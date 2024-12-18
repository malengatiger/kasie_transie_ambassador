import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:kasie_transie_library/utils/functions.dart';


class IntroPage extends StatefulWidget {
  const IntroPage(
      {super.key,
      required this.assetPath,
      required this.title,
      required this.text,
      this.width});

  final String assetPath;
  final String title;
  final String text;
  final double? width;

  @override
  IntroPageState createState() => IntroPageState();
}

class IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  late AnimationController _textAnimationController;
  late AnimationController _titleAnimationController;

  @override
  void initState() {
    _textAnimationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 2000),
        reverseDuration: const Duration(milliseconds: 2000),
        vsync: this);
    _titleAnimationController = AnimationController(
        value: 0.0,
        duration: const Duration(milliseconds: 500),
        reverseDuration: const Duration(milliseconds: 1000),
        vsync: this);
    super.initState();
    _titleAnimationController
        .forward()
        .then((value) => _textAnimationController.forward());
  }

  @override
  void dispose() {
    _textAnimationController.dispose();
    _titleAnimationController.dispose();
    super.dispose();
  }

  int textLength = 0;
  @override
  Widget build(BuildContext context) {
    textLength = widget.text.length;
    var height = 200.0;
    if (textLength > 500) {
      height = 400.0;
    }
    if (textLength < 500) {
      height = 300.0;
    }
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    var  color = getTextColorForBackground(Theme.of(context).primaryColor);

    if (isDarkMode) {
      color = Theme.of(context).primaryColor;
    }
    return SafeArea(
        child: Scaffold(
      body: Stack(
        children: [
          Container(
            width: widget.width == null ? double.infinity : widget.width!,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(widget.assetPath),
                  fit: BoxFit.cover,
                  opacity: 0.6),
            ),
          ),
          Positioned(
              top: 80,
              bottom: 80,
              left: 10,
              right: 10,
              child: SizedBox(
                height: height,
                width: 300,
                child: Card(
                  color: Colors.black26,
                  shape: getRoundedBorder(radius: 16),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        AnimatedBuilder(
                          animation: _textAnimationController,
                          builder: (BuildContext context, Widget? child) {
                            return FadeScaleTransition(
                              animation: _textAnimationController,
                              child: child,
                            );
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              widget.title,
                              style: myTextStyleLargeWithColor(context, color),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: AnimatedBuilder(
                            animation: _textAnimationController,
                            builder: (BuildContext context, Widget? child) {
                              return FadeScaleTransition(
                                animation: _textAnimationController,
                                child: child,
                              );
                            },
                            child: Column(
                              children: [
                                ClipRect(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                        // color: Colors.white.withOpacity(0.6),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(16.0),
                                        )),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        widget.text,
                                        style: myTextStyleMedium(context),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    ));
  }
}
