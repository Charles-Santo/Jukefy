class Song {
  final int? id;
  final String title;
  final String audioPath;
  final String imagePath;
  final int idArtist; // Alterado para int
  final int duration;
  bool isFavorite;

  Song({
    this.id,
    required this.title,
    required this.idArtist,
    required this.duration,
    this.isFavorite = false,
    required this.audioPath,
    required this.imagePath,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as int?,
      title: map['title'] as String,
      audioPath: map['audioPath'] as String,
      imagePath: map['imagePath'] as String,
      idArtist: map['idArtist'] as int,
      duration: map['durationInSeconds'] as int,
      isFavorite: map['isFavorite'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'audioPath': audioPath,
      'imagePath': imagePath,
      'idArtist': idArtist,
      'durationInSeconds': duration,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }
}