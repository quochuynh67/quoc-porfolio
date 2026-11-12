import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';

import '../app_const.dart';
import '../ffmpeg_manager.dart';
import '../file_utils.dart';
import 'widget/media_ui.dart';

enum ExportType { ratio916, ratio169, ratio11, autoCrop }

class Media {
  bool isVideo;
  Uint8List bytes;

  Media(this.isVideo, this.bytes);

  static bool isVideoType(String ext) {
    return ext.contains('mp4');
  }
}

class VlogMakerScreen extends StatefulWidget {
  const VlogMakerScreen({Key? key}) : super(key: key);

  @override
  State<VlogMakerScreen> createState() => _VlogMakerScreenState();
}

class _VlogMakerScreenState extends State<VlogMakerScreen> {
  FilePickerResult? filePickerResult;
  bool _isExporting = false;

  /// Emit changes
  final mediaList = ValueNotifier<List<Media>>([]);
  final audioList = ValueNotifier<List<String>>([]);
  // final progress = ValueNotifier<ProgressParam?>(null);
  // final cmdStream = ValueNotifier<String>('');

  /// CMD
  List<String> cmd = [];
  List<String> clipInput = [
    '-f',
    'concat',
    '-safe',
    '0',
    '-i',
    'input.txt',
  ];
  List<String> audioInput = [];

  @override
  void dispose() {
    mediaList.dispose();
    audioList.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return ListView(
      padding: EdgeInsets.all(compact ? 16 : 24),
      children: [
        const Text('Slideshow maker',
            style: TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text(
            'Combine photos with one background track and export a video.',
            style: TextStyle(color: const Color(0xFFB4B8C5))),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: pickVideoImageFiles,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add photos'),
            ),
            OutlinedButton.icon(
              onPressed: pickAudioFiles,
              icon: const Icon(Icons.audio_file_outlined),
              label: const Text('Add background music'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ValueListenableBuilder<List<Media>>(
          valueListenable: mediaList,
          builder: (context, data, _) => _SectionCard(
            title: 'Photos',
            subtitle:
                data.isEmpty ? 'No photos selected' : '${data.length} selected',
            child: data.isEmpty
                ? const _EmptyState(
                    icon: Icons.photo_library_outlined,
                    label: 'Add photos to preview your slideshow')
                : SizedBox(
                    height: compact ? 180 : 240,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: data[index].isVideo
                              ? const ColoredBox(
                                  color: Colors.black26,
                                  child:
                                      Center(child: Icon(Icons.movie_outlined)))
                              : Image.memory(data[index].bytes,
                                  fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<List<String>>(
          valueListenable: audioList,
          builder: (context, data, _) => _SectionCard(
            title: 'Soundtrack',
            subtitle: data.isEmpty ? 'No audio selected' : 'Ready to export',
            child: data.isEmpty
                ? const _EmptyState(
                    icon: Icons.music_note_outlined,
                    label: 'Choose one MP3 background track')
                : ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.music_note)),
                    title: Text(data.first,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Export format',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _exportButton('Auto crop', ExportType.autoCrop),
            _exportButton('Portrait 9:16', ExportType.ratio916),
            _exportButton('Landscape 16:9', ExportType.ratio169),
            _exportButton('Square 1:1', ExportType.ratio11),
          ],
        ),
        if (_isExporting) ...[
          const SizedBox(height: 18),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Text('Exporting your slideshow…',
              style: TextStyle(color: const Color(0xFFB4B8C5))),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _exportButton(String label, ExportType type) {
    return OutlinedButton.icon(
      onPressed: _isExporting ? null : () => _handleExport(type),
      icon: const Icon(Icons.download_outlined),
      label: Text(label),
    );
  }

/*
      child: Column(
        children: [
          const Text('Tạo slide ảnh, có 1 nhạc nền',
              style: TextStyle(fontSize: 16, color: Colors.black)),
          Row(
            spacing: 12,
            children: [
              /// Select video/image Button
              ///
              OutlinedButton(
                  onPressed: pickVideoImageFiles,
                  child: const Text('Select image')),

              /// Select audio Button
              ///
              OutlinedButton(
                  onPressed: pickAudioFiles,
                  child: const Text('Select background music')),
            ],
          ),

          /// Export button
          ///
          // Column(
          //   crossAxisAlignment: CrossAxisAlignment.end,
          //   children: [
          //     ValueListenableBuilder(
          //         valueListenable: cmdStream,
          //         builder: (context, data, __) {
          //           if (data.isEmpty) return const SizedBox();
          //           return Text('cmd: $data');
          //         }),
          //     ValueListenableBuilder(
          //         valueListenable: progress,
          //         builder: (context, data, __) {
          //           if (data == null) return const SizedBox();
          //           return Row(
          //             mainAxisAlignment: MainAxisAlignment.end,
          //             children: [
          //               const SizedBox(
          //                   width: 16,
          //                   height: 16,
          //                   child: CircularProgressIndicator()),
          //               const SizedBox(width: 12),
          //               Text(
          //                   'Rendering ${(data.ratio * 300).ceil()}% - ${data.time}'),
          //             ],
          //           );
          //         })
          //   ],
          // ),

          /// Clips list
          ///
          SizedBox(
            height: 300,
            child: ValueListenableBuilder(
              builder: (context, data, __) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                      itemCount: data.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, index) {
                        final item = data.elementAt(index);
                        return Container(
                          color: Colors.grey,
                          padding: const EdgeInsets.all(16),
                          child: (item.isVideo)
                              ? const Center(child: Text('Video'))
                              : Image.memory(item.bytes, fit: BoxFit.cover),
                        );
                      }),
                );
              },
              valueListenable: mediaList,
            ),
          ),

          /// Audio  list
          ///
          SizedBox(
            height: 100,
            child: ValueListenableBuilder(
              builder: (context, data, __) {
                return ListView.builder(
                    itemCount: data.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, index) {
                      final item = data.elementAt(index);
                      return Container(
                        width: MediaQuery.sizeOf(context).width,
                        color: Colors.grey,
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          children: [
                            const Positioned(
                              top: 8,
                              left: 8,
                              child: Icon(Icons.music_note),
                            ),
                            Text(item),
                          ],
                        ),
                      );
                    });
              },
              valueListenable: audioList,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton(
                  onPressed: _isExporting
                      ? null
                      : () => _handleExport(ExportType.autoCrop),
                  child: const Text('Export as AutoCrop')),
              OutlinedButton(
                  onPressed: _isExporting
                      ? null
                      : () => _handleExport(ExportType.ratio916),
                  child: const Text('Export as 9:16')),
              OutlinedButton(
                  onPressed: _isExporting
                      ? null
                      : () => _handleExport(ExportType.ratio169),
                  child: const Text('Export as 16:9')),
              OutlinedButton(
                  onPressed: _isExporting
                      ? null
                      : () => _handleExport(ExportType.ratio11),
                  child: const Text('Export as 1:1')),
            ],
          )
        ],
      ),
    );
  }*/

  Future<void> pickAudioFiles() async {
    try {
      filePickerResult = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['mp3'],
          allowMultiple: false,
          withData: true);

      if (filePickerResult != null) {
        audioInput.clear();
        List<String> picked = [];
        for (int i = 0; i < filePickerResult!.files.length; ++i) {
          final file = filePickerResult!.files.elementAt(i);
          FfmpegManager.instance.ffmpeg?.writeFile('audio$i.mp3', file.bytes!);
          if (file.bytes == null) continue;
          picked.add(file.name);

          audioInput.addAll(['-i', 'audio$i.mp3']);
        }
        audioList.value = picked;
      }
    } catch (e) {
      // Handle the error, e.g., show a dialog or a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking audio files: $e')),
      );
    }
  }

  Future<void> pickVideoImageFiles() async {
    try {
      filePickerResult = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['png', 'jpg', 'jpeg'],
          allowMultiple: true,
          withData: true);

      if (filePickerResult != null) {
        List<Media> picked = [];
        String input = '';
        for (int i = 0; i < filePickerResult!.files.length; ++i) {
          final file = filePickerResult!.files.elementAt(i);
          if (file.bytes == null) continue;
          bool isVideo = Media.isVideoType(file.extension ?? '');
          picked.add(Media(isVideo, file.bytes!));
          FfmpegManager.instance.ffmpeg
              ?.writeFile('input$i.${file.extension}', file.bytes!);
          if (isVideo) {
            input +=
                'file ${'input$i.${file.extension}'}\nduration ${AppConst.VIDEO_DEFAULT_DURATION}\n';
          } else {
            input +=
                'file ${'input$i.${file.extension}'}\nduration ${AppConst.IMAGE_DEFAULT_DURATION}\n';
          }
        }
        FfmpegManager.instance.ffmpeg
            ?.writeFile('input.txt', Uint8List.fromList(utf8.encode(input)));
        mediaList.value = picked;
      }
    } catch (e) {
      // Handle the error, e.g., show a dialog or a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video/image files: $e')),
      );
    }
  }

  Future<void> _handleExport(ExportType type) async {
    if (!FfmpegManager.instance.isLoaded) {
      _showMessage('Media engine is not ready.', isError: true);
      return;
    }
    if (mediaList.value.isEmpty) {
      _showMessage('Select at least one image first.', isError: true);
      return;
    }
    if (audioList.value.isEmpty) {
      _showMessage('Select background music first.', isError: true);
      return;
    }
    setState(() => _isExporting = true);
    cmd.clear();
    cmd.addAll(clipInput);
    cmd.addAll(audioInput);
    if (type == ExportType.autoCrop) {
      cmd.addAll([
        '-af',
        'atrim=duration=20',
        '-vf',
        'scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:-1:-1:color=black',
        '-c:v',
        'libx264',
        'output.mp4'
      ]);
    } else if (type == ExportType.ratio11) {
      cmd.addAll([
        '-af',
        'atrim=duration=20',
        '-vf',
        'scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:-1:-1:color=black',
        '-c:v',
        'libx264',
        'output.mp4'
      ]);
    } else if (type == ExportType.ratio916) {
      cmd.addAll([
        '-af',
        'atrim=duration=20',
        '-vf',
        'scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:-1:-1:color=black',
        '-c:v',
        'libx264',
        'output.mp4'
      ]);
    } else if (type == ExportType.ratio169) {
      cmd.addAll([
        '-af',
        'atrim=duration=20',
        '-vf',
        'scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1:color=black',
        '-c:v',
        'libx264',
        'output.mp4'
      ]);
    }

    // cmdStream.value = cmd.toString();
    final success = await FfmpegManager.instance.runCommand(cmd);
    if (!mounted) return;
    if (!success) {
      setState(() => _isExporting = false);
      _showMessage('Could not export the slideshow.', isError: true);
      return;
    }
    final exportBytes = FfmpegManager.instance.ffmpeg?.readFile('output.mp4');
    if (exportBytes == null || exportBytes.isEmpty) {
      setState(() => _isExporting = false);
      _showMessage('The exported video is empty.', isError: true);
      return;
    }
    FileUtils.downloadVideoOutputInWeb('output.mp4');
    setState(() => _isExporting = false);
    _showMessage('Slideshow exported successfully.');
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message), backgroundColor: isError ? Colors.red : null),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mediaPanelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: mediaPanelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(color: const Color(0xFFB4B8C5))),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Icon(icon, color: Colors.cyanAccent, size: 34),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: const Color(0xFFB4B8C5))),
          ],
        ),
      ),
    );
  }
}
