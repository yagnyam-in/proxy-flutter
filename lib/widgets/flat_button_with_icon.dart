import 'package:flutter/material.dart';

enum _IconPosition { First, Last }

/// The type of of FlatButtons created with [FlatButton.icon].
///
/// This class only exists to give FlatButtons created with [FlatButton.icon]
/// a distinct class for the sake of [ButtonTheme]. It can not be instantiated.
class FlatButtonWithIcon extends FlatButton with MaterialButtonWithIconMixin {
  FlatButtonWithIcon({
    Key key,
    @required VoidCallback onPressed,
    ValueChanged<bool> onHighlightChanged,
    ButtonTextTheme textTheme,
    Color textColor,
    Color disabledTextColor,
    Color color,
    Color disabledColor,
    Color highlightColor,
    Color splashColor,
    Brightness colorBrightness,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    Clip clipBehavior,
    MaterialTapTargetSize materialTapTargetSize,
    @required Widget icon,
    @required Widget label,
    _IconPosition iconPosition = _IconPosition.First,
  })  : assert(icon != null),
        assert(label != null),
        super(
          key: key,
          onPressed: onPressed,
          onHighlightChanged: onHighlightChanged,
          textTheme: textTheme,
          textColor: textColor,
          disabledTextColor: disabledTextColor,
          color: color,
          disabledColor: disabledColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
          colorBrightness: colorBrightness,
          padding: padding,
          shape: shape,
          clipBehavior: clipBehavior,
          materialTapTargetSize: materialTapTargetSize,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: iconPosition == _IconPosition.First
                ? <Widget>[
                    label,
                    const SizedBox(width: 8.0),
                    icon,
                  ]
                : <Widget>[
                    icon,
                    const SizedBox(width: 8.0),
                    label,
                  ],
          ),
        );

  factory FlatButtonWithIcon.withSuffixIcon({
    Key key,
    @required VoidCallback onPressed,
    @required Widget icon,
    @required Widget label,
  }) =>
      FlatButtonWithIcon(
        key: key,
        onPressed: onPressed,
        icon: icon,
        label: label,
        iconPosition: _IconPosition.Last,
      );

  factory FlatButtonWithIcon.withPrefixIcon({
    Key key,
    @required VoidCallback onPressed,
    @required Widget icon,
    @required Widget label,
  }) =>
      FlatButtonWithIcon(
        key: key,
        onPressed: onPressed,
        icon: icon,
        label: label,
        iconPosition: _IconPosition.Last,
      );
}
