import 'package:meta/meta.dart';

class EnticementEntity {
  final String enticementId;
  final bool active;
  final String title;
  final String description;
  final int priority;

  EnticementEntity({
    @required this.enticementId,
    @required this.title,
    @required this.description,
    int priority,
    bool active = true,
  })  : this.active = active,
        this.priority = priority;
}
