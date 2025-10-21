class Project {
  final int id;
  final String name;
  final String regex;
  final String urlTemplate;

  Project({
    required this.id,
    required this.name,
    required this.regex,
    required this.urlTemplate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'regex': regex,
    'urlTemplate': urlTemplate,
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'],
    name: json['name'],
    regex: json['regex'],
    urlTemplate: json['urlTemplate'],
  );

  Project copyWith({
    int? id,
    String? name,
    String? regex,
    String? urlTemplate,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      regex: regex ?? this.regex,
      urlTemplate: urlTemplate ?? this.urlTemplate,
    );
  }

  @override
  String toString() {
    return 'Project(id: $id, name: $name, regex: $regex, urlTemplate: $urlTemplate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Project &&
        other.id == id &&
        other.name == name &&
        other.regex == regex &&
        other.urlTemplate == urlTemplate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        regex.hashCode ^
        urlTemplate.hashCode;
  }
}
