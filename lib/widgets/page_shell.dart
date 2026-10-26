import 'package:flutter/material.dart';
import '../app/app_colors.dart';
import '../app/app_styles.dart';

class PageShell extends StatelessWidget {
  final String title;
  final Widget child;
  final bool useScroll;

  const PageShell({
    super.key,
    required this.title,
    required this.child,
    this.useScroll = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppStyles.pageHorizontal,
        AppStyles.pageTop,
        AppStyles.pageHorizontal,
        AppStyles.pageBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title, style: AppStyles.pageTitle),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: useScroll
            ? SingleChildScrollView(child: content)
            : content,
      ),
    );
  }
}