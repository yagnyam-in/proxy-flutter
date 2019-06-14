import 'package:flutter/material.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/widgets/basic_types.dart';

abstract class LoadingSupportState<T extends StatefulWidget> extends State<T> {
  bool loading = false;

  Future<T> invoke<T>(FutureCallback<T> callback, {bool silent = false}) async {
    if (!silent) {
      setState(() {
        loading = true;
      });
    }
    try {
      return await callback();
    } catch (e) {
      print("Error invoking: $e");
      return null;
    } finally {
      if (!silent) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Widget asyncBuilder<T>(
    BuildContext context,
    AsyncSnapshot<T> snapshot, {
    Widget loadingWidget,
    String errorMessage,
    Widget errorWidget,
    String emptyMessage,
    Widget emptyWidget,
    @required Widget readyWidget,
  }) {
    if (LOADING_STATES.contains(snapshot.connectionState)) {
      return loadingWidget ??
          Center(
            child: CircularProgressIndicator(),
          );
    } else if (snapshot.hasError) {
      return errorWidget ??
          Center(
            child: Text(
              errorMessage ?? ProxyLocalizations.of(context).somethingWentWrong,
              style: TextStyle(color: Theme.of(context).errorColor),
            ),
          );
    } else if (!snapshot.hasData) {
      return emptyWidget ??
          Center(
            child: Text(
              emptyMessage ?? ProxyLocalizations.of(context).noDataAvailable,
            ),
          );
    } else {
      return readyWidget;
    }
  }

  static const Set<ConnectionState> LOADING_STATES = {
    ConnectionState.none,
    ConnectionState.waiting,
    ConnectionState.active,
  };
}
