import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/db/firestore_utils.dart';
import 'package:promo/model/device_entity.dart';

class DeviceStore with ProxyUtils, FirestoreUtils {
  final AppConfiguration appConfiguration;
  final DocumentReference root;

  DeviceStore(this.appConfiguration) : root = FirestoreUtils.accountRootRef(appConfiguration.accountId);

  CollectionReference _devicesRef() {
    return root.collection('devices');
  }

  DocumentReference _ref(String deviceId) {
    return _devicesRef().document(deviceId);
  }

  Future<void> updateFcmToken({
    @required String deviceId,
    @required String fcmToken,
    @required List<ProxyKey> proxyKeys,
  }) async {
    final DeviceEntity existingDevice = await fetchDevice(deviceId);
    DeviceEntity updatedDevice;
    if (existingDevice != null && existingDevice.fcmToken == fcmToken) {
      final Set<ProxyId> existingProxies = existingDevice.proxyIdList;
      final List<ProxyId> newProxies = proxyKeys.map((key) => key.id).toList();
      updatedDevice = DeviceEntity(
        deviceId: deviceId,
        fcmToken: fcmToken,
        proxyIdList: {...existingProxies, ...newProxies},
      );
    } else {
      updatedDevice = DeviceEntity(
        deviceId: deviceId,
        fcmToken: fcmToken,
        proxyIdList: proxyKeys.map((k) => k.id).toSet(),
      );
    }
    return saveDevice(updatedDevice);
  }

  Future<void> saveDevice(DeviceEntity deviceEntity) async {
    _ref(deviceEntity.deviceId).setData(deviceEntity.toJson());
  }

  Future<Set<ProxyId>> fetchProxiesWithFcmToken({
    @required String deviceId,
    @required String fcmToken,
  }) async {
    print('fetchProxiesWithFcmToken(deviceId: $deviceId, fcmToken: $fcmToken)');
    final DeviceEntity existingDevice = await fetchDevice(deviceId);
    if (existingDevice != null) {
      return existingDevice.proxyIdList;
    }
    return {};
  }

  Future<DeviceEntity> fetchDevice(String deviceId) async {
    print('fetchDevice(deviceId: $deviceId)');
    final existingSnapshot = await _ref(deviceId).get();
    return _documentSnapshotToDevice(existingSnapshot);
  }

  DeviceEntity _documentSnapshotToDevice(DocumentSnapshot snapshot) {
    if (snapshot != null && snapshot.exists) {
      return DeviceEntity.fromJson(snapshot.data);
    } else {
      return null;
    }
  }
}
