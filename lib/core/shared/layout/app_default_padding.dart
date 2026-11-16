import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:khalty_ai_matchmaker/core/constants/constants.dart';

class DefaultPadding extends StatelessWidget {
  final double horizontalOffset, verticalOffset;
  final Widget child;
  const DefaultPadding({
    super.key,
    this.verticalOffset = kPaddingVertical,
    this.horizontalOffset = kPaddingHorizontal,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalOffset.w,
        vertical: verticalOffset.h,
      ),
      child: child,
    );
  }
}
