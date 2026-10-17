class PlaylistSong {
  final int playlistId;
  final int songId;
  final int position;

  PlaylistSong({
    required this.playlistId,
    required this.songId,
    this.position = 0,
  });

  factory PlaylistSong.fromMap(Map<String, dynamic> map) {
    return PlaylistSong(
      playlistId: map['playlistId'] as int,
      songId: map['songId'] as int,
      position: map['position'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playlistId': playlistId,
      'songId': songId,
      'position': position,
    };
  }
}
