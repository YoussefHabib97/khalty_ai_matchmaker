import 'dart:async';

import 'package:khalty_ai_matchmaker/core/l10n/l10n_extensions.dart';
import 'package:material_ui/material_ui.dart';

/// "Resend code in 0:42", turning into a "Resend code" link when allowed.
class ResendCodeButton extends StatefulWidget {
  const ResendCodeButton({
    super.key,
    required this.remaining,
    required this.onResend,
    this.enabled = true,
  });

  /// Time left before a new code may be requested (asked every second).
  final Duration Function() remaining;
  final VoidCallback onResend;
  final bool enabled;

  @override
  State<ResendCodeButton> createState() => _ResendCodeButtonState();
}

class _ResendCodeButtonState extends State<ResendCodeButton> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void didUpdateWidget(ResendCodeButton old) {
    super.didUpdateWidget(old);
    _startTicker(); // a new code may have been sent
  }

  /// Rebuilds every second while counting down; stops at zero so the screen
  /// can settle.
  void _startTicker() {
    if (_ticker?.isActive ?? false) return;
    if (widget.remaining() == Duration.zero) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
      if (widget.remaining() == Duration.zero) _ticker?.cancel();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final left = widget.remaining();
    if (left > Duration.zero) {
      final seconds = left.inSeconds % 60;
      final time = '${left.inMinutes}:${seconds.toString().padLeft(2, '0')}';
      return TextButton(onPressed: null, child: Text(l10n.resendIn(time)));
    }
    return TextButton(
      onPressed: widget.enabled ? widget.onResend : null,
      child: Text(l10n.resendCode),
    );
  }
}
