library introduction_screen;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:introduction_screen/src/model/page_view_model.dart';
import 'package:introduction_screen/src/ui/intro_button.dart';
import 'package:introduction_screen/src/ui/intro_page.dart';

class IntroductionScreen extends StatefulWidget {
  /// All pages of the onboarding
  final List<PageViewModel> pages;

  /// Callback when Done button is pressed
  final VoidCallback onDone;

  final Future<bool> Function() onIntroPressedOverride;

  /// Done button
  final Widget done;

  /// Callback when Skip button is pressed
  final VoidCallback onSkip;

  /// Callback when page change
  final ValueChanged<int> onChange;

  /// Skip button
  final Widget skip;

  /// Next button
  final Widget next;

  final Widget prev;

  /// Is the Skip button should be display
  ///
  /// @Default `false`
  final bool showSkipButton;

  /// Is the Next button should be display
  ///
  /// @Default `true`
  final bool showNextButton;

  /// Is the progress indicator should be display
  ///
  /// @Default `true`
  final bool isProgress;

  /// Is the user is allow to change page
  ///
  /// @Default `false`
  final bool freeze;

  /// Global background color (only visible when a page has a transparent background color)
  final Color globalBackgroundColor;

  /// Dots decorator to custom dots color, size and spacing
  final DotsDecorator dotsDecorator;

  /// Animation duration in millisecondes
  ///
  /// @Default `350`
  final int animationDuration;

  final int prevAnimationDuration;

  /// Index of the initial page
  ///
  /// @Default `0`
  final int initialPage;

  /// Flex ratio of the skip button
  ///
  /// @Default `1`
  final int skipFlex;

  final int prevFlex;

  /// Flex ratio of the progress indicator
  ///
  /// @Default `1`
  final int dotsFlex;

  /// Flex ratio of the next/done button
  ///
  /// @Default `1`
  final int nextFlex;

  /// Type of animation between pages
  ///
  /// @Default `Curves.easeIn`
  final Curve curve;

  const IntroductionScreen({
    Key key,
    @required this.pages,
    @required this.onDone,
    @required this.done,
    this.onSkip,
    this.onChange,
    this.skip,
    this.next,
    this.prev,
    this.showSkipButton = false,
    this.showNextButton = true,
    this.isProgress = true,
    this.freeze = false,
    this.globalBackgroundColor,
    this.dotsDecorator = const DotsDecorator(),
    this.animationDuration = 350,
    this.prevAnimationDuration = 350,
    this.onIntroPressedOverride,
    this.initialPage = 0,
    this.skipFlex = 1,
    this.dotsFlex = 1,
    this.nextFlex = 1,
    this.prevFlex = 1,
    this.curve = Curves.easeIn,
  })  : assert(pages != null),
        assert(
          pages.length > 0,
          "You provide at least one page on introduction screen !",
        ),
        assert(onDone != null),
        assert(done != null),
        assert((skip != null && showSkipButton) || !showSkipButton),
        assert(skipFlex >= 0 && dotsFlex >= 0 && nextFlex >= 0),
        super(key: key);

  @override
  _IntroductionScreenState createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  PageController _pageController;
  double _currentPage = 0.0;
  bool _isSkipPressed = false;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    int initialPage = min(widget.initialPage, widget.pages.length - 1);
    _currentPage = initialPage.toDouble();
    _pageController = PageController(initialPage: initialPage);
  }

  void _onNext() {
    animateScroll(min(_currentPage.round() + 1, widget.pages.length - 1),
        widget.animationDuration);
  }

  void _onPrev() {
    animateScroll(
        max(_currentPage.round() - 1, 0), widget.prevAnimationDuration);
  }

  Future<void> _onSkip() async {
    if (widget.onSkip != null) return widget.onSkip();

    setState(() => _isSkipPressed = true);
    await animateScroll(widget.pages.length - 1, widget.animationDuration);
    setState(() => _isSkipPressed = false);
  }

  Future<void> animateScroll(int page, [int duration = 350]) async {
    setState(() => _isScrolling = true);
    await _pageController.animateToPage(
      page,
      duration: Duration(milliseconds: duration),
      curve: widget.curve,
    );
    setState(() => _isScrolling = false);
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = (_currentPage.round() == widget.pages.length - 1);
    bool isSkipBtn = (!_isSkipPressed && !isLastPage && widget.showSkipButton);

    final prevBtn = IntroButton(
      child: widget.prev,
      onPressed: _onPrev,
    );

    final skipBtn = IntroButton(
      child: widget.skip,
      onPressed: isSkipBtn ? _onSkip : null,
    );

    final nextBtn = IntroButton(
      child: widget.next,
      onPressed: widget.showNextButton && !_isScrolling
          ? () async {
              if (widget.onIntroPressedOverride != null) {
                final result = await widget.onIntroPressedOverride();
                if (result == true) {
                  _onNext();
                }
              } else {
                _onNext();
              }
            }
          : null,
    );

    final doneBtn = IntroButton(
      child: widget.done,
      onPressed: () async {
        if (widget.onIntroPressedOverride != null) {
          final result = await widget.onIntroPressedOverride();
          if (result == true) {
            widget.onDone();
          }
        } else {
          widget.onDone();
        }
      },
    );

    return Scaffold(
      backgroundColor: widget.globalBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: widget.freeze
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              children: widget.pages.map((p) => IntroPage(page: p)).toList(),
              onPageChanged: (index) {
                setState(() => _currentPage = index.toDouble());
                if (widget.onChange != null) {
                  widget.onChange(index);
                }
              },
            ),
          ),
          Row(
            children: [
              // Expanded(
              //   flex: widget.skipFlex,
              //   child:
              //       isSkipBtn ? skipBtn : Opacity(opacity: 0.0, child: skipBtn),
              // ),
              Expanded(
                flex: widget.prevFlex,
                child: prevBtn,
              ),
              Expanded(
                flex: widget.dotsFlex,
                child: Center(
                  child: widget.isProgress
                      ? DotsIndicator(
                          dotsCount: widget.pages.length,
                          position: _currentPage,
                          decorator: widget.dotsDecorator,
                        )
                      : const SizedBox(),
                ),
              ),
              Expanded(
                flex: widget.nextFlex,
                child: isLastPage
                    ? doneBtn
                    : widget.showNextButton
                        ? nextBtn
                        : Opacity(opacity: 0.0, child: nextBtn),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
