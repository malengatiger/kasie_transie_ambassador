import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/data/data_schemas.dart' as lib;
import 'package:kasie_transie_library/utils/device_location_bloc.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/ambassador/cars_for_ambassador.dart';
import 'package:kasie_transie_library/widgets/ambassador/routes_for_ambassador.dart';
import 'package:kasie_transie_library/widgets/vehicle_passenger_count.dart';
import 'package:uuid/uuid.dart';
import 'package:kasie_transie_library/widgets/ambassador/association_vehicle_photo_handler.dart';

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

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    user = prefs.getUser();
    route = prefs.getRoute();
    car = prefs.getCar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          widget: VehiclePassengerCount(
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
      dataApi.addTrip(trip!);
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
                gapH32,
                user == null
                    ? gapW32
                    : Text('${user!.firstName} ${user!.lastName}',
                        style: myTextStyle(
                            color: Colors.grey,
                            fontSize: 28,
                            weight: FontWeight.w700)),
                gapH32,
                gapH32,
                gapH32,
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'To start your Ambassador job you have to choose the route and the taxi you will be working in.',
                    style: myTextStyle(fontSize: 18),
                  ),
                ),
                Expanded(
                    child: Center(
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
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Start Trip',
                                  style: myTextStyle(
                                      fontSize: 24,
                                      color: Colors.white,
                                      weight: FontWeight.normal),
                                )))))
              ],
            ),
          ),
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
                            },
                            child: Text('${route!.name}',
                                style: myTextStyle(color: Colors.grey)),
                          ),
                          gapH8,
                          TextButton(
                            onPressed: () {
                              _navigateToCarSearch(route!);
                            },
                            child: Text('Use Previous Trip Route',
                                style: myTextStyle(fontSize: 20)),
                          ),
                        ],
                      ))),
        ]),
      ),
    );
  }
}
