import 'dart:convert';
import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';

import '../app_const.dart';
import '../ffmpeg_manager.dart';
import '../file_utils.dart';

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

  /// Emit changes
  final mediaList = ValueNotifier<List<Media>>([]);
  final audioList = ValueNotifier<List<String>>([]);
  // final progress = ValueNotifier<ProgressParam?>(null);
  // final cmdStream = ValueNotifier<String>('');

  /// CMD
  List<String> cmd = [];
  List<String> clipInput = ['-f', 'concat', '-safe', '0', '-i', 'input.txt',];
  List<String> audioInput = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const Text('Tạo slide ảnh, có 1 nhạc nền',
              style: TextStyle(fontSize: 16,color: Colors.black)),
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
                  onPressed: () => _handleExport(ExportType.autoCrop),
                  child: const Text('Export as AutoCrop')),
              OutlinedButton(
                  onPressed: () => _handleExport(ExportType.ratio916),
                  child: const Text('Export as 9:16')),
              OutlinedButton(
                  onPressed: () => _handleExport(ExportType.ratio169),
                  child: const Text('Export as 16:9')),
              OutlinedButton(
                  onPressed: () => _handleExport(ExportType.ratio11),
                  child: const Text('Export as 1:1')),
            ],
          )
        ],
      ),
    );
  }

  Future<void> pickAudioFiles() async {
   try {
     filePickerResult = await FilePicker.platform.pickFiles(
         type: FileType.custom,
         allowedExtensions: ['mp3'],
         allowMultiple: false);

     if (filePickerResult != null) {
       List<String> picked = [];
       for (int i = 0; i < filePickerResult!.files.length; ++i) {
         final file = filePickerResult!.files.elementAt(i);
         FfmpegManager.instance.ffmpeg?.writeFile('audio$i.mp3', file.bytes!);
         picked.add(''
             '\n- name: ${file.name} '
             '\n- extension: ${file.extension} '
             '\n- bytes: ${file.bytes?.length}');

         audioInput.addAll(['-i', 'audio$i.mp3']);
       }
       audioList.value = picked;
     }
   } catch(e) {
      print('HAHA --- [pickAudioFiles]  --- Error: $e');
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
          allowMultiple: true);

      if (filePickerResult != null) {
        List<Media> picked = [];
        String input = '';
        for (int i = 0; i < filePickerResult!.files.length; ++i) {
          final file = filePickerResult!.files.elementAt(i);
          bool isVideo = Media.isVideoType(file.extension ?? '');
          picked.add(Media(isVideo, file.bytes!));
          FfmpegManager.instance.ffmpeg?.writeFile('input$i.${file.extension}', file.bytes!);
          if (isVideo) {
            input +=
            'file ${'input$i.${file.extension}'}\nduration ${AppConst.VIDEO_DEFAULT_DURATION}\n';
          } else {
            input +=
            'file ${'input$i.${file.extension}'}\nduration ${AppConst.IMAGE_DEFAULT_DURATION}\n';
          }
        }
        FfmpegManager.instance.ffmpeg?.writeFile('input.txt', Uint8List.fromList(utf8.encode(input)));
        mediaList.value = picked;
      }
    } catch (e) {
      print('HAHA --- [pickVideoImageFiles]  --- Error: $e');
      // Handle the error, e.g., show a dialog or a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video/image files: $e')),
      );
    }
  }

  Future<void> _handleExport(ExportType type) async {
    cmd.clear();
    cmd.insertAll(0, clipInput);
    cmd.insertAll(0, audioInput);
    if (type == ExportType.autoCrop) {
      cmd.addAll(
          ['-af','atrim=duration=20','-vf', 'scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:-1:-1:color=black','-c:v', 'libx264', 'output.mp4']);
    } else if(type == ExportType.ratio11){
      cmd.addAll(
          ['-af','atrim=duration=20','-vf', 'scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:-1:-1:color=black','-c:v', 'libx264', 'output.mp4']);
    }else if(type == ExportType.ratio916){
      cmd.addAll(
          ['-af','atrim=duration=20','-vf', 'scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:-1:-1:color=black','-c:v', 'libx264', 'output.mp4']);
    }else if(type == ExportType.ratio169){
      cmd.addAll(
          ['-af','atrim=duration=20', '-vf', 'scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1:color=black','-c:v', 'libx264', 'output.mp4']);
    }

    // cmdStream.value = cmd.toString();
    print('HAHA --- [_handleExport]  --- cmd [$cmd]');
    await FfmpegManager.instance.runCommand(cmd);
    final exportBytes = FfmpegManager.instance.ffmpeg?.readFile('output.mp4');
    print('HAHA --- [_handleExport]  --- exportBytes [${exportBytes?.length}]');
    if (exportBytes == null || exportBytes.isEmpty) {
      print('HAHA --- [_handleExport]  --- exportBytes is null or empty');
      return;
    }
    final outputFile = XFile.fromData(exportBytes);

    print('HAHA --- [_handleExport]  --- outputFile [$outputFile, ${outputFile.name}, ${outputFile.mimeType}]');
    if (exportBytes.isNotEmpty == true) {
      FileUtils.downloadVideoOutputInWeb('output.mp4');
      // progress.value = null;
    }
  }
}
