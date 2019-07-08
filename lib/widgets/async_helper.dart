import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:proxy_flutter/localizations.dart';
import 'package:proxy_flutter/widgets/basic_types.dart';
import 'package:proxy_flutter/widgets/loading.dart';

typedef DataToWidgetBuilder<T> = Widget Function(BuildContext context, T data);

abstract class LoadingSupportState<T extends StatefulWidget> extends State<T> {
  bool get loading;
  set loading(bool value);


  Future<T> invoke<T>(
    FutureCallback<T> callback, {
    String name,
    bool silent = false,
    VoidCallback onError,
  }) async {
    if (!silent) {
      print("LoadingSupportState($name) Setting loading flag for");
      setState(() {
        loading = true;
      });
    }
    try {
      return await callback();
    } catch (e, t) {
      print("Error invoking ($name): $e => $t");
      if (onError != null) {
        onError();
      }
    } finally {
      if (!silent) {
        print("LoadingSupportState($name) Clearing loading flag");
        setState(() {
          loading = false;
        });
      }
    }
    return null;
  }

  StreamBuilder streamBuilder<T>({
    @required Stream<T> stream,
    T initialData,
    String name,
    Widget loadingWidget,
    String errorMessage,
    Widget errorWidget,
    String emptyMessage,
    Widget emptyWidget,
    @required DataToWidgetBuilder<T> builder,
  }) {
    return StreamBuilder<T>(
      initialData: initialData,
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
        return asyncBuilder(
          context,
          snapshot,
          builderName: "streamBuilder",
          name: name,
          loadingWidget: loadingWidget,
          errorMessage: errorMessage,
          errorWidget: errorWidget,
          emptyMessage: emptyMessage,
          emptyWidget: emptyWidget,
          builder: builder,
        );
      },
    );
  }

  FutureBuilder futureBuilder<T>({
    @required Future<T> future,
    T initialData,
    String name,
    Widget loadingWidget,
    String errorMessage,
    Widget errorWidget,
    String emptyMessage,
    Widget emptyWidget,
    @required DataToWidgetBuilder<T> builder,
  }) {
    return FutureBuilder<T>(
      future: future,
      initialData: initialData,
      builder: (BuildContext context, AsyncSnapshot<T> snapshot) {
        return asyncBuilder(
          context,
          snapshot,
          builderName: "futureBuilder",
          name: name,
          loadingWidget: loadingWidget,
          errorMessage: errorMessage,
          errorWidget: errorWidget,
          emptyMessage: emptyMessage,
          emptyWidget: emptyWidget,
          builder: builder,
        );
      },
    );
  }

  Widget asyncBuilder<T>(
    BuildContext context,
    AsyncSnapshot<T> snapshot, {
        @required String builderName,
    String name,
    Widget loadingWidget,
    String errorMessage,
    Widget errorWidget,
    String emptyMessage,
    Widget emptyWidget,
    @required DataToWidgetBuilder<T> builder,
  }) {
    if (LOADING_STATES.contains(snapshot.connectionState)) {
      print("$builderName($name) is still loading: ${snapshot.connectionState}");
      return loadingWidget ?? LoadingWidget();
    } else if (snapshot.hasError) {
      print("$builderName($name) has Error: ${snapshot.error}");
      return errorWidget ??
          Center(
            child: Text(
              errorMessage ?? ProxyLocalizations.of(context).somethingWentWrong,
              style: TextStyle(color: Theme.of(context).errorColor),
            ),
          );
    } else if (!snapshot.hasData) {
      print("$builderName($name) has no data");
      return emptyWidget ??
          Center(
            child: Text(
              emptyMessage ?? ProxyLocalizations.of(context).noDataAvailable,
            ),
          );
    } else {
      print("$builderName($name) is ready with data: ${snapshot.data}");
      return builder(context, snapshot.data);
    }
  }

  static const Set<ConnectionState> LOADING_STATES = {
    ConnectionState.waiting,
  };
}
