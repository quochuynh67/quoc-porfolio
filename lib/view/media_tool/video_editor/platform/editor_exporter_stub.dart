import 'dart:typed_data';

import '../application/export_plan.dart';
import 'editor_exporter.dart';

EditorExporter createExporter() => _StubExporter();

class _StubExporter implements EditorExporter {
  @override
  bool get supported => false;

  @override
  Future<ExportOutcome> run(
          ExportRequest request, ExportProgress onProgress) async =>
      const ExportOutcome.failure(
          'Video export needs the web build (FFmpeg WebAssembly).', []);

  @override
  bool download(Uint8List bytes, String fileName) => false;
}
