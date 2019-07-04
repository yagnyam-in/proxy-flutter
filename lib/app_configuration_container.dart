import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:proxy_flutter/config/app_configuration.dart';

class AppConfigurationContainer extends StatefulWidget {
  final AppConfiguration appConfiguration;
  final Widget child;

  AppConfigurationContainer({
    @required this.child,
    @required this.appConfiguration,
  });

  static AppConfiguration configuration(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(_InheritedStateContainer) as _InheritedStateContainer).data.appConfiguration;
  }

  @override
  _AppConfigurationContainerState createState() => new _AppConfigurationContainerState(appConfiguration);
}

class _AppConfigurationContainerState extends State<AppConfigurationContainer> {
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

class _InheritedStateContainer extends InheritedWidget {
  final _AppConfigurationContainerState data;

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
