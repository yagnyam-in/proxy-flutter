
import 'package:flutter/material.dart';
import 'package:proxy_flutter/widgets/basic_types.dart';

abstract class LoadingSupportState<T extends StatefulWidget> extends State<T> {

  bool loading = false;

  Future<T> invoke<T>(FutureCallback<T> callback) async {
    setState(() {
      loading = true;
    });
    try {

      return await callback();
    } catch (e) {
      print("Error invoking: $e");
      return null;
      // throw e;
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

}

