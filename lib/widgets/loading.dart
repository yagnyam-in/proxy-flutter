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

class BusyChildWidget extends StatelessWidget {
  final Widget child;
  final Widget loadingWidget;
  final bool loading;

  const BusyChildWidget({
    Key key,
    @required this.child,
    @required this.loading,
    Widget loadingWidget,
  })  : loadingWidget = loadingWidget ?? const LoadingWidget(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Opacity(
          opacity: 1,
          child: AbsorbPointer(
            absorbing: loading,
            child: child,
          ),
        ),
        Opacity(
          opacity: loading ? 1.0 : 0,
          child: loadingWidget,
        ),
      ],
    );
  }
}
