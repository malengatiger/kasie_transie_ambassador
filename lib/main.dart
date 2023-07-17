import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasie_transie_ambassador/ui/dashboard.dart';
import 'package:kasie_transie_library/bloc/theme_bloc.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;
import 'package:kasie_transie_library/isolates/dispatch_isolate.dart';
import 'package:kasie_transie_library/isolates/heartbeat_isolate.dart';
import 'package:kasie_transie_library/messaging/heartbeat.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/auth/damn_email_link.dart';
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

  final action = ActionCodeSettings(
    url: 'https://kasietransie2023.page.link/1gGs',
    handleCodeInApp: true,
    androidMinimumVersion: '1',
    dynamicLinkDomain: 'kasietransie2023.page.link',
    androidPackageName: 'com.boha.kasie_transie_ambassador',
    // iOSBundleId: 'com.boha.kasieTransieOwner',
  );
  await initializeEmailLinkProvider(action);
  FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) async {
    final Uri deepLink = dynamicLinkData.link;
    bool foo = FirebaseAuth.instance.isSignInWithEmailLink(deepLink.toString());
    pp('...... deepLink is email link? $foo');
    pp(dynamicLinkData.asMap());
    // if (FirebaseAuth.instance.isSignInWithEmailLink(dynamicLinkData.link.toString())) {
    //   try {
    //     // The client SDK will parse the code from the link for you.
    //     final userCredential = await FirebaseAuth.instance
    //         .signInWithEmailLink(email: emailAuth, emailLink: emailLink);
    //
    //     // You can access the new user via userCredential.user.
    //     final emailAddress = userCredential.user?.email;
    //
    //     pp('Successfully signed in with email link!');
    //   } catch (error) {
    //     pp('Error signing in with email link.');
    //   }
    // }

  });
  Workmanager().initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode:
          true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
      );

  runApp(const ProviderScope(child: AmbassadorApp()));
}


class AmbassadorApp extends StatelessWidget {
  const AmbassadorApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

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
            // initialRoute: '/dashboard',
            // routes: {
            //     '/login': (context) {
            //       return const SigninWithLink();
            //     },
            //     '/dashboard': (context) => const Dashboard(),
            //   },
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
