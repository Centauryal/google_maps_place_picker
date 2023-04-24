import 'package:flutter/material.dart';

/// Allows Page or StateFullWidget to listen of status modal route animation.
/// to anticipate glitch animation when page transition.
mixin AutomaticTransitionMixin<T extends StatefulWidget> on State<T>
    implements TransitionFinished {
  ModalRoute? modalRoute;

  @mustCallSuper
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onCheck();
    });
  }

  void _onCheck() {
    modalRoute ??= ModalRoute.of(context);
    modalRoute?.animation?.addStatusListener(_statusListener);
  }

  void _statusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      onTransitionFinished();
      modalRoute?.animation?.removeStatusListener(_statusListener);
    }
  }
}

abstract class TransitionFinished {
  void onTransitionFinished();
}
