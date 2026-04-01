class WearDay {
  final String id;
  final String itemId;
  final DateTime date;
  final double? latitude;
  final double? longitude;

  const WearDay({
    required this.id,
    required this.itemId,
    required this.date,
    this.latitude,
    this.longitude,
  });

  bool get hasLocation => latitude != null && longitude != null;

  WearDay copyWith({DateTime? date}) => WearDay(
        id: id,
        itemId: itemId,
        date: date ?? this.date,
        latitude: latitude,
        longitude: longitude,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'item_id': itemId,
        'date': date.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
      };

  factory WearDay.fromMap(Map<String, dynamic> map) => WearDay(
        id: map['id'] as String,
        itemId: map['item_id'] as String,
        date: DateTime.parse(map['date'] as String),
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => toMap();
  factory WearDay.fromJson(Map<String, dynamic> json) => WearDay.fromMap(json);
}
