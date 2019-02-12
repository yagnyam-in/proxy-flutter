import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: const CircularProgressIndicator(),
    );
  }
}

class BusyChildWidget extends StatefulWidget {
  final Widget child;
  final Widget loadingWidget;

  const BusyChildWidget({Key key, @required this.child, @required Widget loadingWidget})
      : loadingWidget = loadingWidget ?? const LoadingWidget(),
        super(key: key);

  @override
  _BusyChildWidgetState createState() {
    return _BusyChildWidgetState();
  }
}

class _BusyChildWidgetState extends State<BusyChildWidget> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Opacity(
          opacity: 0,
          child: widget.loadingWidget,
        ),
        Opacity(
          opacity: 1,
          child: widget.child,
        )
      ],
    );
  }
}
