import 'dart:typed_data';

Future<void> saveDownloadedBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  throw UnsupportedError('Saving downloads is only implemented for Flutter Web in this scaffold.');
}
