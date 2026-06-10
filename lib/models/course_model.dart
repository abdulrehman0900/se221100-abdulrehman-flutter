
class Course {
  final int id;
  final String title;
  final String description;
  final int userId;

  Course({
    required this.id,
    required this.title,
    required this.description,
    this.userId = 1,
  });

  /// Builds a [Course] from a JSONPlaceholder post object.
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      title: (json['title'] ?? '').toString(),
      description: (json['body'] ?? '').toString(),
      userId: json['userId'] is int ? json['userId'] : 1,
    );
  }

  /// Maps back to the shape JSONPlaceholder expects for POST/PUT requests.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': description,
      'userId': userId,
    };
  }

  /// Returns a copy with the given fields replaced.
  Course copyWith({int? id, String? title, String? description, int? userId}) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
    );
  }
}
