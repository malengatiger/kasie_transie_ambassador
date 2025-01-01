import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kasie_transie_library/auth/email_auth_signin.dart';
import 'package:kasie_transie_library/auth/phone_auth_signin2.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';

import 'package:kasie_transie_library/data/color_and_locale.dart';
import 'package:kasie_transie_library/data/data_schemas.dart' as lib;
import 'package:kasie_transie_library/data/route_data.dart';
import 'package:kasie_transie_library/l10n/translation_handler.dart';
import 'package:kasie_transie_library/maps/association_route_maps.dart';
import 'package:kasie_transie_library/messaging/fcm_bloc.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/utils/user_utils.dart';
import 'package:kasie_transie_library/widgets/dash_widgets/generic.dart';
import 'package:kasie_transie_library/widgets/days_drop_down.dart';
import 'package:kasie_transie_library/widgets/scanners/dispatch_helper.dart';
import 'package:kasie_transie_library/widgets/language_and_color_chooser.dart';
import 'package:kasie_transie_library/widgets/scanners/scan_vehicle_for_counts.dart';
import 'package:kasie_transie_library/widgets/scanners/scan_vehicle_for_media.dart';
import 'package:kasie_transie_library/widgets/vehicle_widgets/routes_for_dispatch.dart';
import 'package:page_transition/page_transition.dart';
import 'package:get_it/get_it.dart';

class AmbassadorDashboard extends StatefulWidget {
  const AmbassadorDashboard({super.key});

  @override
  AmbassadorDashboardState createState() => AmbassadorDashboardState();
}

class AmbassadorDashboardState extends State<AmbassadorDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  static const mm = '😡😡😡😡AmbassadorDashboard: 💪 ';

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
  ListApiDog listApiDog = GetIt.instance<ListApiDog>();
  Prefs prefs = GetIt.instance<Prefs>();
  FCMService fcmService = GetIt.instance<FCMService>();

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
  String notRegistered =
      'You are not registered yet. Please call your administrator';
  String emailNotFound = 'emailNotFound';
  String welcome = 'Welcome';
  String firstTime =
      'This is the first time that you have opened the app and you '
      'need to sign in to your Taxi Association.';
  String changeLanguage = 'Change Language or Color';
  String startEmailLinkSignin = 'Start Email Link Sign In';
  String signInWithPhone = 'Start Phone Sign In';

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _listen();
    _setTexts();
    // _getAuthenticationStatus();
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
        fcmService.vehicleMediaRequestStream.listen((event) {
          pp('$mm fcmService.vehicleMediaRequestStream delivered ${event.vehicleReg}');
          if (mounted) {
            _confirmNavigationToPhotos(event);
          }
        });
    //
    _routeUpdateSubscription = fcmService.routeUpdateRequestStream.listen((event) {
      pp('$mm fcmService.routeUpdateRequestStream delivered: ${event.routeName}');
      _noteRouteUpdate(event);
    });
  }

  // void _getAuthenticationStatus() async {
  //   pp('\n\n$mm _getAuthenticationStatus ....... '
  //       'check both Firebase user and Kasie user');
  //   var firebaseUser = FirebaseAuth.instance.currentUser;
  //   authed = await checkEmail(firebaseUser);
  //   if (authed) {
  //     pp('\n\n$mm _getAuthenticationStatus ....... authed: $authed');
  //     _getData(false);
  //     return;
  //   }
  //   authed = await checkUser(firebaseUser);
  //   if (authed) {
  //     pp('\n\n$mm _getAuthenticationStatus ....... authed: $authed');
  //     _getData(true);
  //     return;
  //   }
  //   pp('$mm ......... _getAuthenticationStatus ....... setting state, authed = $authed ');
  //   _navigateToEmailAuth();
  // }

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

  void _noteRouteUpdate(lib.RouteUpdateRequest request) async {
    pp('$mm route update started in isolate for ${request.routeName} ...  ');
    if (mounted) {
      showSnackBar(
          duration: const Duration(seconds: 10),
          message: 'Route ${request.routeName} has been refreshed! Thanks',
          context: context);
    }
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

  void _navigateToScanVehicleForMedia() {
    pp('$mm navigate to ScanVehicleForMedia ...  ');
    NavigationUtils.navigateTo(context: context, widget: ScanVehicleForMedia(), );
  }

  Future _getData(bool refresh) async {
    pp('$mm ................... get data for ambassador dashboard ...');
    user = prefs.getUser();
    setState(() {
      busy = true;
    });
    try {
      if (user != null) {
        await _getRoutes(refresh);
        await _getLandmarks();
        await _getCars();
        await _getDispatches(false);
        await _getAssociationVehicleMediaRequests(false);
        await _getPassengerCounts(false);
      }
    } catch (e) {
      pp(e);
      if (mounted) {
        showSnackBar(
            padding: 16, message: 'Error getting data', context: context);
      }
    }
    //
    if (mounted) {
      setState(() {
        busy = false;
      });
    }
  }

  Future _setTexts() async {
    colorAndLocale = prefs.getColorAndLocale();
    final loc = colorAndLocale.locale;
    dispatchWithScan =
    await translator.translate('dispatchWithScan', loc);
    manualDispatch =
    await translator.translate('manualDispatch', loc);
    vehiclesText =
    await translator.translate('vehicles', loc);

    routesText = await translator.translate('routes', loc);
    landmarksText =
    await translator.translate('landmarks', loc);
    dispatchesText =
    await translator.translate('dispatches', loc);

    passengers =
    await translator.translate('passengers', loc);
    days = await translator.translate('days', loc);
    ambassadorText =
    await translator.translate('ambassador', loc);
    countPassengers =
    await translator.translate('countPassengers', loc);
    passengerCount =
    await translator.translate('passengerCount', loc);
    emailNotFound =
    await translator.translate('emailNotFound', loc);
    notRegistered =
    await translator.translate('notRegistered', loc);
    firstTime = await translator.translate('firstTime', loc);
    changeLanguage =
    await translator.translate('changeLanguage', loc);
    welcome = await translator.translate('welcome', loc);
    startEmailLinkSignin =
    await translator.translate('signInWithEmail', loc);
    signInWithPhone =
    await translator.translate('signInWithPhone', loc);
    setState(() {

    });
  }

  int daysForData = 7;
  AssociationRouteData? routeData;

  Future _getRoutes(bool refresh) async {
    pp('$mm ... getting routes: ${routes.length} ...');

    routeData = await listApiDog.getAssociationRouteData(user!.associationId!, refresh);
    if (routeData != null) {
      for (var rd in routeData!.routeDataList) {
        if (rd.routePoints.isNotEmpty) {
          routes.add(rd.route!);
        }
      }
    }
    pp('$mm ... ambassador dashboard; routes: ${routes.length} ...');
  }

  Future _getCars() async {
    pp('$mm ... ambassador dashboard; getting cars: ${cars.length} ...');

    cars = await listApiDog.getAssociationCars(user!.associationId!, false);
    pp('$mm ...  cars: ${cars.length} ...');
  }

  var passengerCounts = <lib.AmbassadorPassengerCount>[];

  Future _getPassengerCounts(bool refresh) async {
    pp('$mm ... ambassador dashboard; getting counts, noe: ${passengerCounts.length} ...');

    try {
      final startDate = DateTime.now().toUtc().toIso8601String();
      passengerCounts = await listApiDog.getAmbassadorPassengerCountsByUser(
          userId: user!.userId!, refresh: refresh, startDate: startDate);
      _aggregatePassengers();
      pp('$mm ... ambassador dashboard; passengerCounts: ${passengerCounts.length} ...');
    } catch (e) {
      pp(e);
    }
  }

  Future _getDispatches(bool refresh) async {
    pp('$mm ... ambassador dashboard; getting dispatches: ${dispatchRecords.length} ...');

    try {
      dispatchRecords = await listApiDog.getMarshalDispatchRecords(
          userId: user!.userId!, refresh: refresh, days: daysForData);
      _aggregatePassengers();
      pp('$mm ... ambassador dashboard; dispatchRecords: ${dispatchRecords.length} ...');
      setState(() {});
    } catch (e) {
      pp(e);
    }
  }

  Future _getLandmarks() async {
    routeLandmarks = await listApiDog.getAssociationRouteLandmarks(
        user!.associationId!, false);
    pp('$mm ... ambassador dashboard; routeLandmarks: ${routeLandmarks.length} ...');
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

    NavigationUtils.navigateTo(context: context, widget: RoutesForDispatch(), );

  }

  void _navigateToCountPassengers() async {
    pp('$mm ... _navigateToCountPassengers ...');
    // NavigationUtils.navigateTo(context: context, widget: ScanVehicleForCounts(trip: null,), );

  }
  void _navigateToEmailAuth() async {
    pp('$mm ... _navigateToEmailAuth ...');

    NavigationUtils.navigateTo(context: context, widget: EmailAuthSignin(onGoodSignIn: (){}, onSignInError: (){}), );

    if (user != null) {
      pp('$mm ... back from _navigateToPhoneAuth with user: ${user!.name} ...');
      _getData(true);
    }
  }
  void _navigateToPhoneAuth() async {
    pp('$mm ... _navigateToPhoneAuth ...');

    NavigationUtils.navigateTo(context: context, widget: PhoneAuthSignin(onGoodSignIn: (){}, onSignInError: (){}), );

    if (user != null) {
      pp('$mm ... back from _navigateToPhoneAuth with user: ${user!.name} ...');
      _getData(true);
    }
  }

  Future _navigateToColor() async {
    pp('$mm _navigateToColor ......');
      NavigationUtils.navigateTo(context: context, widget: LanguageAndColorChooser(onLanguageChosen: () async {
        colorAndLocale = prefs.getColorAndLocale();
        await _setTexts();
        setState(() {

        });
      },), );


  }
  void _navigateToMap() {
    NavigationUtils.navigateTo(context: context, widget: AssociationRouteMaps(), );

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
                user == null
                    ? const SizedBox()
                    : IconButton(
                    onPressed: () {
                      _navigateToScanVehicleForMedia();
                    },
                    icon: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).primaryColor,
                    )),
                IconButton(
                    onPressed: () {
                      _navigateToMap();
                    },
                    icon: Icon(
                      Icons.map,
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
                user == null
                    ? const SizedBox()
                    : IconButton(
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
                        gapH32,
                        Text(
                          user == null
                              ? 'Association Name'
                              : user!.associationName!,
                          style: myTextStyleMediumLargeWithColor(
                              context, Theme.of(context).primaryColor, 18),
                        ),
                        gapH8,
                        Text(
                          user == null ? 'Ambassador Name' : user!.name,
                          style: myTextStyleSmall(context),
                        ),
                        gapH16,
                        SizedBox(
                            width: 300,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.people),
                              style: ButtonStyle(
                                  elevation: WidgetStatePropertyAll(8)),
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
                        gapH32,

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                DaysDropDown(
                                    onDaysPicked: (days) {
                                      daysForData = days;
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
                        gapH8,
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
                            padding: const EdgeInsets.all(20.0),
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
                                    fontSize: 32,
                                    onTapped: () {}),
                                TotalWidget(
                                    caption: dispatchesText == null
                                        ? 'Dispatches'
                                        : dispatchesText!,
                                    number: dispatchRecords.length,

                                    fontSize: 32,
                                    onTapped: () {}),
                                TotalWidget(
                                    caption: passengers == null
                                        ? 'Passengers'
                                        : passengers!,
                                    number: totalPassengers,
                                    fontSize: 32,
                                    onTapped: () {}),
                                TotalWidget(
                                    caption: vehiclesText == null
                                        ? 'Vehicles'
                                        : vehiclesText!,
                                    number: cars.length,
                                    fontSize: 32,
                                    onTapped: () {}),
                                TotalWidget(
                                    caption: routesText == null
                                        ? 'Routes'
                                        : routesText!,
                                    number: routes.length,
                                    fontSize: 32,
                                    onTapped: () {}),
                                TotalWidget(
                                    caption: landmarksText == null
                                        ? 'Landmarks'
                                        : landmarksText!,
                                    number: routeLandmarks.length,
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
              ],
            )));
  }
}
