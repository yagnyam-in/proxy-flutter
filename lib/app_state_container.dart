import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:proxy_flutter/model/app_state.dart';
import 'package:proxy_flutter/widgets/loading.dart';

class AppStateContainer extends StatefulWidget {
  final AppState state;

  final Widget child;

  AppStateContainer({
    @required this.child,
    this.state,
  });

  static _AppStateContainerState of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(_InheritedStateContainer) as _InheritedStateContainer).data;
  }

  @override
  _AppStateContainerState createState() => new _AppStateContainerState();
}

class _AppStateContainerState extends State<AppStateContainer> {
  AppState state;

  @override
  void initState() {
    super.initState();
    if (widget.state != null) {
      state = widget.state;
    } else {
      state = AppState(isLoading: false);
    }
  }



  @override
  Widget build(BuildContext context) {
    print("Re-drawing AppStateContainer");
    return new _InheritedStateContainer(
      data: this,
      child: Stack(
        children: <Widget>[
          Opacity(
            opacity: 0,
            child: LoadingWidget(),
          ),
          Opacity(
            opacity: 1,
            child: widget.child,
          ),
        ],
      ),
    );
  }

}

class _InheritedStateContainer extends InheritedWidget {
  final _AppStateContainerState data;

  _InheritedStateContainer({
    Key key,
    @required this.data,
    @required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_InheritedStateContainer old) {
    print('_InheritedStateContainer.updateShouldNotify');
    return true;
  }
}
