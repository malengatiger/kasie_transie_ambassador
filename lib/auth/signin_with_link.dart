
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:kasie_transie_library/l10n/translation_handler.dart';
import 'package:kasie_transie_library/utils/emojis.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/language_and_color_chooser.dart';

class SigninWithLink extends StatefulWidget {
  const SigninWithLink({super.key});

  @override
  State<SigninWithLink> createState() => SigninWithLinkState();
}

class SigninWithLinkState extends State<SigninWithLink>
    implements EmailLinkAuthListener {
  static const mm = '🍎🍎🍎🍎🍎🍎 SigninWithLink 🍎🍎🍎';

  String? enterEmail,
      pleaseEnterEmail,
      selectLangColor,
      emailAddress,
      submitText,
      desc,
      errorEmailVerification,
      successEmailVerification,
      emailAuthTitle;

  bool busy = false;
  final actionCodeSettings = ActionCodeSettings(
    url: 'https://kasietransie2023.page.link/1gGs',
    handleCodeInApp: true,
    androidInstallApp: true,
    androidMinimumVersion: '1',
    androidPackageName: 'com.boha.kasie_transie_ambassador',
    // iOSBundleId: 'com.boha.kasieTransieOwner',
  );

  @override
  void initState() {
    super.initState();
    _setTexts();
    auth = FirebaseAuth.instance;

  }
  void _init() {

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

  @override
  late FirebaseAuth auth;

  @override
  void onBeforeLinkSent(String email) {
    pp('$mm ... onBeforeLinkSent: email: $email');
    setState(() {
      busy = true;
    });
  }

  @override
  void onLinkSent(String email) {
    pp('$mm ... onLinkSent ... email: $email');
    setState(() {});
  }

  final formKey = GlobalKey<FormState>();
  var emailController = TextEditingController(text: "jackmalengata@gmail.com");

  void _sendEmail() {
    pp('$mm ... _sendEmail .... ${emailController.value.text}');
    var email = emailController.value.text;
    //auth = FirebaseAuth.instance;
    // pp('$mm ... _sendEmail .... auth.languageCode:  ${auth.languageCode}');
    provider.authListener = this;
    provider.auth.sendSignInLinkToEmail(email: email, actionCodeSettings: actionCodeSettings);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        title:
            Text(emailAuthTitle == null ? 'Email Link Auth' : emailAuthTitle!),
      ),
      body: Stack(
        children: [
          Column(
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
                                child: Text(
                                    submitText == null ? 'Submit' : submitText!),
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
          busy? const Center(
            child: CircularProgressIndicator(
              strokeWidth: 8,
            ),
          ) : const SizedBox(),
        ],
      )
    ));
  }

  @override
  void onBeforeProvidersForEmailFetch() {
    pp('$mm ... onBeforeProvidersForEmailFetch ...');

    setState(() {
      busy = true;
    });
  }

  @override
  void onBeforeSignIn() {
    pp('$mm ... onBeforeSignIn ...');
    setState(() {
      busy = true;
    });
  }

  @override
  void onCanceled() {
    pp('$mm ... onCanceled ${E.redDot}');
    setState(() {
      busy = false;
    });
  }

  @override
  void onCredentialLinked(AuthCredential credential) {
    pp('$mm ... onCredentialLinked : ${credential.asMap()}');
    Navigator.of(context).pop(credential);
    //Navigator.of(context).pushReplacementNamed('/profile');
  }

  @override
  void onDifferentProvidersFound(
      String email, List<String> providers, AuthCredential? credential) {
    showDifferentMethodSignInDialog(
      context: context,
      availableProviders: providers,
      providers: FirebaseUIAuth.providersFor(FirebaseAuth.instance.app),
    );
  }

  @override
  void onError(Object error) {
    try {
      // tries default recovery strategy
      defaultOnAuthError(provider, error);
    } catch (err) {
      setState(() {
        defaultOnAuthError(provider, error);
      });
    }
  }

  @override
  void onSignedIn(UserCredential credential) {
    Navigator.of(context).pushReplacementNamed('/profile');
  }

  @override
  void onCredentialReceived(AuthCredential credential) {
    // TODO: implement onCredentialReceived
  }

  @override
  void onMFARequired(MultiFactorResolver resolver) {
    // TODO: implement onMFARequired
  }

  @override
  AuthProvider<AuthListener, AuthCredential> get provider => EmailLinkAuthProvider(
      actionCodeSettings: ActionCodeSettings(
        url: 'https://kasietransie2023.page.link/1gGs',
        handleCodeInApp: true,
        androidInstallApp: true,
        androidMinimumVersion: '1',
        androidPackageName: 'com.boha.kasie_transie_ambassador',
        // iOSBundleId: 'com.boha.kasieTransieOwner',
      ))
    ..authListener = this;

}
