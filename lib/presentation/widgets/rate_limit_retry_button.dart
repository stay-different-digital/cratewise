import 'dart:async';

import 'package:flutter/material.dart';

/// Default countdown applied after a Discogs 429 (rate-limited) response.
const kRateLimitCountdownSeconds = 60;

/// A [FilledButton] that, when [isRateLimited] is true, shows a disabled
/// "Retry in X s" countdown and becomes active once the window elapses.
///
/// For non-rate-limited errors the button is immediately active.
class RateLimitRetryButton extends StatefulWidget {
  const RateLimitRetryButton({
    super.key,
    required this.onRetry,
    this.isRateLimited = false,
    this.countdownSeconds = kRateLimitCountdownSeconds,
  });

  final VoidCallback onRetry;
  final bool isRateLimited;

  /// Seconds to count down before enabling the button.
  /// Exposed for tests that need a short countdown.
  final int countdownSeconds;

  @override
  State<RateLimitRetryButton> createState() => _RateLimitRetryButtonState();
}

class _RateLimitRetryButtonState extends State<RateLimitRetryButton> {
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isRateLimited) _startCountdown();
  }

  @override
  void didUpdateWidget(RateLimitRetryButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isRateLimited && widget.isRateLimited) {
      _startCountdown();
    } else if (oldWidget.isRateLimited && !widget.isRateLimited) {
      _cancelTimer();
      setState(() => _secondsLeft = 0);
    }
  }

  void _startCountdown() {
    _cancelTimer();
    setState(() => _secondsLeft = widget.countdownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _secondsLeft = 0;
          _cancelTimer();
        }
      });
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _secondsLeft == 0;
    return FilledButton(
      onPressed: active ? widget.onRetry : null,
      child: Text(active ? 'Retry' : 'Retry in $_secondsLeft s'),
    );
  }
}
