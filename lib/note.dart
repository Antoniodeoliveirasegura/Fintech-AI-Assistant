import 'dart:convert';

class Note {
  final String id;
  final String content;
  final DateTime createdAt;
  final String weatherDescription;
  final String weatherEmoji;
  final double temperature;

  const Note({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.weatherDescription,
    required this.weatherEmoji,
    required this.temperature,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'weatherDescription': weatherDescription,
        'weatherEmoji': weatherEmoji,
        'temperature': temperature,
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        weatherDescription: json['weatherDescription'] as String,
        weatherEmoji: json['weatherEmoji'] as String,
        temperature: (json['temperature'] as num).toDouble(),
      );

  static List<Note> listFromJson(String jsonString) {
    final list = json.decode(jsonString) as List;
    return list.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<Note> notes) =>
      json.encode(notes.map((e) => e.toJson()).toList());
}
