import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:kasie_transie_ambassador/services/auth/auth_service.dart';
import 'package:kasie_transie_ambassador/services/auth/sp_service.dart';
import 'package:kasie_transie_ambassador/services/utils/app_loader.dart';
import 'package:kasie_transie_ambassador/ui/dashboard.dart';
import 'package:kasie_transie_library/bloc/theme_bloc.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/isolates/dispatch_isolate.dart';
import 'package:kasie_transie_library/isolates/heartbeat_isolate.dart';
import 'package:kasie_transie_library/messaging/heartbeat.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/splash_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';

late fb.FirebaseApp firebaseApp;
fb.User? fbAuthedUser;
var themeIndex = 0;
lib.User? user;
const projectId = 'kasietransie';
const mx = '🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵 KasieTransie Ambassador : main 🔵🔵';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  firebaseApp = await fb.Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  pp('\n\n$mx '
      ' Firebase App has been initialized: ${firebaseApp.name}, checking for authed current user\n');
  fbAuthedUser = fb.FirebaseAuth.instance.currentUser;
  user = await prefs.getUser();
  if (user == null) {
    pp('$mx  this user has NOT been initialized yet ${E.redDot}');
  } else {
    pp('$mx  this user has been initialized! ${E.leaf}: ${user!.name}');
  }
  await AppLoader.init();
  await SPService.init();
  Get.put(AuthService());

  final action = ActionCodeSettings(
    url: 'https://kasietransie2023.page.link/1gGs',
    handleCodeInApp: true,
    androidMinimumVersion: '1',
    androidPackageName: 'com.boha.kasie_transie_ambassador',
    // iOSBundleId: 'com.boha.kasieTransieOwner',
  );

  FirebaseUIAuth.configureProviders([
    EmailLinkAuthProvider(
      actionCodeSettings: action,
    ),
    // ... other providers
  ]);
  pp('$mx  EmailLinkAuthProvider has been initialized! ${E.leaf} ${action.asMap()}');
  // Check if you received the link via `getInitialLink` first
  final PendingDynamicLinkData? initialLink =
  await FirebaseDynamicLinks.instance.getInitialLink();

  if (initialLink != null) {
    final Uri deepLink = initialLink.link;
    pp('$mx  initialLink! ${E.leaf}: ${deepLink.data}');

    // Example of using the dynamic link to push the user to a different screen
    //Navigator.of(context).push(route)
  } else {
    pp('$mx  initialLink is null! ${E.redDot}');
  }

  FirebaseDynamicLinks.instance.onLink.listen(
        (pendingDynamicLinkData) {
      // Set up the `onLink` event listener next as it may be received here
      final Uri deepLink = pendingDynamicLinkData.link;
      pp('$mx  deepLink from listen! ${E.leaf}: ${deepLink.data}');
    },
  );

  Workmanager().initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode:
      true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  );

  runApp(const ProviderScope(child: AmbassadorApp()));
}

class AmbassadorApp extends ConsumerWidget {
  const AmbassadorApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    pp('$mx ref from RiverPod Provider: ref: $ref');
    // var m = ref.watch(countryProvider);
    // if (m.hasValue) {
    //   pp('$mx value from the watch: ${m.value?.length} from RiverPod Provide');
    // }

    return StreamBuilder(
        stream: themeBloc.localeAndThemeStream,
        builder: (ctx, snapshot) {
          if (snapshot.hasData) {
            pp(' 🔵 🔵 🔵'
                'build: theme index has changed to ${snapshot.data!.themeIndex}'
                '  and locale is ${snapshot.data!.locale}');
            themeIndex = snapshot.data!.themeIndex;
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Marshal',
            theme: themeBloc.getTheme(themeIndex).lightTheme,
            darkTheme: themeBloc.getTheme(themeIndex).darkTheme,
            themeMode: ThemeMode.system,
            // home:  const Dashboard(),
            home: AnimatedSplashScreen(
              splash: const SplashWidget(),
              animationDuration: const Duration(milliseconds: 2000),
              curve: Curves.easeInCirc,
              splashIconSize: 160.0,
              nextScreen: const Dashboard(),
              splashTransition: SplashTransition.fadeTransition,
              pageTransitionType: PageTransitionType.leftToRight,
              backgroundColor: Colors.amber.shade800,
            ),
          );
        });
  }
}

final FailedChecker failedChecker = FailedChecker();

class FailedChecker {
  void startChecking() async {
    pp('$mx ... checking for failed uploads ....');
    await heartbeatIsolate.addHeartbeat();
    await dispatchIsolate.addFailedAmbassadorPassengerCounts();
    await dispatchIsolate.addFailedDispatchRecords();
  }
}
