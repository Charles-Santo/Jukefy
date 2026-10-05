class Playlist {
  final int? id;
  final String title;
  final String? description;
  final String? imagePath;
  final int idUser;

  Playlist({
    this.id,
    required this.title,
    this.description,
    this.imagePath,
    required this.idUser,
  });

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      imagePath: map['imagePath'] as String?,
      idUser: map['idUser'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'idUser': idUser,
    };
  }
}