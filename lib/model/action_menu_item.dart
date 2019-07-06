import 'package:flutter/material.dart';

class ActionMenuItem {
  ActionMenuItem({
    @required this.title,
    @required this.action,
    @required this.icon,
  });

  final String action;
  final String title;
  final IconData icon;
}
