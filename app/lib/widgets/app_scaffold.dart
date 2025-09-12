import 'package:flutter/material.dart';
import 'package:app/widgets/menu.dart';
import 'package:app/app/theme.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final String title;

  const AppScaffold({
    super.key,
    required this.child,
    this.title = 'API 6',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.accentColor),
      ),
      drawer: const AppMenu(),
      body: child,
    );
  }
}