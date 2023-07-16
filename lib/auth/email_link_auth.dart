import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:kasie_transie_library/l10n/translation_handler.dart';
import 'package:kasie_transie_library/utils/functions.dart';
import 'package:kasie_transie_library/utils/navigator_utils.dart';
import 'package:kasie_transie_library/utils/prefs.dart';
import 'package:kasie_transie_library/widgets/language_and_color_chooser.dart';

//... kasietransieambassador.page.link/.well-known/assetlinks.json
class EmailLinkAuth extends StatefulWidget {
  const EmailLinkAuth({Key? key}) : super(key: key);

  @override
  EmailLinkAuthState createState() => EmailLinkAuthState();
}

class EmailLinkAuthState extends State<EmailLinkAuth>
    with SingleTickerProviderStateMixin
    implements EmailAuthListener {
  late AnimationController controller;
  static const projectId = 'thermal-effort-366015';
  static const mm = '🍎🍎🍎🍎🍎🍎 EmailLinkAuth 🍎🍎🍎';
  late ActionCodeSettings actionCodeSettings;
  final formKey = GlobalKey<FormState>();
  @override
  late EmailLinkAuthProvider provider;

  String? enterEmail,
      pleaseEnterEmail,
      selectLangColor,
      emailAddress,
      submitText,
      desc,
      errorEmailVerification,
      successEmailVerification,
      emailAuthTitle;

  void _init() {
    pp('$mm ... _init .....');
    // https://kasie.page.link/?link=your_deep_link&apn=package_name[&amv=minimum_version][&afl=fallback_link]

    actionCodeSettings = ActionCodeSettings(
      url: 'https://kasietransie2023.page.link/1gGs',
      handleCodeInApp: true,
      androidInstallApp: true,
      androidMinimumVersion: '1',
      androidPackageName: 'com.boha.kasie_transie_ambassador',
      // iOSBundleId: 'com.boha.kasieTransieOwner',
    );
    provider = EmailLinkAuthProvider(
      actionCodeSettings: actionCodeSettings,
    );
    pp('$mm ... provider: ${provider.actionCodeSettings.asMap()}');
  }
  Future<void> _setDynamicLink() async {
    final dynamicLinkParams = DynamicLinkParameters(
      link: Uri.parse("https://kasietransie.com/ambassador/1234s"),
      uriPrefix: "https://kasietransie.page.link",
      androidParameters: const AndroidParameters(
        packageName: "com.boha.kasie_transie_ambassador",
        minimumVersion: 23,
      ),
      // iosParameters: const IOSParameters(
      //   bundleId: "com.example.app.ios",
      //   appStoreId: "123456789",
      //   minimumVersion: "1.0.1",
      // ),
      // googleAnalyticsParameters: const GoogleAnalyticsParameters(
      //   source: "twitter",
      //   medium: "social",
      //   campaign: "example-promo",
      // ),
      // socialMetaTagParameters: SocialMetaTagParameters(
      //   title: "Example of a Dynamic Link",
      //   imageUrl: Uri.parse("https://example.com/image.png"),
      // ),
    );
    final dynamicLink =
        await FirebaseDynamicLinks.instance.buildShortLink(dynamicLinkParams);
    pp('$mm ... dynamicLink: ${dynamicLink.asMap()}');
  }

  @override
  void initState() {
    controller = AnimationController(vsync: this);
    super.initState();
    _init();
    _setDynamicLink();
    _setTexts();
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
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  var emailController = TextEditingController(text: "jackmalengata@gmail.com");

  void _sendEmail() {
    pp('$mm ... _sendEmail .... ');

    var emailAuth = emailController.value.text;
    FirebaseAuth.instance
        .sendSignInLinkToEmail(
            email: emailAuth, actionCodeSettings: actionCodeSettings)
        .catchError((onError) {
      pp('$mm Error sending email verification $onError');
    }).then((value) {
      pp('$mm Successfully sent email verification');
    });
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
  void onBeforeProvidersForEmailFetch() {
    pp('$mm ... onBeforeProvidersForEmailFetch');
  }

  @override
  void onBeforeSignIn() {
    pp('$mm ... onBeforeSignIn ');
  }

  @override
  void onCanceled() {
    pp('$mm ... onCanceled');
  }

  @override
  void onCredentialLinked(AuthCredential credential) {
    pp('$mm ... onCredentialLinked: ${credential.asMap()}');
  }

  @override
  void onCredentialReceived(AuthCredential credential) {
    pp('$mm ... onCredentialReceived: ${credential.asMap()}');
  }

  @override
  void onDifferentProvidersFound(
      String email, List<String> providers, AuthCredential? credential) {
    pp('$mm ... onDifferentProvidersFound: email $email');
  }

  @override
  void onError(Object error) {
    pp('$mm ... $error');
  }

  @override
  void onMFARequired(MultiFactorResolver resolver) {
    pp('$mm ... onMFARequired: resolver: ${resolver.toString()}');
  }

  @override
  void onSignedIn(UserCredential credential) {
    pp('$mm ... onSignedIn ... credential: ${credential.toString()}');
  }
}
