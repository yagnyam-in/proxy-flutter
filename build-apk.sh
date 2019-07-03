#!/bin/sh

flutter pub get
flutter clean
#flutter build appbundle
flutter build appbundle --target-platform android-arm,android-arm64
# flutter build apk --target-platform android-arm,android-arm64 --split-per-abi

