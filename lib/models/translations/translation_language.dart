import 'package:kiosk_flutter/models/base.dart';

// in the model id converted to an id
class TranslationLanguage extends Base<TranslationLanguage> {
  @override
  final String id;
  final String languageName;
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  const TranslationLanguage({
    required this.id,
    required this.languageName,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  TranslationLanguage copyWith({
    String? id,
    String? languageName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TranslationLanguage(
      id: id ?? this.id,
      languageName: languageName ?? this.languageName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TranslationLanguage.fromJson(Map<String, dynamic> json) {
    return TranslationLanguage(
      id: json['id'] as String,
      languageName: json['language_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language_name': languageName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TranslationLanguage && other.id == id && other.languageName == languageName && other.createdAt == createdAt && other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ languageName.hashCode ^ createdAt.hashCode ^ updatedAt.hashCode;
  }
}