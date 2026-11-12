import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../res/constants.dart';
import '../ffmpeg_manager.dart';
import '../file_utils.dart';
import 'quotemaker_screen.dart';
import 'widget/media_ui.dart';
import 'vlogmaker_screen.dart';

class MediaToolHomeScreen extends StatefulWidget {
  const MediaToolHomeScreen({super.key});

  @override
  State<MediaToolHomeScreen> createState() => _MediaToolHomeScreenState();
}

class _MediaToolHomeScreenState extends State<MediaToolHomeScreen> {
  bool _isLoaded = false;
  bool _isProcessing = false;
  String _status = 'Loading engine';

  @override
  void initState() {
    super.initState();
    _loadEngine();
  }

  void _loadEngine() {
    if (mounted) setState(() => _status = 'Loading engine');
    FfmpegManager.instance.loadFFmpeg(() {
      if (!mounted) return;
      setState(() {
        _isLoaded = FfmpegManager.instance.isLoaded;
        _status = _isLoaded ? 'Ready' : 'Engine unavailable';
      });
    }, onFailed: (error) {
      if (!mounted) return;
      setState(() {
        _isLoaded = false;
        _status = 'Failed: $error';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _mediaTheme(Theme.of(context)),
      child: DefaultTabController(
      length: 3,
      child: ColoredBox(
        color: bgColor,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
                16,
                MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
                10,
              ),
              child: Wrap(
                spacing: 14,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.pinkAccent, Colors.blue],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width < 600
                        ? MediaQuery.sizeOf(context).width - 92
                        : 460,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Media Studio',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                        const Text(
                          'Convert, compose and export media in your browser',
                          style: TextStyle(color: bodyTextColor),
                        ),
                      ],
                    ),
                  ),
                  if (MediaQuery.sizeOf(context).width >= 600) _statusChip(),
                ],
              ),
            ),
            if (MediaQuery.sizeOf(context).width < 600)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _statusChip(),
                ),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(icon: Icon(Icons.bolt), text: 'Quick tools'),
                  Tab(icon: Icon(Icons.format_quote), text: 'Quote maker'),
                  Tab(icon: Icon(Icons.slideshow), text: 'Slideshow'),
                ],
              ),
            ),
            if (_isProcessing) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 4),
            Expanded(
              child: TabBarView(
                children: [
                  _buildQuickToolsGrid(),
                  QuoteMakerScreen(),
                  VlogMakerScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  /// Dark scheme for the whole studio so buttons, tabs, inputs and sliders
  /// keep readable contrast on the dark page background.
  ThemeData _mediaTheme(ThemeData base) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.cyan,
      brightness: Brightness.dark,
    ).copyWith(
      primary: Colors.cyanAccent,
      onPrimary: const Color(0xFF00212B),
      surface: mediaPanelColor,
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xFFB4B8C5),
      outline: const Color(0x66FFFFFF),
    );
    return base.copyWith(
      colorScheme: scheme,
      iconTheme: const IconThemeData(color: Colors.white70),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.cyanAccent,
        unselectedLabelColor: Color(0xFFB4B8C5),
        indicatorColor: Colors.cyanAccent,
        dividerColor: mediaPanelBorder,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0x66FFFFFF)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Color(0xFFB4B8C5)),
        hintStyle: TextStyle(color: Color(0xFF8B8FA0)),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0x66FFFFFF))),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFFE6E8EF),
        displayColor: Colors.white,
      ),
    );
  }

  Widget _statusChip() {
    final failed =
        _status.startsWith('Failed') || _status == 'Engine unavailable';
    final loading = _status == 'Loading engine';
    final color = failed
        ? Colors.redAccent
        : loading
            ? Colors.amber
            : _isProcessing
                ? Colors.cyanAccent
                : Colors.greenAccent;
    return ActionChip(
      tooltip: failed ? _status : null,
      backgroundColor: color.withOpacity(.14),
      side: BorderSide(color: color.withOpacity(.6)),
      shape: const StadiumBorder(),
      avatar: loading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(
              failed ? Icons.refresh : Icons.check_circle_outline,
              size: 16,
              color: color,
            ),
      label: Text(
        failed ? 'Retry engine' : _status,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      onPressed: failed ? _loadEngine : null,
    );
  }

  Widget _buildQuickToolsGrid() {
    final tools = [
      _MediaTool(Icons.image_outlined, 'First frame',
          'Extract a WebP cover from a video', _extractFirstFrame),
      _MediaTool(Icons.movie_filter_outlined, 'Animated preview',
          'Create a short WebP preview', _createPreview),
      _MediaTool(
          Icons.hd_outlined,
          'Portrait 720p',
          'Resize video to 720 × 1280',
          () => _resizeVideo('720x1280', '720P_output.mp4')),
      _MediaTool(
          Icons.sd_outlined,
          'Portrait 480p',
          'Resize video to 480 × 720',
          () => _resizeVideo('480x720', '480P_output.mp4')),
      _MediaTool(Icons.photo_outlined, 'HEIC to JPEG',
          'Convert an iPhone photo', _heicToJpeg),
      _MediaTool(Icons.video_file_outlined, 'MOV to MP4',
          'Remux an iPhone video', _movToMp4),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1000
          ? 3
          : constraints.maxWidth >= 600
              ? 2
              : 1;
      return GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: tools.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisExtent: columns == 1 ? 190 : 220,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          final tool = tools[index];
          return Card(
            color: mediaPanelColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: mediaPanelBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _isLoaded && !_isProcessing ? tool.action : null,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          Icon(tool.icon, color: Colors.cyanAccent, size: 26),
                    ),
                    const Spacer(),
                    Text(tool.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(tool.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFB4B8C5))),
                    const SizedBox(height: 8),
                    Text(
                      _isLoaded ? 'Choose file →' : 'Preparing engine…',
                      style: TextStyle(
                        color: _isLoaded ? Colors.cyanAccent : bodyTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Future<String?> _pickFile({List<String>? extensions}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: extensions == null ? FileType.video : FileType.custom,
        allowedExtensions: extensions,
        withData: true,
      );
      if (result == null) return null;
      final file = result.files.single;
      if (file.bytes == null || file.bytes!.isEmpty || file.extension == null) {
        throw StateError('The selected file could not be read.');
      }
      final name = 'input.${file.extension!.toLowerCase()}';
      FfmpegManager.instance.ffmpeg?.writeFile(name, file.bytes!);
      return name;
    } catch (error) {
      _showMessage('Could not open file: $error', isError: true);
      return null;
    }
  }

  Future<void> _process(Future<bool> Function() task) async {
    if (!_isLoaded || _isProcessing) return;
    setState(() {
      _isProcessing = true;
      _status = 'Processing';
    });
    var success = false;
    try {
      success = await task();
    } catch (error) {
      if (mounted) _showMessage('Processing failed: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _status = success ? 'Completed' : 'Ready';
        });
      }
    }
    if (mounted) {
      _showMessage(
          success
              ? 'Your file is ready and downloading.'
              : 'Could not process this file.',
          isError: !success);
    }
  }

  Future<void> _extractFirstFrame() async {
    final input = await _pickFile();
    if (input == null) return;
    await _process(() async {
      if (!await FfmpegManager.instance.runCommand([
        '-i',
        input,
        '-vf',
        "select='eq(n,0)'",
        '-vsync',
        '0',
        'frame1.webp'
      ])) return false;
      return FileUtils.downloadBytesInWeb(
        FfmpegManager.instance.ffmpeg?.readFile('frame1.webp'),
        'frame1.webp',
        mimeType: 'image/webp',
      );
    });
  }

  Future<void> _createPreview() async {
    final input = await _pickFile();
    if (input == null) return;
    await _process(() async {
      if (!await FfmpegManager.instance.runCommand([
        '-i',
        input,
        '-t',
        '5',
        '-ss',
        '2',
        '-s',
        '480x720',
        '-f',
        'webp',
        '-r',
        '5',
        'preview.webp'
      ])) return false;
      return FileUtils.downloadBytesInWeb(
        FfmpegManager.instance.ffmpeg?.readFile('preview.webp'),
        'preview.webp',
        mimeType: 'image/webp',
      );
    });
  }

  Future<void> _resizeVideo(String size, String output) async {
    final input = await _pickFile();
    if (input == null) return;
    await _process(() async {
      if (!await FfmpegManager.instance
          .runCommand(['-i', input, '-s', size, '-c:a', 'aac', output]))
        return false;
      return FileUtils.downloadBytesInWeb(
        FfmpegManager.instance.ffmpeg?.readFile(output),
        output,
        mimeType: 'video/mp4',
      );
    });
  }

  Future<void> _heicToJpeg() async {
    final input = await _pickFile(extensions: ['heic']);
    if (input == null) return;
    await _process(() async {
      if (!await FfmpegManager.instance.runCommand(['-i', input, 'output.jpg']))
        return false;
      return FileUtils.downloadBytesInWeb(
        FfmpegManager.instance.ffmpeg?.readFile('output.jpg'),
        'output.jpg',
        mimeType: 'image/jpeg',
      );
    });
  }

  Future<void> _movToMp4() async {
    final input = await _pickFile(extensions: ['mov']);
    if (input == null) return;
    await _process(() async {
      if (!await FfmpegManager.instance.runCommand(
          ['-i', input, '-c', 'copy', '-movflags', '+faststart', 'output.mp4']))
        return false;
      return FileUtils.downloadBytesInWeb(
        FfmpegManager.instance.ffmpeg?.readFile('output.mp4'),
        'output.mp4',
        mimeType: 'video/mp4',
      );
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
    ));
  }
}

class _MediaTool {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback action;

  const _MediaTool(this.icon, this.title, this.description, this.action);
}
