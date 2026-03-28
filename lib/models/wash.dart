class Wash {
  final String id;
  final String itemId;
  final DateTime date;
  final int tempCelsius;
  final int? wearDaysAtWash;

  const Wash({
    required this.id,
    required this.itemId,
    required this.date,
    required this.tempCelsius,
    this.wearDaysAtWash,
  });

  Wash copyWith({
    DateTime? date,
    int? tempCelsius,
    Object? wearDaysAtWash = _sentinel,
  }) =>
      Wash(
        id: id,
        itemId: itemId,
        date: date ?? this.date,
        tempCelsius: tempCelsius ?? this.tempCelsius,
        wearDaysAtWash: wearDaysAtWash == _sentinel
            ? this.wearDaysAtWash
            : wearDaysAtWash as int?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'item_id': itemId,
        'date': date.toIso8601String(),
        'temp_celsius': tempCelsius,
        'wear_days_at_wash': wearDaysAtWash,
      };

  factory Wash.fromMap(Map<String, dynamic> map) => Wash(
        id: map['id'] as String,
        itemId: map['item_id'] as String,
        date: DateTime.parse(map['date'] as String),
        tempCelsius: map['temp_celsius'] as int,
        wearDaysAtWash: map['wear_days_at_wash'] as int?,
      );

  Map<String, dynamic> toJson() => toMap();
  factory Wash.fromJson(Map<String, dynamic> json) => Wash.fromMap(json);
}

const _sentinel = Object();
