import 'package:flutter/material.dart';

class CustomPadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const CustomPadding({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(50),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: child,
    );
  }
}