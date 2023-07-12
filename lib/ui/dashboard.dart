import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/data/color_and_locale.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/isolates/routes_isolate.dart';
import 'package:kasie_transie_library/l10n/translation_handler.dart';
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/providers/kasie_providers.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/days_drop_down.dart';
import 'package:kasie_transie_library/widgets/dispatch_via_scan.dart';
import 'package:kasie_transie_library/widgets/language_and_color_chooser.dart';
import 'package:kasie_transie_library/bloc/dispatch_helper.dart';
import 'package:kasie_transie_library/widgets/scan_vehicle_for_counts.dart';
import 'package:kasie_transie_library/widgets/scan_vehicle_for_media.dart';

import '../auth/phone_auth_signin.dart';
import '../main.dart';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  ConsumerState createState() => DashboardState();
}

class DashboardState extends ConsumerState<Dashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  static const mm = '😡😡😡😡😡😡😡 Dashboard: 💪 ';

  lib.User? user;
  var cars = <lib.Vehicle>[];
  var routes = <lib.Route>[];
  var routeLandmarks = <lib.RouteLandmark>[];
  var dispatchRecords = <lib.DispatchRecord>[];
  bool busy = false;
  late ColorAndLocale colorAndLocale;
  bool authed = false;
  var totalPassengers = 0;
  lib.VehicleMediaRequest? vehicleMediaRequest;
  late StreamSubscription<lib.DispatchRecord> _dispatchStreamSubscription;
  late StreamSubscription<lib.VehicleMediaRequest> _mediaRequestSubscription;
  late StreamSubscription<lib.RouteUpdateRequest> _routeUpdateSubscription;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
    _getAuthenticationStatus();
  }

  void _listen() async {
    _dispatchStreamSubscription = dispatchHelper.dispatchStream.listen((event) {
      pp('$mm dispatchHelper.dispatchStream delivered ${event.vehicleReg}');
      dispatchRecords.insert(0, event);
      _aggregatePassengers();
      if (mounted) {
        setState(() {});
      }
    });
    //
    _mediaRequestSubscription =
        fcmBloc.vehicleMediaRequestStream.listen((event) {
      pp('$mm fcmBloc.vehicleMediaRequestStream delivered ${event.vehicleReg}');
      if (mounted) {
        _confirmNavigationToPhotos(event);
      }
    });
    //
    _routeUpdateSubscription = fcmBloc.routeUpdateRequestStream.listen((event) {
      pp('$mm fcmBloc.routeUpdateRequestStream delivered: ${event.routeName}');
      _startRouteUpdate(event);
    });
  }

  void _aggregatePassengers() {
    totalPassengers = 0;
    for (var value in dispatchRecords) {
      totalPassengers += value.passengers!;
    }
  }

  void _confirmNavigationToPhotos(lib.VehicleMediaRequest request) {
    pp('$mm confirm dialog for navigation to vehicle media control ');

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (ctx) {
          return AlertDialog(
            content: Column(
              children: [
                const Text(
                    'You have been requested to take pictures and or video of the vehicle.\n'
                    'Please tap YES to start the photos or do that at the earliest opportunity.'),
                const SizedBox(
                  height: 48,
                ),
                Row(
                  children: [
                    const Text('Vehicle: '),
                    Text(
                      '${request.vehicleReg}',
                      style: myTextStyleMediumLargeWithColor(
                          context, Theme.of(context).primaryColor, 32),
                    )
                  ],
                ),
                const SizedBox(
                  height: 48,
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () {
                    _navigateToScanVehicleForMedia();
                  },
                  child: const Text("Start the Camera")),
            ],
          );
        });
  }

  void _startRouteUpdate(lib.RouteUpdateRequest request) async {
    pp('$mm start route update in isolate for ${request.routeName} ...  ');
    routesIsolate.getRoute(user!.associationId!, request.routeId!);

    if (mounted) {
      showSnackBar(
          duration: const Duration(seconds: 10),
          message: 'Route ${request.routeName} has been refreshed! Thanks',
          context: context);
    }
  }

  void _getAuthenticationStatus() async {
    pp('\n\n$mm _getAuthenticationStatus ....... '
        'check both Firebase user and Kasie user');
    var user = await prefs.getUser();
    var firebaseUser = FirebaseAuth.instance.currentUser;

    if (user != null && firebaseUser != null) {
      pp('$mm _getAuthenticationStatus .......  '
          '🥬🥬🥬auth is DEFINITELY authenticated and OK');
      user = await prefs.getUser();
      authed = true;
      fcmBloc.subscribeToTopics('AmbassadorApp');
      failedChecker.startChecking();
      setState(() {});
      _getData();
    } else {
      pp('$mm _getAuthenticationStatus ....... NOT AUTHENTICATED! '
          '🌼🌼🌼 ... will clean house!!');
      authed = false;
      //todo - ensure that the right thing gets done!
      pp('$mm _getAuthenticationStatus .......  '
          '🔴🔴🔴🔴'
          'the device should be ready for sign in or registration');
    }
    pp('$mm ......... _getAuthenticationStatus ....... setting state, authed = $authed ');

    setState(() {});
  }

  var requests = <lib.VehicleMediaRequest>[];

  Future _getAssociationVehicleMediaRequests(bool refresh) async {
    final startDate = DateTime.now()
        .toUtc()
        .subtract(const Duration(days: 30))
        .toIso8601String();
    requests = await listApiDog.getAssociationVehicleMediaRequests(
        user!.associationId!, startDate, refresh);
  }

  Future<void> _navigateToAuth() async {
    var res = await navigateWithScale(
        CellPhoneAuthSignin(dataApiDog: dataApiDog), context);
    pp('\n\n$mm ................ back from sign in: $res');
    setState(() {
      busy = false;
    });
    user = await prefs.getUser();
    _getData();
  }

  void _navigateToScanVehicleForMedia() {
    pp('$mm navigate to ScanVehicleForMedia ...  ');
    navigateWithScale(const ScanVehicleForMedia(), context);
  }

  Future _getData() async {
    pp('$mm ................... get data for marshal dashboard ...');
    user = await prefs.getUser();
    setState(() {
      busy = true;
    });
    try {
      colorAndLocale = await prefs.getColorAndLocale();
      // _setTexts();

      if (user != null) {
        await _getRoutes();
        await _getLandmarks();
        await _getCars();
        await _getDispatches(false);
        await _getAssociationVehicleMediaRequests(false);
        await _getPassengerCounts(false);
        _setTexts();
      }
    } catch (e) {
      pp(e);
      if (mounted) {
        showSnackBar(
            padding: 16, message: 'Error getting data', context: context);
      }
      ;
    }
    //
    setState(() {
      busy = false;
    });
  }

  String? dispatchWithScan,
      manualDispatch,
      vehiclesText,
      routesText,
      landmarksText,
      days,
      passengerCount,
      dispatchesText,
      passengers,
      countPassengers,
      ambassadorText;

  Future _setTexts() async {
    dispatchWithScan =
        await translator.translate('dispatchWithScan', colorAndLocale.locale);
    manualDispatch =
        await translator.translate('manualDispatch', colorAndLocale.locale);
    vehiclesText =
        await translator.translate('vehicles', colorAndLocale.locale);

    routesText = await translator.translate('routes', colorAndLocale.locale);
    landmarksText =
        await translator.translate('landmarks', colorAndLocale.locale);
    dispatchesText =
        await translator.translate('dispatches', colorAndLocale.locale);

    passengers =
        await translator.translate('passengers', colorAndLocale.locale);
    days = await translator.translate('days', colorAndLocale.locale);
    ambassadorText =
        await translator.translate('ambassador', colorAndLocale.locale);
    countPassengers =
        await translator.translate('countPassengers', colorAndLocale.locale);
    passengerCount =
        await translator.translate('passengerCount', colorAndLocale.locale);

    setState(() {});
  }

  int daysForData = 7;
  Future _getRoutes() async {
    pp('$mm ... marshal dashboard; getting routes: ${routes.length} ...');

    routes = await listApiDog
        .getRoutes(AssociationParameter(user!.associationId!, false));
    pp('$mm ... marshal dashboard; routes: ${routes.length} ...');
    setState(() {});
  }

  Future _getCars() async {
    pp('$mm ... marshal dashboard; getting cars: ${cars.length} ...');

    cars = await listApiDog.getAssociationVehicles(user!.associationId!, false);
    pp('$mm ... marshal dashboard; cars: ${cars.length} ...');
    setState(() {});
  }

  var passengerCounts = <lib.AmbassadorPassengerCount>[];

  Future _getPassengerCounts(bool refresh) async {
    pp('$mm ... ambassador dashboard; getting counts, noe: ${passengerCounts.length} ...');
    setState(() {
      busy = true;
    });
    try {
      final startDate = DateTime.now().toUtc().toIso8601String();
      passengerCounts = await listApiDog.getAmbassadorPassengerCountsByUser(
          userId: user!.userId!, refresh: refresh, startDate: startDate);
      _aggregatePassengers();
      pp('$mm ... ambassador dashboard; passengerCounts: ${passengerCounts.length} ...');
    } catch (e) {
      pp(e);
    }
    setState(() {
      busy = false;
    });
  }

  Future _getDispatches(bool refresh) async {
    pp('$mm ... marshal dashboard; getting dispatches: ${dispatchRecords.length} ...');
    setState(() {
      busy = true;
    });
    try {
      dispatchRecords = await listApiDog.getMarshalDispatchRecords(
          userId: user!.userId!, refresh: refresh, days: daysForData);
      _aggregatePassengers();
      pp('$mm ... marshal dashboard; dispatchRecords: ${dispatchRecords.length} ...');
    } catch (e) {
      pp(e);
    }
    setState(() {
      busy = false;
    });
  }

  Future _getLandmarks() async {
    routeLandmarks = await listApiDog.getAssociationRouteLandmarks(
        user!.associationId!, false);
    pp('$mm ... marshal dashboard; routeLandmarks: ${routeLandmarks.length} ...');
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _dispatchStreamSubscription.cancel();
    _routeUpdateSubscription.cancel();
    _mediaRequestSubscription.cancel();
    super.dispose();
  }

  void _navigateToScanDispatch() async {
    pp('$mm _navigateToScanDispatch ......');

    navigateWithScale(const DispatchViaScan(), context);
  }

  void _navigateToCountPassengers() async {
    pp('$mm ... _navigateToCountPassengers ...');
    navigateWithScale(const ScanVehicleForCounts(), context);
  }

  Future _navigateToColor() async {
    pp('$mm _navigateToColor ......');
    await navigateWithScale(const LanguageAndColorChooser(), context);
    colorAndLocale = await prefs.getColorAndLocale();
    await _setTexts();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              leading: const SizedBox(),
              title: Text(
                ambassadorText == null ? 'Ambassador' : ambassadorText!,
                style: myTextStyleMediumLarge(context, 20),
              ),
              actions: [
                IconButton(
                    onPressed: () {
                      _navigateToScanVehicleForMedia();
                    },
                    icon: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).primaryColor,
                    )),
                IconButton(
                    onPressed: () {
                      _navigateToColor();
                    },
                    icon: Icon(
                      Icons.color_lens,
                      color: Theme.of(context).primaryColor,
                    )),
                IconButton(
                    onPressed: () {
                      _navigateToScanDispatch();
                    },
                    icon: Icon(
                      Icons.airport_shuttle,
                      color: Theme.of(context).primaryColor,
                    )),
              ],
            ),
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    shape: getRoundedBorder(radius: 16),
                    elevation: 4,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 32,
                        ),
                        Text(
                          user == null
                              ? 'Association Name'
                              : user!.associationName!,
                          style: myTextStyleMediumLargeWithColor(
                              context, Theme.of(context).primaryColor, 18),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          user == null ? 'Ambassador Name' : user!.name,
                          style: myTextStyleSmall(context),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        SizedBox(
                            width: 300,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.people),
                              style:  ButtonStyle(
                                elevation: const MaterialStatePropertyAll(8.0),
                                shape: MaterialStatePropertyAll(getRoundedBorder(radius: 16))
                              ),
                              onPressed: () {
                                _navigateToCountPassengers();
                              },
                              label: Padding(
                                padding: const EdgeInsets.all(28.0),
                                child: Text(countPassengers == null
                                    ? 'Count Passengers'
                                    : countPassengers!),
                              ),
                            )),
                        const SizedBox(
                          height: 24,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                DaysDropDown(
                                    onDaysPicked: (days) {
                                      daysForData = days;
                                      setState(() {});
                                      _getDispatches(true);
                                    },
                                    hint: days == null ? 'Days' : days!),
                                const SizedBox(
                                  width: 20,
                                ),
                                Text(
                                  '$daysForData',
                                  style: myTextStyleMediumLargeWithColor(
                                      context,
                                      Theme.of(context).primaryColorLight,
                                      24),
                                )
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        busy
                            ? const Center(
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 6,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              )
                            : Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: user == null
                                      ? const SizedBox()
                                      : GridView(
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisSpacing: 2,
                                            mainAxisSpacing: 2,
                                            crossAxisCount: 2,
                                          ),
                                          children: [
                                            TotalWidget(
                                                caption: passengerCount == null
                                                    ? 'Passenger Counts'
                                                    : passengerCount!,
                                                number: passengerCounts.length,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontSize: 32,
                                                onTapped: () {}),
                                            TotalWidget(
                                                caption: dispatchesText == null
                                                    ? 'Dispatches'
                                                    : dispatchesText!,
                                                number: dispatchRecords.length,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontSize: 32,
                                                onTapped: () {}),
                                            TotalWidget(
                                                caption: passengers == null
                                                    ? 'Passengers'
                                                    : passengers!,
                                                number: totalPassengers,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontSize: 32,
                                                onTapped: () {}),
                                            TotalWidget(
                                                caption: vehiclesText == null
                                                    ? 'Vehicles'
                                                    : vehiclesText!,
                                                number: cars.length,
                                                color: Colors.grey.shade600,
                                                fontSize: 32,
                                                onTapped: () {}),
                                            TotalWidget(
                                                caption: routesText == null
                                                    ? 'Routes'
                                                    : routesText!,
                                                number: routes.length,
                                                color: Colors.grey.shade600,
                                                fontSize: 32,
                                                onTapped: () {}),
                                            TotalWidget(
                                                caption: landmarksText == null
                                                    ? 'Landmarks'
                                                    : landmarksText!,
                                                number: routeLandmarks.length,
                                                color: Colors.grey.shade600,
                                                fontSize: 32,
                                                onTapped: () {}),
                                          ],
                                        ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                user == null
                    ? Positioned(
                        left: 24,
                        right: 24,
                        top: 40,
                        bottom: 100,
                        child: Center(
                          child: Card(
                            shape: getRoundedBorder(radius: 16),
                            elevation: 8,
                            child: SizedBox(
                              height: 400,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 64,
                                    ),
                                    Text(
                                      'Welcome!',
                                      style: myTextStyleLarge(context),
                                    ),
                                    const SizedBox(
                                      height: 32,
                                    ),
                                    const Text(
                                        'Welcome! This is the first time that you have opened the app and you '
                                        'need to sign in to your Taxi Association or other organization.'),
                                    const SizedBox(
                                      height: 64,
                                    ),
                                    ElevatedButton(
                                        onPressed: () {
                                          _navigateToAuth();
                                        },
                                        child: const Text('Start Sign In')),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ))
                    : const SizedBox()
              ],
            )));
  }
}

class TotalWidget extends StatelessWidget {
  const TotalWidget(
      {Key? key,
      required this.caption,
      required this.number,
      required this.onTapped,
      required this.color,
      required this.fontSize})
      : super(key: key);
  final String caption;
  final int number;
  final Function onTapped;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: 120,
      child: GestureDetector(
        onTap: () {
          onTapped();
        },
        child: Card(
          shape: getRoundedBorder(radius: 16),
          elevation: 8,
          child: Center(
            child: SizedBox(
              height: 80,
              child: NumberAndCaption(
                  caption: caption,
                  number: number,
                  color: color,
                  fontSize: fontSize),
            ),
          ),
        ),
      ),
    );
  }
}

class NumberAndCaption extends StatelessWidget {
  const NumberAndCaption(
      {Key? key,
      required this.caption,
      required this.number,
      required this.color,
      required this.fontSize})
      : super(key: key);
  final String caption;
  final int number;
  final Color color;
  final double fontSize;
  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern();
    return SizedBox(
      height: 64,
      child: Column(
        children: [
          Text(
            fmt.format(number),
            style: myNumberStyleLargerWithColor(color, fontSize, context),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            caption,
            style: myTextStyleSmall(context),
          ),
        ],
      ),
    );
  }
}
