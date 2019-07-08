import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:proxy_flutter/config/app_configuration.dart';

class _AppConfigurationContainer extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final Widget child;

  _AppConfigurationContainer({
    @required this.child,
    @required this.appConfiguration,
  });

  static AppConfiguration configuration(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(_InheritedStateContainer) as _InheritedStateContainer)
        .data
        .appConfiguration;
  }

  @override
  _AppConfigurationContainerState createState() => new _AppConfigurationContainerState(appConfiguration);
}

class _AppConfigurationContainerState extends State<_AppConfigurationContainer> {
  final AppConfiguration appConfiguration;

  _AppConfigurationContainerState(this.appConfiguration);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print("Re-drawing AppStateContainer");
    return new _InheritedStateContainer(
      data: this,
      child: widget.child,
    );
  }
}

class AppConfigurationContainer extends InheritedWidget {
  final AppConfiguration appConfiguration;

  AppConfigurationContainer({
    Key key,
    @required this.appConfiguration,
    @required Widget child,
  }) : super (key:key, child: child);


  @override
  bool updateShouldNotify(AppConfigurationContainer oldContainer) {
    final latest = this.appConfiguration;
    final old = oldContainer.appConfiguration;
    final notify = latest != old;
    print('AppConfigurationContainer.updateShouldNotify => $notify');
    return notify;
  }
}

class _InheritedStateContainer extends InheritedWidget {
  final _AppConfigurationContainerState data;

  _InheritedStateContainer({
    Key key,
    @required this.data,
    @required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_InheritedStateContainer oldContainer) {
    final latest = data.appConfiguration;
    final old = oldContainer.data.appConfiguration;
    final notify = latest != old;
    print('_InheritedStateContainer.updateShouldNotify => $notify');
    return notify;
  }
}
