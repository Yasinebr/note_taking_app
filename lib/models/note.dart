class Note {
  int? id;
  String title;
  String content;
  DateTime createdAt;
  DateTime? reminderTime;
  String? location;
  String? weather;
  double? latitude;
  double? longitude;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.reminderTime,
    this.location,
    this.weather,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.millisecondsSinceEpoch,
      'reminder_time': reminderTime?.millisecondsSinceEpoch,
      'location': location,
      'weather': weather,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      reminderTime: map['reminder_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['reminder_time'])
          : null,
      location: map['location'],
      weather: map['weather'],
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}