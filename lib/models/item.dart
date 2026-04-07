enum ItemCategory {
  jeans,
  hemd,
  jacke,
  hose,
  sonstiges;

  static ItemCategory? fromString(String? value) {
    if (value == null) return null;
    try {
      return ItemCategory.values.byName(value);
    } catch (_) {
      return null;
    }
  }
}

class Item {
  final String id;
  final String brand;
  final String model;
  final String size;
  final DateTime firstWearDate;
  final String? notes;
  final String? photoPath;
  final String? nfcTagId;
  final DateTime createdAt;
  final int baseWearCount;
  final ItemCategory? category;

  const Item({
    required this.id,
    required this.brand,
    required this.model,
    required this.size,
    required this.firstWearDate,
    this.notes,
    this.photoPath,
    this.nfcTagId,
    required this.createdAt,
    this.baseWearCount = 0,
    this.category,
  });

  Item copyWith({
    String? brand,
    String? model,
    String? size,
    DateTime? firstWearDate,
    String? notes,
    int? baseWearCount,
    Object? photoPath = _sentinel,
    Object? nfcTagId = _sentinel,
    Object? category = _sentinel,
  }) {
    return Item(
      id: id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      size: size ?? this.size,
      firstWearDate: firstWearDate ?? this.firstWearDate,
      notes: notes ?? this.notes,
      photoPath: photoPath == _sentinel ? this.photoPath : photoPath as String?,
      nfcTagId: nfcTagId == _sentinel ? this.nfcTagId : nfcTagId as String?,
      createdAt: createdAt,
      baseWearCount: baseWearCount ?? this.baseWearCount,
      category: category == _sentinel ? this.category : category as ItemCategory?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'brand': brand,
        'model': model,
        'size': size,
        'first_wear_date': firstWearDate.toIso8601String(),
        'notes': notes,
        'photo_path': photoPath,
        'nfc_tag_id': nfcTagId,
        'created_at': createdAt.toIso8601String(),
        'base_wear_count': baseWearCount,
        'category': category?.name,
      };

  factory Item.fromMap(Map<String, dynamic> map) => Item(
        id: map['id'] as String,
        brand: map['brand'] as String,
        model: map['model'] as String,
        size: map['size'] as String,
        firstWearDate: DateTime.parse(map['first_wear_date'] as String),
        notes: map['notes'] as String?,
        photoPath: map['photo_path'] as String?,
        nfcTagId: map['nfc_tag_id'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        baseWearCount: (map['base_wear_count'] as int?) ?? 0,
        category: ItemCategory.fromString(map['category'] as String?),
      );

  Map<String, dynamic> toJson() => toMap();
  factory Item.fromJson(Map<String, dynamic> json) => Item.fromMap(json);
}

const _sentinel = Object();
