import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';

Future<String> saveExportedFile({
  required String filename,
  required Uint8List bytes,
  required String ext,
  required MimeType mimeType,
}) async {
  await FileSaver.instance.saveFile(
    name: filename,
    bytes: bytes,
    ext: ext,
    mimeType: mimeType,
  );
  return filename;
}
