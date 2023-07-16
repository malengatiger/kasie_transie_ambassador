import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:kasie_transie_library/utils/functions.dart';

class SigninWithLink2 extends StatefulWidget {

  const SigninWithLink2({super.key});


  @override
  State<SigninWithLink2> createState() => _SigninWithLink2State();
}

class _SigninWithLink2State extends State<SigninWithLink2> {
  static const mm = '😡😡😡😡😡😡😡 SigninWithLink2: 💪 ';

  final actionCodeSettings = ActionCodeSettings(
    url: 'https://kasietransie2023.page.link/1gGs',
    handleCodeInApp: true,
    androidInstallApp: true,
    androidMinimumVersion: '1',
    dynamicLinkDomain: 'kasietransie2023.page.link',
    androidPackageName: 'com.boha.kasie_transie_ambassador',
    // iOSBundleId: 'com.boha.kasieTransieOwner',
  );
  late EmailLinkAuthProvider prov;

  bool busy = false;

  @override
  void initState() {
    super.initState();
    prov = EmailLinkAuthProvider(actionCodeSettings: actionCodeSettings);
  }

  late EmailLinkAuthController controller;
  void _sendEmailLink(String email) {
    pp('$mm ... _sendEmailLink email: $email');
    setState(() {
      busy = true;
    });
    try {
      controller.sendLink(email);
    } catch (e) {
      pp('$mm Error: $e');
    }
    setState(() {
      busy = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('This is FUCKED!'),
      ),
      body: Card(
        shape: getRoundedBorder(radius: 16),
        elevation: 8,
        child: AuthFlowBuilder<EmailLinkAuthController>(
          provider: prov,
          onComplete: (cred) {
            pp('$mm ... onComplete cred: ${cred.asMap()}');
          },
          listener: (oldState, newState, ctrl) {
            pp('$mm ... listener fired: $oldState $newState');

            if (newState is SignedIn) {
              Navigator.of(context).pushReplacementNamed('/profile');
            }
          },
          builder: (context, state, ctrl, child) {
            pp('$mm ... builder state: $state action: ${ctrl.action}');
            controller = ctrl;
            if (state is Uninitialized) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    shape: getRoundedBorder(radius: 16),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Kasie Transie',
                            style: myTextStyleMediumLargeWithColor(
                                context, Theme.of(context).primaryColorLight, 36),
                          ),
                          const SizedBox(
                            height: 48,
                          ),
                          TextField(
                            decoration:
                                const InputDecoration(label: Text('Email')),
                            onSubmitted: (email) {
                              pp('$mm onSubmitted: $email');
                              _sendEmailLink(email);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else if (state is AwaitingDynamicLink) {
              pp('$mm ... onComplete cred: $state');

              return const CircularProgressIndicator();
            } else if (state is AuthFailed) {
              pp('$mm ... onComplete cred: $state');

              return ErrorText(exception: state.exception);
            } else {
              pp('$mm ... Unknown state $state');

              return Text('Unknown state $state');
            }
          },
        ),
      ),
    ));
  }
}
