class StockMovement {
  final int? id;
  final int modelId;
  final int delta;
  final String? reason;
  final DateTime movedAt;

  const StockMovement({
    this.id,
    required this.modelId,
    required this.delta,
    this.reason,
    required this.movedAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'model_id': modelId,
        'delta': delta,
        'reason': reason,
        'moved_at': movedAt.toIso8601String(),
      };

  factory StockMovement.fromMap(Map<String, dynamic> map) => StockMovement(
        id: map['id'] as int?,
        modelId: map['model_id'] as int,
        delta: map['delta'] as int,
        reason: map['reason'] as String?,
        movedAt: DateTime.parse(map['moved_at'] as String),
      );
}
