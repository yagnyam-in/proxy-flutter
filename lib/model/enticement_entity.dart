class EnticementEntity {
  final String enticementId;
  final bool active;
  final String title;
  final String description;
  final int priority;

  EnticementEntity({
    this.enticementId,
    this.title,
    this.description,
    this.priority,
    this.active,
  });

  EnticementEntity copy({
    String enticementId,
    bool active,
    String title,
    String description,
    int priority,
  }) {
    return EnticementEntity(
      enticementId: enticementId ?? this.enticementId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      active: active ?? this.active,
    );
  }
}
