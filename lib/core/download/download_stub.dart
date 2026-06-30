import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

const _noViewerMessage =
    'Fichier enregistré, mais aucune application compatible trouvée';

Future<void> saveDownloadedBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  if (bytes.isEmpty) {
    throw const FileSystemException('Échec du téléchargement');
  }

  final directory = await _downloadDirectory();
  final safeFileName = _safeFileName(fileName);
  final file = await _uniqueFile(directory, safeFileName);
  await file.writeAsBytes(bytes, flush: true);

  final result = await OpenFilex.open(file.path, type: mimeType);
  if (result.type != ResultType.done) {
    throw const FileSystemException(_noViewerMessage);
  }
}

Future<Directory> _downloadDirectory() async {
  final downloads = await getDownloadsDirectory();
  final base = downloads ?? await getApplicationDocumentsDirectory();
  final directory = Directory('${base.path}${Platform.pathSeparator}LegalGo');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  return directory;
}

Future<File> _uniqueFile(Directory directory, String fileName) async {
  final separator = Platform.pathSeparator;
  final dotIndex = fileName.lastIndexOf('.');
  final stem = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
  final extension = dotIndex > 0 ? fileName.substring(dotIndex) : '';

  var candidate = File('${directory.path}$separator$fileName');
  var index = 1;
  while (await candidate.exists()) {
    candidate = File('${directory.path}$separator$stem ($index)$extension');
    index++;
  }
  return candidate;
}

String _safeFileName(String value) {
  final trimmed = value.trim();
  final candidate = trimmed.isEmpty ? 'document' : trimmed;
  final safe = candidate
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return safe.isEmpty ? 'document' : safe;
}
