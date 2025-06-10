import 'package:flutter/material.dart';

enum ResponseType {
  text,
  steps,
  image,
}

class FirstAidResponse {
  final String id;
  final String title;
  final String content;
  final ResponseType type;
  final List<String>? steps;
  final String? imageUrl;
  final bool isEmergency;
  final String? source;

  const FirstAidResponse({
    required this.id,
    required this.title,
    required this.content,
    this.type = ResponseType.text,
    this.steps,
    this.imageUrl,
    this.isEmergency = false,
    this.source,
  });

  factory FirstAidResponse.fromJson(Map<String, dynamic> json) {
    return FirstAidResponse(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: ResponseType.values.firstWhere(
        (e) => e.toString() == 'ResponseType.${json['type']}',
        orElse: () => ResponseType.text,
      ),
      steps: (json['steps'] as List<dynamic>?)?.cast<String>(),
      imageUrl: json['imageUrl'] as String?,
      isEmergency: json['isEmergency'] as bool? ?? false,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.toString().split('.').last,
      'steps': steps,
      'imageUrl': imageUrl,
      'isEmergency': isEmergency,
      'source': source,
    };
  }

  FirstAidResponse copyWith({
    String? id,
    String? title,
    String? content,
    ResponseType? type,
    List<String>? steps,
    String? imageUrl,
    bool? isEmergency,
    String? source,
  }) {
    return FirstAidResponse(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      steps: steps ?? this.steps,
      imageUrl: imageUrl ?? this.imageUrl,
      isEmergency: isEmergency ?? this.isEmergency,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FirstAidResponse &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.type == type &&
        other.isEmergency == isEmergency &&
        other.source == source &&
        _listEquals(other.steps, steps) &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      content,
      type,
      Object.hashAll(steps ?? []),
      imageUrl,
      isEmergency,
      source,
    );
  }

  Color getTypeColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (type) {
      case ResponseType.steps:
        return theme.colorScheme.primary;
      case ResponseType.image:
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.surface;
    }
  }

  IconData getTypeIcon() {
    switch (type) {
      case ResponseType.steps:
        return Icons.format_list_numbered;
      case ResponseType.image:
        return Icons.image;
      default:
        return Icons.chat;
    }
  }
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
} 