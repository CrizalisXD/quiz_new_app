import 'package:flutter/material.dart';

/// Виджет-обёртка, объединяющий Hero-анимацию и анимацию нажатия (scale)
/// Используется для плавного превращения одного виджета в другой между экранами
class HeroScaleTap extends StatefulWidget {
  final Widget child;
  final String heroTag;
  final VoidCallback onTap;
  final Duration scaleDuration;
  final double scaleDownValue;
  final bool enableHero;

  const HeroScaleTap({
    super.key,
    required this.child,
    required this.heroTag,
    required this.onTap,
    this.scaleDuration = const Duration(milliseconds: 200),
    this.scaleDownValue = 0.92,
    this.enableHero = true,
  });

  @override
  State<HeroScaleTap> createState() => _HeroScaleTapState();
}

class _HeroScaleTapState extends State<HeroScaleTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.scaleDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDownValue)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    // onTap будет вызван автоматически через GestureDetector.onTap
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );

    child = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap, // Основное событие тапа
      behavior: HitTestBehavior.opaque,
      child: child,
    );

    if (widget.enableHero) {
      child = Hero(
        tag: widget.heroTag,
        flightShuttleBuilder: (context, animation, direction, fromContext, toContext) {
          return widget.child;
        },
        transitionOnUserGestures: true,
        child: child,
      );
    }

    return child;
  }
}

/// Виджет для создания плавного перехода между экранами
class ScreenTransitionWidget extends StatefulWidget {
  final Widget child;
  final bool enableAnimation;
  final Duration duration;
  final Curve curve;

  const ScreenTransitionWidget({
    super.key,
    required this.child,
    this.enableAnimation = true,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeInOut,
  });

  @override
  State<ScreenTransitionWidget> createState() => _ScreenTransitionWidgetState();
}

class _ScreenTransitionWidgetState extends State<ScreenTransitionWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.enableAnimation) {
      _controller = AnimationController(
        duration: widget.duration,
        vsync: this,
      );
      _opacityAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ));
      _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ));
      _controller.forward();
    }
  }

  @override
  void dispose() {
    if (widget.enableAnimation) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableAnimation) {
      return widget.child;
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Виджет для анимированного списка с последовательным появлением
class AnimatedListWidget extends StatefulWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration duration;
  final Curve curve;

  const AnimatedListWidget({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 150),
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOut,
  });

  @override
  State<AnimatedListWidget> createState() => _AnimatedListWidgetState();
}

class _AnimatedListWidgetState extends State<AnimatedListWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _opacityAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );
    
    _opacityAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: widget.curve),
      );
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: controller, curve: widget.curve),
      );
    }).toList();

    // Запускаем анимацию с задержкой
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.delay * i, () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, _) {
            return SlideTransition(
              position: _slideAnimations[index],
              child: FadeTransition(
                opacity: _opacityAnimations[index],
                child: child,
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

/// Виджет-обёртка только с анимацией нажатия (scale)
/// Используется для кнопок и интерактивных элементов без Hero-перехода
class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Duration scaleDuration;
  final double scaleDownValue;

  const ScaleTap({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDuration = const Duration(milliseconds: 200),
    this.scaleDownValue = 0.92,
  });

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.scaleDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDownValue)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    // onTap будет вызван автоматически через GestureDetector.onTap
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap, // Основное событие тапа
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Виджет для анимации появления с fade и slide
/// Используется для последовательного появления элементов списка
class FadeSlideTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset offset;
  final Curve curve;

  const FadeSlideTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.05),
    this.curve = Curves.easeOutQuart,
  });

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    _offsetAnimation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Вспомогательный виджет для одновременной анимации верхнего и нижнего виджетов
class TopBottomSlideTransition extends StatefulWidget {
  final Widget topChild;
  final Widget bottomChild;
  final Duration transitionDuration;
  final bool isForward;

  const TopBottomSlideTransition({
    super.key,
    required this.topChild,
    required this.bottomChild,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.isForward = true,
  });

  @override
  State<TopBottomSlideTransition> createState() => _TopBottomSlideTransitionState();
}

class _TopBottomSlideTransitionState extends State<TopBottomSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _topController;
  late AnimationController _bottomController;
  late Animation<Offset> _topSlideAnimation;
  late Animation<double> _topOpacityAnimation;
  late Animation<Offset> _bottomSlideAnimation;
  late Animation<double> _bottomOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _topController = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );

    _bottomController = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );

    _topSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.3),
    ).animate(CurvedAnimation(
      parent: _topController,
      curve: Curves.easeOutQuart,
    ));

    _topOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _topController,
      curve: const Interval(0.7, 1.0),
    ));

    _bottomSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _bottomController,
      curve: Curves.easeOutQuart,
    ));

    _bottomOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bottomController,
      curve: const Interval(0.0, 0.7),
    ));

    if (widget.isForward) {
      _startForwardAnimation();
    }
  }

  void _startForwardAnimation() {
    _topController.forward();
    _bottomController.forward();
  }

  @override
  void dispose() {
    _topController.dispose();
    _bottomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Верхний виджет (движется вверх)
        AnimatedBuilder(
          animation: _topController,
          builder: (context, _) {
            return SlideTransition(
              position: _topSlideAnimation,
              child: FadeTransition(
                opacity: _topOpacityAnimation,
                child: widget.topChild,
              ),
            );
          },
        ),
        
        // Нижние виджеты (появляются снизу)
        AnimatedBuilder(
          animation: _bottomController,
          builder: (context, _) {
            return SlideTransition(
              position: _bottomSlideAnimation,
              child: FadeTransition(
                opacity: _bottomOpacityAnimation,
                child: widget.bottomChild,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Виджет для анимации списка элементов с последовательным появлением/исчезновением
class AnimatedListTransition extends StatefulWidget {
  final List<Widget> children;
  final Duration duration;
  final Duration staggerDelay;
  final Offset slideOffset;
  final Curve curve;
  final bool reverseOnExit;

  const AnimatedListTransition({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 400),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.slideOffset = const Offset(0, 0.1),
    this.curve = Curves.easeOutQuart,
    this.reverseOnExit = false,
  });

  @override
  State<AnimatedListTransition> createState() => _AnimatedListTransitionState();
}

class _AnimatedListTransitionState extends State<AnimatedListTransition>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _opacityAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );

    _opacityAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: widget.curve,
        ),
      );
    }).toList();

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: widget.slideOffset,
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: widget.curve,
        ),
      );
    }).toList();

    // Запускаем анимацию появления
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, _) {
            return SlideTransition(
              position: _slideAnimations[index],
              child: FadeTransition(
                opacity: _opacityAnimations[index],
                child: child,
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

/// Виджет для управления переходом между экранами с анимацией
class ScreenTransitionManager extends StatefulWidget {
  final Widget topWidget;
  final List<Widget> bottomWidgets;
  final Duration transitionDuration;
  final bool isForward;

  const ScreenTransitionManager({
    super.key,
    required this.topWidget,
    required this.bottomWidgets,
    this.transitionDuration = const Duration(milliseconds: 600),
    this.isForward = true,
  });

  @override
  State<ScreenTransitionManager> createState() => _ScreenTransitionManagerState();
}

class _ScreenTransitionManagerState extends State<ScreenTransitionManager>
    with TickerProviderStateMixin {
  late AnimationController _topController;
  late AnimationController _bottomController;
  late Animation<Offset> _topSlideAnimation;
  late Animation<double> _topOpacityAnimation;
  late Animation<Offset> _bottomSlideAnimation;
  late Animation<double> _bottomOpacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _topController = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );
    
    _bottomController = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );

    // Анимация для верхнего виджета (движется вверх)
    _topSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.3),
    ).animate(CurvedAnimation(
      parent: _topController,
      curve: Curves.easeOutQuart,
    ));

    _topOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _topController,
      curve: const Interval(0.7, 1.0),
    ));

    // Анимация для нижних виджетов (появляются снизу)
    _bottomSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _bottomController,
      curve: Curves.easeOutQuart,
    ));

    _bottomOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bottomController,
      curve: const Interval(0.0, 0.7),
    ));

    // Запускаем анимацию
    if (widget.isForward) {
      _startForwardAnimation();
    }
  }

  void _startForwardAnimation() {
    _topController.forward().then((_) {
      if (mounted) {
        _bottomController.forward();
      }
    });
  }

  void _startReverseAnimation() {
    _bottomController.reverse().then((_) {
      if (mounted) {
        _topController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _topController.dispose();
    _bottomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Верхний виджет (движется вверх)
        AnimatedBuilder(
          animation: _topController,
          builder: (context, _) {
            return SlideTransition(
              position: _topSlideAnimation,
              child: FadeTransition(
                opacity: _topOpacityAnimation,
                child: widget.topWidget,
              ),
            );
          },
        ),
        
        // Нижние виджеты (появляются снизу)
        AnimatedBuilder(
          animation: _bottomController,
          builder: (context, _) {
            return SlideTransition(
              position: _bottomSlideAnimation,
              child: FadeTransition(
                opacity: _bottomOpacityAnimation,
                child: Column(
                  children: widget.bottomWidgets,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}