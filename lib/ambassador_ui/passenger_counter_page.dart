import 'dart:async';

import 'package:badges/badges.dart' as bd;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/data_schemas.dart' as lib;
import 'package:kasie_transie_library/l10n/translation_handler.dart';
import 'package:kasie_transie_library/maps/map_viewer.dart';
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/utils/device_location_bloc.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/ambassador/counter.dart';
import 'package:kasie_transie_library/widgets/payment/commuter_cash_payment_widget.dart';
import 'package:kasie_transie_library/widgets/photo_handler.dart';
import 'package:kasie_transie_library/widgets/scanners/dispatch_helper.dart';
import 'package:kasie_transie_library/widgets/scanners/kasie/last_scanner_widget.dart';
import 'package:kasie_transie_library/widgets/vehicle_widgets/fuel_top_up_widget.dart';

import 'commuter_scanner.dart';

class PassengerCounterPage extends StatefulWidget {
  const PassengerCounterPage(
      {super.key,
      required this.vehicle,
      required this.route,
      required this.trip});

  final lib.Vehicle vehicle;
  final lib.Route route;
  final lib.Trip trip;

  @override
  PassengerCounterPageState createState() => PassengerCounterPageState();
}

class PassengerCounterPageState extends State<PassengerCounterPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ListApiDog listApiDog = GetIt.instance<ListApiDog>();
  Prefs prefs = GetIt.instance<Prefs>();
  DataApiDog dataApiDog = GetIt.instance<DataApiDog>();
  DeviceLocationBloc locationBloc = GetIt.instance<DeviceLocationBloc>();
  late StreamSubscription<lib.CommuterRequest> commuterRequestSub;
  FCMService fcmService = GetIt.instance<FCMService>();

  static const mm = '🔷🔷🔷🔷🔷🔷 PassengerCounterPage 🔷';
  var passengerCounts = <lib.AmbassadorPassengerCount>[];

  var currentCounts = <lib.AmbassadorPassengerCount>[];

  bool busy = false;
  bool showAllCounts = false;
  lib.User? user;
  String? passengersInText,
      passengerCounter,
      passengersOutText,
      currentPassengersText,
      passengerCountsaved,
      lastCount,
      errorCount,
      saveCounts;

  Future _setTexts() async {
    final c = prefs.getColorAndLocale();
    passengersInText = await translator.translate('passengersIn', c.locale);
    passengersOutText = await translator.translate('passengersOut', c.locale);
    currentPassengersText =
        await translator.translate('currentPassengers', c.locale);
    saveCounts = await translator.translate('saveCounts', c.locale);
    passengerCounter = await translator.translate('passengerCount', c.locale);
    lastCount = await translator.translate('lastCount', c.locale);
    passengerCountsaved =
        await translator.translate('passengerCountsaved', c.locale);
    errorCount = await translator.translate('errorCount', c.locale);

    setState(() {});
  }

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
    _control();
    // _initializeTimer();
    _getCommuterRequests();
  }

  List<lib.CommuterRequest> commuterRequests = [];

  void _listen() {
    commuterRequestSub = fcmService.commuterRequestStream.listen((req) {
      commuterRequests.add(req);
      _filterCommuterRequests(commuterRequests);
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _getCommuterRequests() async {
    var date = DateTime.now().toUtc().subtract(const Duration(hours: 1));
    commuterRequests = await listApiDog.getRouteCommuterRequests(
        routeId: widget.route.routeId!, startDate: date.toIso8601String());
    if (mounted) {
      setState(() {});
    }
  }

  int _getPassengers() {
    var cnt = 0;
    for (var cr in commuterRequests) {
      cnt += cr.numberOfPassengers!;
    }
    return cnt;
  }

  List<lib.CommuterRequest> _filterCommuterRequests(
      List<lib.CommuterRequest> requests) {
    pp('$mm _filterCommuterRequests arrived: ${requests.length}');

    List<lib.CommuterRequest> filtered = [];
    DateTime now = DateTime.now().toUtc();
    for (var r in requests) {
      var date = DateTime.parse(r.dateRequested!);
      var difference = now.difference(date);
      pp('$mm _filterCommuterRequests difference: 🍎 $difference');

      if (difference <= const Duration(hours: 1)) {
        filtered.add(r);
      }
    }
    pp('$mm _filterCommuterRequests filtered: 🍑 ${filtered.length}');
    if (mounted) {
      setState(() {
        commuterRequests = filtered;
      });
    }
    return filtered;
  }

  void _control() async {
    user = prefs.getUser();
    await _setTexts();
  }

  late Timer timer;

  _initializeTimer() async {
    pp('\n\n$mm initialize Timer for ambassador commuters');
    timer = Timer.periodic(Duration(seconds: 60), (timer) {
      pp('\n\n$mm Timer tick #${timer.tick} - _filterCommuterRequests ...');
      _filterCommuterRequests(commuterRequests);
    });
    pp('\n\n$mm  Ambassador Timer initialized for 🌀 60 seconds per tick🌀');
  }

  @override
  void dispose() {
    _controller.dispose();
    timer.cancel();
    super.dispose();
  }

  void _getPassengerCounterPages(bool refresh) async {
    pp('$mm ... get prior PassengerCounterPages ...');
    try {
      setState(() {
        busy = true;
      });

      final startDate = DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 8))
          .toIso8601String();
      passengerCounts = await listApiDog.getAmbassadorPassengerCountsByVehicle(
          vehicleId: widget.vehicle.vehicleId!,
          refresh: refresh,
          startDate: startDate);
      passengerCounts.sort((a, b) => b.created!.compareTo(a.created!));
      pp('$mm ... received prior PassengerCounterPages ...${E.appleRed} ${passengerCounts.length}');
    } catch (e) {
      pp(e);
    }
    setState(() {
      busy = false;
      showAllCounts = true;
    });
  }

  String? lastDate;
  int previousPassengersIn = 0;
  late lib.AmbassadorPassengerCount passengerCount;

  void _submitCounts() async {
    pp('$mm .. _submitCounts ...');
    setState(() {
      busy = true;
    });

    try {
      previousPassengersIn = passengersIn;
      final loc = await locationBloc.getLocation();
      passengerCount = lib.AmbassadorPassengerCount(
        associationId: user!.associationId,
        tripId: widget.trip.tripId,
        created: DateTime.now().toUtc().toIso8601String(),
        userId: user!.userId,
        vehicleId: widget.vehicle.vehicleId,
        vehicleReg: widget.vehicle.vehicleReg,
        userName: user!.name,
        currentPassengers: currentPassengers,
        passengersIn: passengersIn,
        passengersOut: passengersOut,
        ownerId: widget.vehicle.ownerId,
        ownerName: widget.vehicle.ownerName,
        position: lib.Position(
          type: 'Point',
          coordinates: [loc.longitude, loc.latitude],
          latitude: loc.latitude,
          longitude: loc.latitude,
        ),
        routeId: widget.route.routeId,
        routeName: widget.route.name,
      );

      pp('$mm sending counts: ${passengerCount.toJson()}');
      dataApiDog.addAmbassadorPassengerCount(passengerCount);
      pp('$mm .. _submitCounts seems OK!');
      var format = DateFormat.Hms();
      lastDate = format.format(DateTime.now());
      passengersOut = 0;
      passengersIn = 0;
      currentCounts.add(passengerCount);

      dispatchHelper.sendPassengerCount(passengerCount);
      if (mounted) {
        showOKToast(
            duration: const Duration(seconds: 2),
            padding: 20,
            message: passengerCountsaved == null
                ? 'Passenger Counts saved, thank you!'
                : passengerCountsaved!,
            context: context);
      }
      if (passengerCount.passengersIn! > 0) {
        _navigateToCashPayment();
      }
    } catch (e, s) {
      pp('$e $s');
      if (mounted) {
        showErrorToast(message: '$e', context: context);
      }
    }
    setState(() {
      busy = false;
      showSubmit = false;
    });
  }

  void _navigateToCashPayment() async {
    if (passengersIn == 0) {
      return;
    }
    NavigationUtils.navigateTo(
        context: context,
        widget: CommuterCashPaymentWidget(
          vehicle: widget.vehicle,
          route: widget.route,
          onError: (err) {},
          trip: widget.trip,
          numberOfPassengers: passengersIn,
        ));
  }

  void _navigateToPhotoHandler() {
    pp('$mm ... _navigateToPhotoHandler');

    NavigationUtils.navigateTo(
      context: context,
      widget: PhotoHandler(
          vehicle: widget.vehicle,
          onPhotoTaken: (file, thumb) {
            pp('$mm photo and thumbnail files returned from handler');
          }),
    );
  }

  int passengersIn = 0, passengersOut = 0, currentPassengers = 0;
  bool showSubmit = false;

  void _navigateToRouteMap() {
    pp('$mm ... _navigateToRouteMap');
    NavigationUtils.navigateTo(
        context: context,
        widget:
            MapViewer(commuterRequests: commuterRequests, route: widget.route));
  }

  lib.Commuter? scannedCommuter;
  Future<void> _navigateToCommuterScan() async {
    pp('$mm _navigateToCommuterScan ...');
    if (mounted) {
      try {
        var scanned = await NavigationUtils.navigateTo(
            context: context,
            widget: LastScannerWidget(
              onVehicleScanned: (data) {
                pp('$mm onVehicleScanned scan: $data');
              },
              onCommuterScanned: (commuter) {
                pp('$mm ........ onCommuterScanned scan: ${commuter.toJson()}');
                scannedCommuter = commuter;
                _onPassengersIn(1);
                _navigateToCashPayment();
              },
              onCommuterTicketScanned: (commuterTicket) {
                pp('$mm onCommuterTicketScanned scan: ${commuterTicket.toJson()}');
              },
              onError: (err) {
                pp('$mm onError: $err');
                if (mounted) {
                  showErrorToast(message: err, context: context);
                }
              },
            ));
      } catch (e, s) {
        pp('$e $s');
      }
    }
  }

  _onPassengersIn(int number) {
    setState(() {
      currentPassengers = currentPassengers + number;
      passengersIn = number;
    });
  }

  _onPassengersOut(int number) {
    if (number > currentPassengers) {
      showErrorToast(
          message:
              'The number of passengers leaving the taxi should not be greater than the current passengers',
          context: context);
      return;
    }
    setState(() {
      currentPassengers = currentPassengers - number;
      passengersOut = number;
    });
  }

  _tripHasEnded() {
    pp('\n\n$mm ... _tripHasEnded ... room for a new data model? TripEnd anyone?');

    widget.trip.dateEnded = DateTime.now().toUtc().toIso8601String();
    dataApiDog.updateTrip(widget.trip);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        leading: const SizedBox(),
        title: Text(
          passengerCounter == null ? 'Passengers' : passengerCounter!,
          style: myTextStyle(),
        ),
        actions: [
          IconButton(
              onPressed: () {
                _navigateToPhotoHandler();
              },
              icon: Icon(
                Icons.camera_alt,
                color: Theme.of(context).primaryColor,
              )),
          IconButton(
              onPressed: () {
                _navigateToRouteMap();
              },
              icon: Icon(Icons.map, color: Theme.of(context).primaryColor)),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.vehicle.vehicleReg}',
                      style: myTextStyle(fontSize: 36, weight: FontWeight.w900),
                    ),
                    IconButton(
                        onPressed: () {
                          NavigationUtils.navigateTo(
                              context: context,
                              widget: FuelTopUpWidget(
                                vehicle: widget.vehicle,
                                isLandscape: false,
                              ));
                        },
                        icon: FaIcon(FontAwesomeIcons.gasPump,
                            color: Colors.pink))
                  ],
                ),
                Text(
                  '${widget.vehicle.make} ${widget.vehicle.model} ${widget.vehicle.year}',
                  style: myTextStyle(
                      fontSize: 12,
                      weight: FontWeight.normal,
                      color: Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${widget.route.name}',
                    style: myTextStyle(
                        fontSize: 16,
                        weight: FontWeight.w400,
                        color: Colors.grey),
                  ),
                ),
                gapH16,
                PassengerCounter(
                    title: 'Passengers In',
                    count: 50,
                    fontSize: 24,
                    onNumberSelected: (number) {
                      _onPassengersIn(number);
                    },
                    color: Colors.blue),
                gapH8,
                SizedBox(
                  width: 300,
                  child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.teal),
                        elevation: WidgetStatePropertyAll(4),
                      ),
                      onPressed: () {
                        _navigateToCommuterScan();
                      },
                      child: Text(
                        'Scan Commuter',
                        style: myTextStyle(color: Colors.white),
                      )),
                ),
                gapH32,
                gapH16,
                PassengerCounter(
                    title: 'Passengers Out',
                    count: 50,
                    fontSize: 24,
                    onNumberSelected: (number) {
                      _onPassengersOut(number);
                    },
                    color: Colors.red),
                gapH16,
                Card(
                    elevation: 8,
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Current Passengers',
                              style: myTextStyle(
                                  weight: FontWeight.w900,
                                  fontSize: 18,
                                  color: Colors.grey.shade400),
                            ),
                            gapW32,
                            Text(
                              '$currentPassengers',
                              style: myTextStyle(
                                  fontSize: 24,
                                  color: Colors.black,
                                  weight: FontWeight.w900),
                            )
                          ],
                        ))),
                gapH16,
                SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.blue),
                        elevation: WidgetStatePropertyAll(8)),
                    onPressed: () {
                      _submitCounts();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Submit',
                          style:
                              myTextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ),
                gapH32,
                SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.grey),
                        elevation: WidgetStatePropertyAll(2)),
                    onPressed: () {
                      _tripHasEnded();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Trip has Ended',
                        style: myTextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          commuterRequests.isNotEmpty
              ? Positioned(
                  bottom: 8,
                  right: 16,
                  child: Row(
                    children: [
                      Text('Commuters on the route',
                          style: myTextStyle(
                              weight: FontWeight.w900,
                              fontSize: 12,
                              color: Colors.grey)),
                      gapW16,
                      bd.Badge(
                        badgeContent: Text('${_getPassengers()}',
                            style: myTextStyle(color: Colors.white)),
                        badgeStyle: bd.BadgeStyle(
                            padding: EdgeInsets.all(12),
                            badgeColor: Colors.red.shade700),
                        onTap: () {
                          _navigateToRouteMap();
                        },
                      ),
                      gapW32,
                      Text('Requests',
                          style: myTextStyle(
                              weight: FontWeight.w900,
                              fontSize: 12,
                              color: Colors.grey)),
                      gapW16,
                      bd.Badge(
                        badgeContent: Text('${commuterRequests.length}',
                            style: myTextStyle(color: Colors.white)),
                        badgeStyle: bd.BadgeStyle(
                            padding: EdgeInsets.all(12),
                            badgeColor: Colors.grey.shade500),
                      ),
                    ],
                  ))
              : gapW32,
          busy
              ? const Positioned(
                  child: Center(
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      backgroundColor: Colors.amber,
                    ),
                  ),
                ))
              : const SizedBox(),
        ],
      ),
    ));
  }
}
