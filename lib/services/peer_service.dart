import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geo_firestore/geo_firestore.dart';
import 'package:location/location.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:proxy_core/core.dart';

class Peer {
  final ProxyId peerProxyId;
  final double distance;
  final int color;
  final String id;
  final String data;

  Peer({
    @required this.peerProxyId,
    @required this.distance,
    @required this.color,
    @required this.id,
    this.data,
  });

  @override
  String toString() {
    return "Peer(peerProxyId: $peerProxyId, distance: $distance, color: $color, id: $id)";
  }
}

class PeerLocation {
  final ProxyId proxyId;
  final GeoPoint location;
  final String geoHash;
  final int color;
  final String id;
  final DateTime lastUpdate;
  final String data;

  PeerLocation({
    @required this.proxyId,
    @required this.location,
    @required this.geoHash,
    @required this.color,
    @required this.id,
    @required this.lastUpdate,
    this.data,
  });

  factory PeerLocation.fromJson(Map json) {
    return PeerLocation(
      proxyId: ProxyId.fromJson(json['proxyId'] as Map),
      location: json['location'] as GeoPoint,
      geoHash: json['geoHash'] as String,
      color: json['color'] as int,
      id: json['id'] as String,
      data: json['data'] as String,
      lastUpdate: DateTime.fromMillisecondsSinceEpoch(json['lastUpdate'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'proxyId': proxyId.toJson(),
      'location': location,
      'geoHash': geoHash,
      'color': color,
      'id': id,
      'data': data ?? '',
      'lastUpdate': lastUpdate?.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() {
    return "PeerLocation(proxyId: ${proxyId.id}, "
        "location: (${location.latitude}, ${location.longitude}), "
        "color: $color, "
        "id: $id, "
        "lastUpdate: $lastUpdate)";
  }
}

// TODO: This is temporary and not secure at all.
class PeerService {
  static final List<int> colors = [
    Colors.red.value,
    Colors.orange.value,
    Colors.green.value,
    Colors.blue.value,
    Colors.purple.value
  ];
  static final Duration _locationFetchInterval = Duration(seconds: 5);
  static final double radius = 0.05;
  static final GeoPoint nullIsland = GeoPoint(0, 0);

  final AppConfiguration appConfiguration;
  final Location _locationFetcher = new Location();
  final int _color = colors[Random().nextInt(colors.length)];
  final String _id = Random().nextInt(colors.length).toString();

  DateTime _locationTimestamp = DateTime.now().subtract(_locationFetchInterval);

  String get ourId => appConfiguration.masterProxyId.id;
  CollectionReference get placesRef => Firestore.instance.collection('places');
  DocumentReference get ourLocationRef => placesRef.document(ourId);
  DateTime get tenSecondsAgo => DateTime.now().subtract(Duration(seconds: 30));
  DateTime get fiveSecondsAgo => DateTime.now().subtract(Duration(seconds: 15));

  PeerService(this.appConfiguration);

  Future<void> setup() async {
    try {
      // Permissions
      if (!(await _locationFetcher.hasPermission())) {
        await _locationFetcher.requestPermission();
      }
      await Future.wait([
        _locationFetcher.changeSettings(
          interval: _locationFetchInterval.inMilliseconds,
        ),
      ]);
    } catch (e) {
      print("Error setting up peer service");
    }
  }

  Stream<List<Peer>> peers({String data}) {
    return _locationFetcher.onLocationChanged().where((loc) {
      // iOS continuously sending location update. Only
      return _locationTimestamp.add(_locationFetchInterval).isBefore(DateTime.now());
    }).map((loc) async {
      _locationTimestamp = DateTime.now();
      final location = GeoPoint(loc.latitude, loc.longitude);
      final ourLocation = PeerLocation(
        proxyId: appConfiguration.masterProxyId,
        location: location,
        geoHash: GeoHash.encode(loc.latitude, loc.longitude),
        color: _color,
        id: _id,
        lastUpdate: _locationTimestamp,
        data: data,
      );
      print("Our location is $ourLocation at $_locationTimestamp");
      await ourLocationRef.setData(ourLocation.toJson());
      final peerLocations = (await GeoFirestore(placesRef).getAtLocation(location, radius))
          .where((s) => s.documentID != ourId)
          .map((s) => PeerLocation.fromJson(s.data))
          .where((l) => l.lastUpdate.isAfter(tenSecondsAgo))
          .toList();
      print("Found ${peerLocations.length} peers");
      final results = peerLocations.map((peerLocation) {
        return _peerFromLocation(
          ourLocation: ourLocation,
          peerLocation: peerLocation,
        );
      }).toList();
      results.sort((c1, c2) => c1.distance.compareTo(c2.distance));
      print("Returning $results");
      return results;
    }).asyncExpand((f) => f.asStream());
  }

  Peer _peerFromLocation({PeerLocation peerLocation, PeerLocation ourLocation}) {
    final distance = GeoUtils.distance(ourLocation.location, peerLocation.location);
    if (ourLocation.proxyId.id.compareTo(peerLocation.proxyId.id) < 0) {
      return Peer(peerProxyId: peerLocation.proxyId, distance: distance, color: _color, id: _id, data: peerLocation.data);
    } else {
      return Peer(peerProxyId: peerLocation.proxyId, distance: distance, color: peerLocation.color, id: peerLocation.id, data: peerLocation.data);
    }
  }
}
