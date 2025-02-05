import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kasie_transie_ambassador/ambassador_ui/dash_elements.dart';
import 'package:kasie_transie_ambassador/ambassador_ui/passenger_counter_page.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/data_schemas.dart' as lib;
import 'package:kasie_transie_library/maps/map_viewer.dart';
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/utils/device_location_bloc.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/ambassador/association_vehicle_photo_handler.dart';
import 'package:kasie_transie_library/widgets/ambassador/cars_for_ambassador.dart';
import 'package:kasie_transie_library/widgets/ambassador/routes_for_ambassador.dart';
import 'package:kasie_transie_library/widgets/vehicle_passenger_count.dart';
import 'package:uuid/uuid.dart';
import 'package:badges/badges.dart' as bd;

class AmbassadorStarter extends StatefulWidget {
  const AmbassadorStarter({super.key, required this.association});

  final lib.Association association;

  @override
  AmbassadorStarterState createState() => AmbassadorStarterState();
}

class AmbassadorStarterState extends State<AmbassadorStarter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  lib.User? user;
  Prefs prefs = GetIt.instance<Prefs>();
  lib.Route? route;
  lib.Vehicle? car;
  lib.Trip? trip;
  DeviceLocationBloc deviceLocationBloc = GetIt.instance<DeviceLocationBloc>();
  FCMService fcmService = GetIt.instance<FCMService>();

  late StreamSubscription<lib.CommuterRequest> commuterRequestSub;
  static const mm = '🥦️🥦️🥦️🥦️AmbassadorStarter 🥦️🥦️';

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
    user = prefs.getUser();
    route = prefs.getRoute();
    car = prefs.getCar();
    _signIn();
  }

  List<lib.CommuterRequest> commuterRequests = [];

  Future<void> _listen() async {
    await fcmService.initialize();
    commuterRequestSub = fcmService.commuterRequestStream.listen((req) {
      commuterRequests.add(req);
      _filterCommuterRequests(commuterRequests);
      if (mounted) {
        setState(() {});
      }
    });
  }

  ListApiDog listApiDog = GetIt.instance<ListApiDog>();
  late Timer timer;
  initializeTimer() async {
    pp('\n\n$mm initialize Timer for ambassador commuters');
    timer = Timer.periodic(Duration(seconds: 60), (timer) {
      pp('\n\n$mm Timer tick #${timer.tick} - _filterCommuterRequests ...');
      _filterCommuterRequests(commuterRequests);
    });
    pp('\n\n$mm  Ambassador Timer initialized for 🌀 60 seconds per tick🌀');
  }

  void _getCommuterRequests() async {

    var date = DateTime.now().toUtc().subtract(const Duration(hours: 1));
    commuterRequests = await listApiDog.getRouteCommuterRequests(routeId: route!.routeId!,
        startDate: date.toIso8601String());
    if (mounted) {
      setState(() {
      });
    }
  }
  List<lib.CommuterRequest> _filterCommuterRequests(
      List<lib.CommuterRequest> requests) {
    pp('$mm _filterCommuterRequests arrived: ${requests.length}');

    List<lib.CommuterRequest> filtered = [];
    DateTime now = DateTime.now().toUtc();
    for (var r in requests) {
      var date = DateTime.parse(r.dateRequested!);
      var difference = now.difference(date);
      pp('$mm _filterCommuterRequests difference: $difference');

      if (difference <= const Duration(hours: 1)) {
        filtered.add(r);
      }
    }
    pp('$mm _filterCommuterRequests filtered: ${filtered.length}');
    setState(() {
      commuterRequests = filtered;
    });
    return filtered;
  }

  int _getPassengers() {
    var cnt = 0;
    for (var cr in commuterRequests) {
      cnt += cr.numberOfPassengers!;
    }
    return cnt;
  }

  @override
  void dispose() {
    _controller.dispose();
    commuterRequestSub.cancel();
    timer.cancel();
    super.dispose();
  }

  _signIn() async {
    if (user != null) {
      var u = await auth.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: user!.email!, password: user!.password!);
      if (u.user != null) {
        pp('$mm user has signed in');
        // initializeTimer();
        if (mounted) {
          showOKToast(
              duration: const Duration(seconds: 2),
              message: 'User signed in successfully!',
              context: context);
        }
      }
    }
  }

  _navigateToRoutes() async {
    route = await NavigationUtils.navigateTo(
        context: context,
        widget: NearestRoutesList(
          associationId: widget.association.associationId!,
          title: 'Ambassador Routes',
        ));

    if (route != null) {
      prefs.saveRoute(route!);
      _getCommuterRequests();
      _navigateToCarSearch(route!);
    }
  }

  _confirmCar() {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
              content: SizedBox(
                  height: 140,
                  child: Column(
                    children: [
                      gapH16,
                      Text('Do you want to work in your previous taxi?  '),
                      gapH32,
                      Text(
                        ' ${car!.vehicleReg}',
                        style:
                            myTextStyle(fontSize: 32, weight: FontWeight.w900),
                      )
                    ],
                  )),
              actions: [
                TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      car = await NavigationUtils.navigateTo(
                          context: context,
                          widget: CarForAmbassador(
                            associationId: widget.association.associationId!,
                          ));

                      if (car != null) {
                        trip = await _getTrip(route!, car!);
                        prefs.saveCar(car!);
                        _navigateToPassengerCount(route!, car!);
                      }
                    },
                    child: const Text('No')),
                TextButton(
                    onPressed: () async {
                      trip = await _getTrip(route!, car!);
                      if (mounted) {
                        Navigator.of(context).pop();
                        _navigateToPassengerCount(route!, car!);
                      }
                    },
                    child: const Text('Yes')),
              ]);
        });
  }

  DataApiDog dataApi = GetIt.instance<DataApiDog>();

  _navigateToCarSearch(lib.Route route) async {
    if (car != null) {
      _confirmCar();
      return;
    }
    car = await NavigationUtils.navigateTo(
        context: context,
        widget: CarForAmbassador(
          associationId: widget.association.associationId!,
        ));

    pp('$mm  _navigateToCarSearch(): ....... vehicle scanned: ${car!.toJson()}');

    if (car != null) {
      trip = await _getTrip(route, car!);
      prefs.saveCar(car!);
      _navigateToPassengerCount(route, car!);
    }
  }

  _navigateToPassengerCount(lib.Route route, lib.Vehicle vehicle) async {
    trip ??= await _getTrip(route, vehicle);
    if (mounted) {
      NavigationUtils.navigateTo(
          context: context,
          widget: PassengerCounterPage(
            vehicle: vehicle,
            route: route,
            trip: trip!,
          ));
    }
  }

  Future<lib.Trip?> _getTrip(lib.Route route, lib.Vehicle vehicle) async {
    var loc = await deviceLocationBloc.getLocation();
    var user = prefs.getUser();
    lib.Trip? trip;
    if (user != null) {
      trip = lib.Trip(
          tripId: Uuid().v4().toString(),
          userId: user.userId!,
          userName: '${user.firstName} ${user.lastName}',
          dateStarted: DateTime.now().toUtc().toIso8601String(),
          dateEnded: null,
          routeId: route.routeId!,
          routeName: route.name!,
          vehicleId: car!.vehicleId,
          vehicleReg: car!.vehicleReg,
          associationId: widget.association.associationId!,
          associationName: widget.association.associationName,
          position: lib.Position(
              coordinates: [loc.longitude, loc.latitude], type: 'Point'),
          created: DateTime.now().toUtc().toIso8601String());
      dataApi.addTrip(trip);
      fcmService.subscribeForAmbassador(route, 'Ambassador');
    }
    return trip;
  }

  _navigateToAssociationPhotos() {
    NavigationUtils.navigateTo(
        context: context, widget: AssociationVehiclePhotoHandler());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Ambassador Starter', style: myTextStyle()),
          leading: gapW32,
          actions: [
            IconButton(
                onPressed: () {
                  _navigateToAssociationPhotos();
                },
                icon: FaIcon(FontAwesomeIcons.camera)),
          ]),
      body: SafeArea(
        child: Stack(children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                user == null
                    ? gapW32
                    : Text('${user!.firstName} ${user!.lastName}',
                        style: myTextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                            weight: FontWeight.w700)),
                gapH32,
                gapH32, gapH32,
                Padding(
                  padding: EdgeInsets.all(16),
                  child: DashElements(isGrid: false),
                ),
                Expanded(
                  child: Center(
                      child: SizedBox(
                          height: 200,
                          child: Column(
                            children: [
                              SizedBox(
                                width: 300,
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    elevation: WidgetStatePropertyAll(8),
                                    backgroundColor:
                                        WidgetStatePropertyAll(Colors.grey),
                                  ),
                                  onPressed: () {
                                    _navigateToRoutes();
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text(
                                      'Start Trip',
                                      style: myTextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          weight: FontWeight.normal),
                                    ),
                                  ),
                                ),
                              ),
                              gapH32,
                            ],
                          ))),
                ),

              ],
            ),
          ),
          commuterRequests.isNotEmpty? Positioned(
              top: 64, right: 16, left: 16,
              child: Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Commuters on the route', style: myTextStyle(weight: FontWeight.w900, fontSize: 12, color: Colors.grey)),
                  gapW16,
                  bd.Badge(
                    badgeContent: Text('${_getPassengers()}', style: myTextStyle(color: Colors.white)),
                    badgeStyle: bd.BadgeStyle(padding: EdgeInsets.all(12), badgeColor:  Colors.red.shade700),
                    onTap: () {
                      _navigateToRouteMap();
                    },
                  ),
                  gapW8,
                  Text('Requests', style: myTextStyle(weight: FontWeight.w900, fontSize: 12, color: Colors.grey)),
                  gapW8,
                  bd.Badge(
                    badgeContent: Text('${commuterRequests.length}', style: myTextStyle(color: Colors.white)),
                    badgeStyle: bd.BadgeStyle(padding: EdgeInsets.all(12), badgeColor:  Colors.grey.shade500),
                  ),
                ],
              )): gapW32,
          route == null
              ? gapW32
              : Positioned(
                  bottom: 2,
                  right: 24,
                  child: SizedBox(
                      height: 140,
                      child: Column(
                        children: [
                          TextButton(
                            onPressed: () {
                              route = prefs.getRoute();
                              setState(() {});
                              _navigateToCarSearch(route!);
                            },
                            child: Text('${route!.name}',
                                style: myTextStyle(color: Colors.grey, fontSize: 18, weight: FontWeight.w900)),
                          ),
                        ],
                      ))),
        ]),
      ),
    );
  }
  void _navigateToRouteMap() {
    pp('$mm ..... _navigateToRouteMap');
    if (route != null) {
    NavigationUtils.navigateTo(
        context: context, widget: MapViewer(
        commuterRequests: commuterRequests,
        route: route!));
    }
  }
}
