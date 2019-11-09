import 'package:flutter/material.dart';

class RoundButton extends StatelessWidget {
  final Color color;

  final Color splashColor;

  final Icon child;

  final double radius;

  final String label;

  final VoidCallback onTap;

  double get diameter => radius * 2;

  const RoundButton({
    Key key,
    @required this.color,
    @required this.splashColor,
    @required this.child,
    double radius,
    @required this.label,
    @required this.onTap,
  }) : this.radius = radius ?? 24, super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ClipOval(
          child: Material(
            color: color,
            child: InkWell(
              splashColor: splashColor,
              child: SizedBox(width: diameter, height: diameter, child: child),
              onTap: onTap,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(label),
        ),
      ],
    );
  }
}
