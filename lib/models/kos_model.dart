class KosModel {
  final String id;
  final String ownerId;
  final String name;
  final String area;
  final int price;
  final String type;
  final List<String> facilities;
  final int roomsAvailable;
  final String contactName;
  final String contactPhone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const KosModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.area,
    required this.price,
    required this.type,
    this.facilities = const [],
    required this.roomsAvailable,
    required this.contactName,
    required this.contactPhone,
    this.createdAt,
    this.updatedAt,
  });

  bool get isAvailable => roomsAvailable > 0;

  factory KosModel.fromJson(Map<String, dynamic> json) {
    return KosModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      area: json['area'] as String,
      price: (json['price'] as num).toInt(),
      type: json['type'] as String,
      facilities: (json['facilities'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      roomsAvailable: (json['rooms_available'] as num).toInt(),
      contactName: json['contact_name'] as String,
      contactPhone: json['contact_phone'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'area': area,
      'price': price,
      'type': type,
      'facilities': facilities,
      'rooms_available': roomsAvailable,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  KosModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? area,
    int? price,
    String? type,
    List<String>? facilities,
    int? roomsAvailable,
    String? contactName,
    String? contactPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KosModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      area: area ?? this.area,
      price: price ?? this.price,
      type: type ?? this.type,
      facilities: facilities ?? this.facilities,
      roomsAvailable: roomsAvailable ?? this.roomsAvailable,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KosModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerId == other.ownerId &&
          name == other.name &&
          area == other.area &&
          price == other.price &&
          type == other.type &&
          roomsAvailable == other.roomsAvailable &&
          contactName == other.contactName &&
          contactPhone == other.contactPhone;

  @override
  int get hashCode =>
      id.hashCode ^
      ownerId.hashCode ^
      name.hashCode ^
      area.hashCode ^
      price.hashCode ^
      type.hashCode ^
      roomsAvailable.hashCode ^
      contactName.hashCode ^
      contactPhone.hashCode;
}
