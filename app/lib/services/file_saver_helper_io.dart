import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> saveExportedFile({
  required String filename,
  required Uint8List bytes,
  required String ext,
  required MimeType mimeType,
}) async {
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(dir.path, 'MeetingTracker_Exports'));
    if (!exportDir.existsSync()) {
      exportDir.createSync(recursive: true);
    }
    final filePath = p.join(exportDir.path, filename);
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    debugPrint('[FILE EXPORT SUCCESS] Saved to $filePath');
    return filePath;
  } else {
    await FileSaver.instance.saveFile(
      name: filename,
      bytes: bytes,
      ext: ext,
      mimeType: mimeType,
    );
    return filename;
  }
}
