import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:kasie_transie_library/bloc/data_api_dog.dart';
import 'package:kasie_transie_library/bloc/list_api_dog.dart';
import 'package:kasie_transie_library/isolates/routes_isolate.dart';
import 'package:kasie_transie_library/l10n/translation_handler.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:kasie_transie_library/data/schemas.dart' as lib;

class CellPhoneAuthSignin extends StatefulWidget {
  const CellPhoneAuthSignin({
    Key? key,
    required this.dataApiDog,
  }) : super(key: key);

  final DataApiDog dataApiDog;

  @override
  CellPhoneAuthSigninState createState() => CellPhoneAuthSigninState();
}

class CellPhoneAuthSigninState extends State<CellPhoneAuthSignin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final _formKey = GlobalKey<FormState>();
  bool _codeHasBeenSent = false;
  fb.FirebaseAuth firebaseAuth = fb.FirebaseAuth.instance;
  final mm = '🥬🥬🥬🥬🥬🥬😡 AuthPhoneSigninCard: 😡';
  String? phoneVerificationId;
  String? code;
  final phoneController = TextEditingController(text: "+19095550008");
  final codeController = TextEditingController(text: '123456');
  final orgNameController = TextEditingController();
  final adminController = TextEditingController();
  final errorController = StreamController<ErrorAnimationType>();
  String? currentText;
  bool verificationFailed = false;
  bool verificationCompleted = false;
  bool busy = false;
  bool initializing = false;
  lib.User? user;
  SignInStrings? signInStrings;

  @override
  void initState() {
    super.initState();
    _setTexts();
  }

  Future _setTexts() async {
    final sett = await prefs.getSettings();
    if (sett == null) {
      return;
    }
    signInStrings = await SignInStrings.getTranslated(sett);
    setState(() {});
  }

  void _processSignIn() async {
    pp('\n\n$mm _processSignIn ... sign in the user using code: ${codeController.value.text}');
    setState(() {
      busy = true;
    });
    code = codeController.value.text;

    if (code == null || code!.isEmpty) {
      showSnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).primaryColor,
          textStyle: myTextStyleMedium(context),
          message: signInStrings == null
              ? 'Please put in the code that was sent to you'
              : signInStrings!.putInCode,
          context: context);
      setState(() {
        busy = false;
      });
      return;
    }

    try {
      final result = await _danceWithFirebase();
      pp('\n$mm user signed in to firebase? result: $result');
      user = await prefs.getUser();
      setState(() {
        busy = false;
      });
      if (result == 0 && mounted) {
        pp('\n$mm popping ......................');
        routesIsolate.getRoutes(user!.associationId!);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future _danceWithFirebase() async {
    fb.UserCredential? userCred;
    fb.PhoneAuthCredential authCredential = fb.PhoneAuthProvider.credential(
        verificationId: phoneVerificationId!, smsCode: code!);
    userCred = await firebaseAuth.signInWithCredential(authCredential);
    pp('\n$mm user signed in to firebase? userCred: $userCred');
    pp('$mm seeking to acquire this user from the Kasie database by their id: 🌀🌀🌀${userCred.user?.uid}');
    user = await listApiDog.getUserById(userCred.user!.uid); //

    if (user != null) {
      pp('$mm KasieTransie user found on database:  🍎 ${user!.toJson()} 🍎');
      await prefs.saveUser(user!);
      final ass = await listApiDog.getAssociationById(user!.associationId!);
      final cars =
          await listApiDog.getAssociationVehicles(user!.associationId!, true);
      pp('$mm KasieTransie cars found on database:  🍎 ${cars.length} 🍎');
      final countries = await listApiDog.getCountries();
      pp('$mm KasieTransie countries found on database:  🍎 ${countries.length} 🍎');
      await routesIsolate.getRoutes(user!.associationId!);

      lib.Country? myCountry;
      for (var country in countries) {
        if (country.countryId == ass.countryId!) {
          myCountry = country;
          await prefs.saveCountry(myCountry);
          break;
        }
      }
      pp('$mm KasieTransie; my country the beloved:  🍎 ${myCountry!.name!} 🍎');
    } else {
      if (mounted) {
        showSnackBar(
            padding: 20,
            duration: const Duration(seconds: 5),
            message: 'User not found',
            context: context);
        return 9;
      }
    }
    return 0;
  }

  void _handleError(e) async {
    pp('\n\n\n $mm ${E.redDot} This is annoying! .... $e \n\n\n');
    String msg = 'Unable to Sign in. Have you registered an association?';
    if (msg.contains('dup key')) {
      msg = signInStrings == null
          ? 'Duplicate association name'
          : signInStrings!.duplicateOrg;
    }
    if (msg.contains('not found')) {
      msg = signInStrings == null
          ? 'User not found'
          : signInStrings!.memberNotExist;
    }
    if (msg.contains('Bad response format')) {
      msg = signInStrings == null
          ? 'User not found'
          : signInStrings!.memberNotExist;
    }
    if (msg.contains('server cannot be reached')) {
      msg = signInStrings == null
          ? 'Server cannot be reached'
          : signInStrings!.serverUnreachable;
    }
    pp(msg);
    if (mounted) {
      showSnackBar(
          duration: const Duration(seconds: 5),
          textStyle: myTextStyleMedium(context),
          padding: 20.0,
          message: msg,
          context: context);
      setState(() {
        busy = false;
      });
    }
  }

  void _verifyPhoneNumber() async {
    pp('$mm _start: ....... Verifying phone number ...');
    setState(() {
      busy = true;
    });

    await firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneController.value.text,
        timeout: const Duration(seconds: 90),
        verificationCompleted: (fb.PhoneAuthCredential phoneAuthCredential) {
          pp('$mm verificationCompleted: $phoneAuthCredential');
          var message = phoneAuthCredential.smsCode ?? "";
          if (message.isNotEmpty) {
            codeController.text = message;
          }
          if (mounted) {
            setState(() {
              verificationCompleted = true;
              busy = false;
            });
            showSnackBar(
                backgroundColor: Theme.of(context).colorScheme.background,
                textStyle: myTextStyleMedium(context),
                message: signInStrings == null
                    ? 'Verification completed. Thank you!'
                    : signInStrings!.verifyComplete,
                context: context);
          }
        },
        verificationFailed: (fb.FirebaseAuthException error) {
          pp('\n$mm verificationFailed : $error \n');
          if (mounted) {
            setState(() {
              verificationFailed = true;
              busy = false;
            });
            showSnackBar(
                backgroundColor: Theme.of(context).colorScheme.background,
                textStyle: myTextStyleMedium(context),
                message: signInStrings == null
                    ? 'Verification failed. Please try later'
                    : signInStrings!.verifyFailed,
                context: context);
          }
        },
        codeSent: (String verificationId, int? forceResendingToken) {
          pp('$mm onCodeSent: 🔵 verificationId: $verificationId 🔵 will set state ...');
          phoneVerificationId = verificationId;
          if (mounted) {
            pp('$mm setting state  _codeHasBeenSent to true');
            setState(() {
              _codeHasBeenSent = true;
              busy = false;
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          pp('$mm codeAutoRetrievalTimeout verificationId: $verificationId');
          if (mounted) {
            setState(() {
              busy = false;
              _codeHasBeenSent = false;
            });
            showSnackBar(
                message: signInStrings == null
                    ? 'Code retrieval failed, please try again'
                    : signInStrings!.verifyFailed,
                context: context);
            Navigator.of(context).pop();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Phone SignIn'),
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(100), child: Column()),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: getRoundedBorder(radius: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      busy
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 4,
                                      backgroundColor: Colors.pink,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(
                              height: 12,
                            ),
                      const SizedBox(
                        height: 24,
                      ),
                      SizedBox(
                        width: 400,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              signInStrings == null
                                  ? 'Phone Authentication'
                                  : signInStrings!.phoneAuth,
                              style: myTextStyleMediumBold(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 8,
                                ),
                                SizedBox(
                                  width: 400,
                                  child: TextFormField(
                                    controller: phoneController,
                                    keyboardType: TextInputType.phone,
                                    style: myTextStyleMediumLargeWithColor(
                                        context,
                                        Theme.of(context).primaryColor,
                                        28),
                                    decoration: InputDecoration(
                                        hintText: signInStrings == null
                                            ? 'Enter Phone Number'
                                            : signInStrings!.enterPhone,
                                        label: Text(signInStrings == null
                                            ? 'Phone Number'
                                            : signInStrings!.phoneNumber)),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return signInStrings == null
                                            ? 'Please enter Phone Number'
                                            : signInStrings!.enterPhone;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(
                                  height: 60,
                                ),
                                ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        _verifyPhoneNumber();
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text(signInStrings == null
                                          ? 'Verify Phone Number'
                                          : signInStrings!.verifyPhone),
                                    )),
                                const SizedBox(
                                  height: 20,
                                ),
                                _codeHasBeenSent
                                    ? SizedBox(
                                        height: 200,
                                        child: Column(
                                          children: [
                                            Text(
                                              signInStrings == null
                                                  ? 'Enter SMS pin code sent'
                                                  : signInStrings!.enterSMS,
                                              style: myTextStyleSmall(context),
                                            ),
                                            const SizedBox(
                                              height: 16,
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(4.0),
                                              child: PinCodeTextField(
                                                length: 6,
                                                obscureText: false,
                                                textStyle:
                                                    myNumberStyleLarge(context),
                                                animationType:
                                                    AnimationType.fade,
                                                pinTheme: PinTheme(
                                                  shape: PinCodeFieldShape.box,
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  fieldHeight: 50,
                                                  fieldWidth: 40,
                                                  activeFillColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .background,
                                                ),
                                                animationDuration:
                                                    const Duration(
                                                        milliseconds: 300),
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .background,
                                                enableActiveFill: true,
                                                errorAnimationController:
                                                    errorController,
                                                controller: codeController,
                                                onCompleted: (v) {
                                                  pp("$mm PinCodeTextField: Completed: $v - should call submit ...");
                                                },
                                                onChanged: (value) {
                                                  pp(value);
                                                  setState(() {
                                                    currentText = value;
                                                  });
                                                },
                                                beforeTextPaste: (text) {
                                                  pp("$mm Allowing to paste $text");
                                                  //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
                                                  //but you can show anything you want here, like your pop up saying wrong paste format or etc
                                                  return true;
                                                },
                                                appContext: context,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 28,
                                            ),
                                            busy
                                                ? const SizedBox(
                                                    height: 16,
                                                    width: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 4,
                                                      backgroundColor:
                                                          Colors.pink,
                                                    ),
                                                  )
                                                : ElevatedButton(
                                                    onPressed: _processSignIn,
                                                    style: ButtonStyle(
                                                      elevation:
                                                          MaterialStateProperty
                                                              .all<double>(8.0),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4.0),
                                                      child: Text(
                                                          signInStrings == null
                                                              ? 'Send Code'
                                                              : signInStrings!
                                                                  .sendCode),
                                                    )),
                                          ],
                                        ),
                                      )
                                    : const SizedBox(),
                              ],
                            )),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

class SignInStrings {
  late String signIn,
      memberSignedIn,
      putInCode,
      duplicateOrg,
      enterPhone,
      serverUnreachable,
      phoneSignIn,
      phoneAuth,
      phoneNumber,
      verifyPhone,
      enterSMS,
      sendCode,
      verifyComplete,
      verifyFailed,
      enterOrg,
      orgName,
      enterAdmin,
      adminName,
      enterEmail,
      pleaseSelectCountry,
      memberNotExist,
      registerOrganization,
      signInOK,
      enterPassword,
      password,
      emailAddress;

  SignInStrings(
      {required this.signIn,
      required this.memberSignedIn,
      required this.putInCode,
      required this.duplicateOrg,
      required this.enterPhone,
      required this.serverUnreachable,
      required this.phoneSignIn,
      required this.phoneAuth,
      required this.phoneNumber,
      required this.verifyPhone,
      required this.enterSMS,
      required this.sendCode,
      required this.registerOrganization,
      required this.verifyComplete,
      required this.verifyFailed,
      required this.enterOrg,
      required this.orgName,
      required this.enterAdmin,
      required this.adminName,
      required this.memberNotExist,
      required this.enterEmail,
      required this.pleaseSelectCountry,
      required this.signInOK,
      required this.enterPassword,
      required this.password,
      required this.emailAddress});

  static Future<SignInStrings> getTranslated(lib.SettingsModel sett) async {
    var signIn = await translator.translate('signIn', sett!.locale!);
    var memberNotExist =
        await translator.translate('memberNotExist', sett.locale!);
    var memberSignedIn =
        await translator.translate('memberSignedIn', sett.locale!);
    var putInCode = await translator.translate('putInCode', sett.locale!);
    var duplicateOrg = await translator.translate('duplicateOrg', sett.locale!);
    var pleaseSelectCountry =
        await translator.translate('pleaseSelectCountry', sett.locale!);

    var registerOrganization =
        await translator.translate('registerOrganization', sett.locale!);

    var enterPhone = await translator.translate('enterPhone', sett.locale!);
    var signInOK = await translator.translate('signInOK', sett.locale!);

    var enterPassword =
        await translator.translate('enterPassword', sett.locale!);

    var password = await translator.translate('password', sett.locale!);

    var serverUnreachable =
        await translator.translate('serverUnreachable', sett.locale!);
    var phoneSignIn = await translator.translate('phoneSignIn', sett.locale!);
    var phoneAuth = await translator.translate('phoneAuth', sett.locale!);
    var phoneNumber = await translator.translate('phoneNumber', sett.locale!);
    var verifyPhone = await translator.translate('verifyPhone', sett.locale!);
    var enterSMS = await translator.translate('enterSMS', sett.locale!);
    var sendCode = await translator.translate('sendCode', sett.locale!);
    var verifyComplete =
        await translator.translate('verifyComplete', sett.locale!);
    var verifyFailed = await translator.translate('verifyFailed', sett.locale!);
    var enterOrg = await translator.translate('enterOrg', sett.locale!);
    var orgName = await translator.translate('orgName', sett.locale!);
    var enterAdmin = await translator.translate('enterAdmin', sett.locale!);
    var adminName = await translator.translate('adminName', sett.locale!);
    var enterEmail = await translator.translate('enterEmail', sett.locale!);
    var emailAddress = await translator.translate('emailAddress', sett.locale!);

    final m = SignInStrings(
        signIn: signIn,
        signInOK: signInOK,
        password: password,
        enterPassword: enterPassword,
        memberSignedIn: memberSignedIn,
        putInCode: putInCode,
        duplicateOrg: duplicateOrg,
        enterPhone: enterPhone,
        serverUnreachable: serverUnreachable,
        phoneSignIn: phoneSignIn,
        phoneAuth: phoneAuth,
        pleaseSelectCountry: pleaseSelectCountry,
        phoneNumber: phoneNumber,
        verifyPhone: verifyPhone,
        enterSMS: enterSMS,
        sendCode: sendCode,
        registerOrganization: registerOrganization,
        verifyComplete: verifyComplete,
        verifyFailed: verifyFailed,
        enterOrg: enterOrg,
        orgName: orgName,
        enterAdmin: enterAdmin,
        adminName: adminName,
        enterEmail: enterEmail,
        memberNotExist: memberNotExist,
        emailAddress: emailAddress);

    return m;
  }
}
