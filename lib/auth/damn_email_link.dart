import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/src/auth_credential.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:kasie_transie_library/l10n/translation_handler.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/language_and_color_chooser.dart';

import '../main.dart';

class DamnEmailLink extends StatefulWidget {
  const DamnEmailLink({Key? key}) : super(key: key);

  @override
  DamnEmailLinkState createState() => DamnEmailLinkState();
}

class DamnEmailLinkState extends State<DamnEmailLink>
    with SingleTickerProviderStateMixin implements EmailLinkAuthListener{
  late AnimationController _controller;
  static const mm = '😡😡😡😡😡😡😡 DamnEmailLink: 💪 ';
  var emailController = TextEditingController(text: "jackmalengata@gmail.com");

  final actionCodeSettings = ActionCodeSettings(
    url: 'https://kasietransie2023.page.link/1gGs',
    handleCodeInApp: true,
    androidInstallApp: true,
    androidMinimumVersion: '1',
    dynamicLinkDomain: 'kasietransie2023.page.link',
    androidPackageName: 'com.boha.kasie_transie_ambassador',
    // iOSBundleId: 'com.boha.kasieTransieOwner',
  );
  final formKey = GlobalKey<FormState>();

  String? enterEmail,
      pleaseEnterEmail,
      selectLangColor,
      emailAddress,
      submitText,
      desc,
      errorEmailVerification,
      successEmailVerification,
      emailAuthTitle;
  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    _setTexts();
    emailLinkAuthProvider.authListener = this;

  }

  _setTexts() async {
    final c = await prefs.getColorAndLocale();
    emailAuthTitle = await translator.translate('emailAuthTitle', c.locale);
    desc = await translator.translate('desc', c.locale);
    pleaseEnterEmail = await translator.translate('pleaseEnterEmail', c.locale);
    submitText = await translator.translate('submitText', c.locale);
    enterEmail = await translator.translate('enterEmail', c.locale);
    selectLangColor = await translator.translate('selectLangColor', c.locale);
    errorEmailVerification =
    await translator.translate('errorEmailVerification', c.locale);
    successEmailVerification =
    await translator.translate('successEmailVerification', c.locale);
    emailAddress = await translator.translate('emailAddress', c.locale);

    setState(() {});
  }

  _chooseColor() async {
    await navigateWithScale(const LanguageAndColorChooser(), context);
    _setTexts();
  }
  _sendEmail() async {
    pp('$mm ... _sendEmail ....');

    try {
      final email = emailController.value.text;
      pp('$mm emailLinkAuthProvider: ${emailLinkAuthProvider.providerId}');
      await prefs.saveEmail(email);
      emailLinkAuthProvider.sendLink(email);
    } catch (e) {
      pp(e);
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title:
            Text(emailAuthTitle == null ? 'Email Link Auth' : emailAuthTitle!),
          ),
          body: Column(
            children: [
              const SizedBox(
                height: 48,
              ),
              Form(
                key: formKey,
                child: Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 48,
                          ),
                          Text(
                            desc == null ? 'Description' : desc!,
                            style: myTextStyleMediumLargeWithColor(
                                context, Theme.of(context).primaryColorLight, 16),
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          TextButton(
                            onPressed: () {
                              _chooseColor();
                            },
                            child: Text(selectLangColor == null
                                ? 'Select language and color'
                                : selectLangColor!),
                          ),
                          const SizedBox(
                            height: 48,
                          ),
                          TextFormField(
                            controller: emailController,
                            validator: (value) {
                              pp('$mm ...validator value: $value - pleaseEnterEmail: $pleaseEnterEmail');
                              if (value == null || value.isEmpty) {
                                return pleaseEnterEmail;
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                                label: Text(emailAddress == null
                                    ? 'Email Address'
                                    : emailAddress!),
                                hintText: pleaseEnterEmail == null
                                    ? 'Please enter your email address'
                                    : pleaseEnterEmail!),
                          ),
                          const SizedBox(
                            height: 48,
                          ),
                          ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  _sendEmail();
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child:
                                Text(submitText == null ? 'Submit' : submitText!),
                              )),
                          const SizedBox(
                            height: 48,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
            ],
          ),
        ));
  }

  @override
  FirebaseAuth get auth => FirebaseAuth.instance;

  @override
  void onBeforeLinkSent(String email) {
    pp('$mm ... onBeforeLinkSent $email');
  }

  @override
  void onBeforeProvidersForEmailFetch() {
    pp('$mm ... onBeforeProvidersForEmailFetch');  }

  @override
  void onBeforeSignIn() {
    pp('$mm ... onBeforeSignIn');  }

  @override
  void onCanceled() {
    pp('$mm ... onCanceled');  }

  @override
  void onCredentialLinked(AuthCredential credential) {
    pp('$mm ... onCredentialLinked: cred: $credential');  }

  @override
  void onCredentialReceived(AuthCredential credential) {
    pp('$mm ... onCredentialReceived: $credential');  }

  @override
  void onDifferentProvidersFound(String email, List<String> providers, AuthCredential? credential) {
    pp('$mm ... onDifferentProvidersFound: ${providers.length} cred: $credential');  }

  @override
  void onError(Object error) {
    pp('$mm ... onError: $error');  }

  @override
  void onLinkSent(String email) {
    pp('$mm ... onLinkSent $email');
  }

  @override
  void onMFARequired(MultiFactorResolver resolver) {
    pp('$mm ... onMFARequired');  }

  @override
  void onSignedIn(UserCredential credential) {
    pp('$mm ... onSignedIn cred: $credential');  }

  @override
  AuthProvider<AuthListener, AuthCredential> get provider => throw UnimplementedError();

}
