import 'dart:html' as html;
import 'dart:js' as js;

import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view/media_tool/screen/screen.dart';

import '../ffmpeg_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoaded = false;
  String? selectedFile;
  String? conversionStatus;

  FilePickerResult? filePickerResult;

  @override
  void initState() {
    isLoaded = FfmpegManager.instance.isLoaded;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    FfmpegManager.instance.loadFFmpeg(() {
      setState(() {
        isLoaded = true;
        conversionStatus = 'Ready';
      });
    }, onFailed: (e) {
      conversionStatus = 'FFmpeg load failed - $e';
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 8),
                Text('Conversion Status : $conversionStatus'),
                const SizedBox(height: 8),
                ValueListenableBuilder(
                  valueListenable: FfmpegManager.instance.progress,
                  builder: (context, value, child) {
                    return value == null
                        ? const SizedBox.shrink()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Exporting ${(value * 100).ceil()}%'),
                              const SizedBox(width: 6),
                              const CircularProgressIndicator(),
                            ],
                          );
                  },
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder(
                  valueListenable: FfmpegManager.instance.statistics,
                  builder: (context, value, child) {
                    return value == null
                        ? const SizedBox.shrink()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(value),
                              const SizedBox(width: 6),
                              const CircularProgressIndicator(),
                            ],
                          );
                  },
                ),
              ],
            ),
          ),
          SliverList.list(children: [
            OutlinedButton(
              onPressed: extractFirstFrame,
              child: const Text(
                'Extract First Frame',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: createPreviewVideo,
              child: const Text(
                'Create Preview Image',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: create720PQualityVideo,
              child: const Text(
                'Video 720P Quality',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),

            OutlinedButton(
              onPressed: create480PQualityVideo,
              child: const Text(
                'Video 480P Quality',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),

            OutlinedButton(
              onPressed: heicToJpeg,
              child: const Text(
                '[IOS] HEIC to jpeg',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),

            OutlinedButton(
              onPressed: movToMp4,
              child: const Text(
                '[IOS] MOV to MP4',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: Container(
                  height: 1000,
                  color: Colors.grey.shade200,
                  child: const QuoteMakerScreen(),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1000,
                  color: Colors.grey.shade50,
                  child: const VlogMakerScreen(),
                ),
              ),
            ],)
          ])
        ],
      ),
    );
  }

  Future<void> pickFile({List<String>? allowExt}) async {
    if (allowExt != null && allowExt.isNotEmpty) {
      filePickerResult = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: allowExt);
    } else {
      filePickerResult =
          await FilePicker.platform.pickFiles(type: FileType.video);
    }

    if (filePickerResult != null &&
        filePickerResult!.files.single.bytes != null) {
      /// Writes File to memory
      FfmpegManager.instance.ffmpeg?.writeFile(
          'input.${filePickerResult!.files.single.extension}',
          filePickerResult!.files.single.bytes!);

      setState(() {
        selectedFile = 'input.${filePickerResult!.files.single.extension}';
      });
    }
  }

  /// Extracts First Frame from video
  Future<void> extractFirstFrame() async {
    await pickFile();
    await FfmpegManager.instance.ffmpeg?.run([
      '-i',
      '$selectedFile',
      '-vf',
      "select='eq(n,0)'",
      '-vsync',
      '0',
      'frame1.webp'
    ]);
    final data = FfmpegManager.instance.ffmpeg?.readFile('frame1.webp');
    js.context.callMethod('webSaveAs', [
      html.Blob([data]),
      'frame1.webp'
    ]);
  }

  /// Creates Preview Image of Video
  Future<void> createPreviewVideo() async {
    await pickFile();
    await FfmpegManager.instance.ffmpeg?.run([
      '-i',
      'input.mp4',
      '-t',
      '5.0',
      '-ss',
      '2.0',
      '-s',
      '480x720',
      '-f',
      'webp',
      '-r',
      '5',
      'previewWebp.webp'
    ]);
    final previewWebpData =
        FfmpegManager.instance.ffmpeg?.readFile('previewWebp.webp');
    js.context.callMethod('webSaveAs', [
      html.Blob([previewWebpData]),
      'previewWebp.webp'
    ]);
  }

  Future<void> create720PQualityVideo() async {
    await pickFile();
    setState(() {
      conversionStatus = 'Started';
    });
    await FfmpegManager.instance.ffmpeg?.run([
      '-i',
      'input.mp4',
      '-s',
      '720x1280',
      '-c:a',
      'copy',
      '720P_output.mp4'
    ]);
    setState(() {
      conversionStatus = 'Saving';
    });
    final hqVideo = FfmpegManager.instance.ffmpeg?.readFile('720P_output.mp4');
    setState(() {
      conversionStatus = 'Downloading';
    });
    js.context.callMethod('webSaveAs', [
      html.Blob([hqVideo]),
      '720P_output.mp4'
    ]);
    setState(() {
      conversionStatus = 'Completed';
    });
  }

  Future<void> create480PQualityVideo() async {
    await pickFile();
    setState(() {
      conversionStatus = 'Started';
    });
    await FfmpegManager.instance.ffmpeg?.run([
      '-i',
      'input.mp4',
      '-s',
      '480x720',
      '-c:a',
      'copy',
      '480P_output.mp4'
    ]);
    setState(() {
      conversionStatus = 'Saving';
    });
    final hqVideo = FfmpegManager.instance.ffmpeg?.readFile('480P_output.mp4');
    setState(() {
      conversionStatus = 'Downloading';
    });
    js.context.callMethod('webSaveAs', [
      html.Blob([hqVideo]),
      '480P_output.mp4'
    ]);
    setState(() {
      conversionStatus = 'Completed';
    });
  }

  void navigateToVlogMakerScreen() {
    Navigator.pushNamed(context, '/vlogMaker');
  }

  void navigateToQuoteMakerScreen() {
    Navigator.pushNamed(context, '/quoteMaker');
  }

  Future<void> heicToJpeg() async {
    await pickFile(allowExt: ['heic']);
    setState(() {
      conversionStatus = 'Started - HEIC to jpeg/png';
    });
    await FfmpegManager.instance.ffmpeg
        ?.run(['-i', '$selectedFile', 'output.jpg']);
    setState(() {
      conversionStatus = 'Saving';
    });
    final hqVideo = FfmpegManager.instance.ffmpeg?.readFile('output.jpg');
    if (hqVideo?.isEmpty == true) {
      setState(() {
        conversionStatus = 'Failed';
      });
    }
    setState(() {
      conversionStatus = 'Downloading';
    });
    js.context.callMethod('webSaveAs', [
      html.Blob([hqVideo]),
      'output.jpg'
    ]);
    setState(() {
      conversionStatus = 'Completed';
    });
  }

  Future<void> movToMp4() async {
    await pickFile(allowExt: ['mov']);
    setState(() {
      conversionStatus = 'Started - MOV to MP4';
    });
    await FfmpegManager.instance.ffmpeg?.run([
      '-i',
      '$selectedFile',
      '-c',
      'copy',
      '-movflags',
      '+faststart',
      'output.mp4'
    ]);
    setState(() {
      conversionStatus = 'Saving';
    });
    final hqVideo = FfmpegManager.instance.ffmpeg?.readFile('output.mp4');
    if (hqVideo?.isEmpty == true) {
      setState(() {
        conversionStatus = 'Failed';
      });
    }
    setState(() {
      conversionStatus = 'Downloading';
    });
    js.context.callMethod('webSaveAs', [
      html.Blob([hqVideo]),
      'output.mp4'
    ]);
    setState(() {
      conversionStatus = 'Completed';
    });
  }
}
