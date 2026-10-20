import 'package:hive/hive.dart';

part 'daily_note.g.dart';

@HiveType(typeId: 3)
class DailyNote {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  DailyNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  DailyNote copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
  }) => DailyNote(
        id: id,
        title: title ?? this.title,
        content: content ?? this.content,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
