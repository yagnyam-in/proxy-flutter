import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:promo/banking/model/abstract_entity.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:quiver/strings.dart';

typedef FromJson<T extends AbstractEntity> = T Function(Map json);

abstract class AbstractStore<T extends AbstractEntity> {
  @protected
  final AppConfiguration appConfiguration;

  @protected
  FromJson<T> get fromJson;

  @protected
  CollectionReference get rootCollection;

  String get newInternalId => rootCollection.document().documentID;

  AbstractStore(this.appConfiguration);

  @protected
  List<T> querySnapshotToEntityList(QuerySnapshot querySnapshot) {
    if (querySnapshot.documents == null) {
      return [];
    }
    return querySnapshot.documents.map(documentSnapshotToEntity).where((e) => e != null).toList();
  }

  @protected
  T firstResult(QuerySnapshot querySnapshot, Query query) {
    final results = querySnapshotToEntityList(querySnapshot);
    if (results.isEmpty) {
      print("No results found for $query");
      return null;
    }
    if (results.length > 1) {
      print("More than 1 (${results.length}) results found for $query");
    }
    return results.first;
  }

  @protected
  T documentSnapshotToEntity(DocumentSnapshot snapshot) {
    if (snapshot == null || !snapshot.exists) {
      return null;
    }
    return fromJson(snapshot.data);
  }

  Future<T> fetchByInternalId(String internalId) async {
    final ref = rootCollection.document(internalId);
    return documentSnapshotToEntity(await ref.get());
  }

  Stream<T> subscribeByInternalId(String internalId) {
    final ref = rootCollection.document(internalId);
    return ref.snapshots().map(documentSnapshotToEntity);
  }

  @protected
  T withInternalId(T entity) {
    if (isBlank(entity.internalId)) {
      return entity.copyWithInternalId(newInternalId);
    }
    return entity;
  }

  Future<T> save(T entity, {Transaction transaction}) async {
    entity = withInternalId(entity);
    final ref = rootCollection.document(entity.internalId);
    if (transaction != null) {
      await transaction.set(ref, entity.toJson());
    } else {
      await ref.setData(entity.toJson());
    }
    return entity;
  }

  Future<void> delete(T entity, {Transaction transaction}) {
    if (isBlank(entity.internalId)) {
      print("Can't delete $entity as internalId is not set");
      return Future.value(null);
    }
    final ref = rootCollection.document(entity.internalId);
    if (transaction != null) {
      return transaction.delete(ref);
    } else {
      return rootCollection.document(entity.internalId).delete();
    }
  }

  Future<void> archive(T entity, {Transaction transaction}) {
    if (isBlank(entity.internalId)) {
      print("Can't archive $entity as internalId is not set");
      return Future.value(null);
    }
    final ref = rootCollection.document(entity.internalId);
    final data = {AbstractEntity.ACTIVE: false};
    if (transaction != null) {
      return transaction.set(ref, {...entity.toJson(), ...data});
    } else {
      return ref.setData(data, merge: true);
    }
  }
}
