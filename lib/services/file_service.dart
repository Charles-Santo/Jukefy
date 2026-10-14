import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileService {
  static bool isRemote(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  /// Copia o arquivo para a pasta de documentos do app e devolve o novo caminho.
  ///
  /// O file_picker costuma devolver uma cópia temporária (cache) que o sistema
  /// pode apagar. Guardando uma cópia própria, o caminho salvo no banco
  /// continua válido. Caminhos vazios, URLs e arquivos que já estão na pasta
  /// do app são devolvidos sem alteração.
  static Future<String> persist(String sourcePath, String folder) async {
    if (sourcePath.isEmpty || isRemote(sourcePath)) return sourcePath;

    final source = File(sourcePath);
    if (!await source.exists()) return sourcePath;

    final docs = await getApplicationDocumentsDirectory();
    if (p.isWithin(docs.path, sourcePath)) return sourcePath;

    final dir = Directory(p.join(docs.path, folder));
    if (!await dir.exists()) await dir.create(recursive: true);

    final target = p.join(
      dir.path,
      '${DateTime.now().microsecondsSinceEpoch}_${p.basename(sourcePath)}',
    );
    await source.copy(target);
    return target;
  }
}
