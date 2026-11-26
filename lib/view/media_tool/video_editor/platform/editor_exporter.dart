import 'dart:typed_data';

import '../application/export_plan.dart';
import 'editor_exporter_stub.dart'
    if (dart.library.js_interop) 'editor_exporter_web.dart' as impl;

class ExportOutcome {
  const ExportOutcome.success(this.bytes, this.warnings)
      : error = null,
        log = const [];
  const ExportOutcome.failure(this.error, this.log, [this.warnings = const []])
      : bytes = null;

  final Uint8List? bytes;
  final String? error;
  final List<String> log;
  final List<String> warnings;
  bool get ok => bytes != null;
}

typedef ExportProgress = void Function(String label, double fraction);
typedef ExportLog = void Function(String line);

/// Renders a project with FFmpeg (WebAssembly in the browser).
abstract class EditorExporter {
  factory EditorExporter() => impl.createExporter();

  bool get supported;

  Future<ExportOutcome> run(
    ExportRequest request,
    ExportProgress onProgress, {
    ExportLog? onLog,
  });

  /// Aborts the running render (the FFmpeg core is restarted).
  void cancel();

  /// Saves [bytes] as a file download. Returns false when unsupported.
  bool download(Uint8List bytes, String fileName);
}
