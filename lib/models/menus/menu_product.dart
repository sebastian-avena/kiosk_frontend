import 'package:kiosk_flutter/models/base.dart';

class MenuProduct extends Base<MenuProduct> {
  @override
  final String id;
  final String menuId;
  final String productId;
  @override
  final bool synced;
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  const MenuProduct({
    required this.id,
    required this.menuId,
    required this.productId,
    required this.synced,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  MenuProduct copyWith({
    String? id,
    String? menuId,
    String? productId,
    bool? synced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuProduct(
      id: id ?? this.id,
      menuId: menuId ?? this.menuId,
      productId: productId ?? this.productId,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MenuProduct.fromJson(Map<String, dynamic> json) {
    return MenuProduct(
      id: json['id'] as String,
      menuId: json['menu_id'] as String,
      productId: json['product_id'] as String,
      synced: json['synced'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menu_id': menuId,
      'product_id': productId,
      'synced': synced,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MenuProduct && other.id == id && other.menuId == menuId && other.productId == productId && other.synced == synced && other.createdAt == createdAt && other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ menuId.hashCode ^ productId.hashCode ^ synced.hashCode ^ createdAt.hashCode ^ updatedAt.hashCode;
  }
}
