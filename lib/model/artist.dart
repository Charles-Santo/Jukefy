class Artist {
  final int? id;
  final String name;
  final String artisticName;
  final String description;
  final String imagePath;

  Artist({
    this.id,
    required this.name,
    required this.artisticName,
    required this.description,
    required this.imagePath,
  });

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'] as int?,
      name: map['name'] as String,
      artisticName: map['artisticName'] as String,
      description: map['description'] as String? ?? '',
      imagePath: map['imagePath'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'artisticName': artisticName,
      'description': description,
      'imagePath': imagePath,
    };
  }
}