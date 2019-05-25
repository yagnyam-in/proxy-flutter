import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import 'package:proxy_core/core.dart';

class ContactEntity {
  final int id;

  final String proxyUniverse;

  final ProxyId proxyId;

  final String phone;

  final String email;

  final String name;

  ContactEntity({
    this.id,
    @required this.proxyId,
    this.proxyUniverse,
    this.name,
    this.phone,
    this.email,
  });

  ContactEntity copy({
    String proxyUniverse,
    String phone,
    String email,
    String name,
  }) {
    return ContactEntity(
      id: this.id,
      proxyId: this.proxyId,
      proxyUniverse: proxyUniverse ?? this.proxyUniverse,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }
}
