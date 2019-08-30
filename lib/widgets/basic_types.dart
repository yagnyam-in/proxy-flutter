import 'dart:async';

typedef FutureCallback<T> = Future<T> Function();

typedef Producer<T> = T Function();

T nullIfError<T>(Producer<T> producer) {
  try {
    return producer();
  } catch (e) {
    print("Error while evaluting: $e");
    return null;
  }
}

