class WearDay {
  final String id;
  final String itemId;
  final DateTime date;

  const WearDay({
    required this.id,
    required this.itemId,
    required this.date,
  });

  WearDay copyWith({DateTime? date}) => WearDay(
        id: id,
        itemId: itemId,
        date: date ?? this.date,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'item_id': itemId,
        'date': date.toIso8601String(),
      };

  factory WearDay.fromMap(Map<String, dynamic> map) => WearDay(
        id: map['id'] as String,
        itemId: map['item_id'] as String,
        date: DateTime.parse(map['date'] as String),
      );

  Map<String, dynamic> toJson() => toMap();
  factory WearDay.fromJson(Map<String, dynamic> json) => WearDay.fromMap(json);
}
