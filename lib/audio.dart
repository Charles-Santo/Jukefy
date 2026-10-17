import 'package:audioplayers/audioplayers.dart';

/// Único AudioPlayer do app. Tocar uma música nova substitui a anterior,
/// então nunca há duas músicas tocando ao mesmo tempo.
final AudioPlayer appAudio = AudioPlayer();
