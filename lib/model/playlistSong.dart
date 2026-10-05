class PlaylistSong {
  final int playlistId;
  final int songId;

  PlaylistSong({
    required this.playlistId,
    required this.songId,
  });

  factory PlaylistSong.fromMap(Map<String, dynamic> map) {
    return PlaylistSong(
      playlistId: map['playlistId'] as int,
      songId: map['songId'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playlistId': playlistId,
      'songId': songId,
    };
  }
}