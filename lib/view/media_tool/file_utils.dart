import 'dart:convert';
import 'dart:html';

import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';

import 'ffmpeg_manager.dart';

class FileUtils {
  static List<int> writeTextFile(String text, {String fileName = 'input.txt'}) {
    // prepare
    final bytes = utf8.encode(text);
    final blob = Blob([bytes]);
    final url = Url.createObjectUrlFromBlob(blob);
    final anchor = document.createElement('a') as AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    document.body?.children.add(anchor);

    // download
    anchor.click();

    // cleanup
    document.body?.children.remove(anchor);
    Url.revokeObjectUrl(url);

    return bytes;
  }

  static bool downloadBytesInWeb(
    List<int>? bytes,
    String outputFileName, {
    String mimeType = 'application/octet-stream',
  }) {
    if (bytes == null || bytes.isEmpty) {
      print('Output file is null or empty, cannot download.');
      return false;
    }

    final blob = Blob([bytes], mimeType);
    final url = Url.createObjectUrlFromBlob(blob);
    final anchor = document.createElement('a') as AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = outputFileName;

    document.body?.children.add(anchor);
    anchor.click();
    document.body?.children.remove(anchor);
    Url.revokeObjectUrl(url);
    return true;
  }

  static bool downloadVideoOutputInWeb(String outputFileName) {
    final outputVideo = FfmpegManager.instance.ffmpeg?.readFile(outputFileName);
    return downloadBytesInWeb(
      outputVideo,
      outputFileName,
      mimeType: 'video/mp4',
    );
  }
}
