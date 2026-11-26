import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../res/constants.dart';
import '../ffmpeg_manager.dart';
import '../file_utils.dart';
import '../video_editor/presentation/video_editor_studio_screen.dart';
import 'widget/media_ui.dart';

class MediaToolHomeScreen extends StatefulWidget {
  const MediaToolHomeScreen({super.key});

  @override
  State<MediaToolHomeScreen> createState() => _MediaToolHomeScreenState();
}

class _MediaToolHomeScreenState extends State<MediaToolHomeScreen> {
  bool _isLoaded = false;
  bool _isProcessing = false;
  String _status = 'Loading engine';
  String _selectedCategory = 'All';

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
          length: 2,
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
                        child:
                            const Icon(Icons.auto_awesome, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width < 600
                            ? MediaQuery.sizeOf(context).width - 92
                            : 460,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quốc Media Tools',
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
                      if (MediaQuery.sizeOf(context).width >= 600)
                        _statusChip(),
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
                      Tab(
                          icon: Icon(Icons.video_camera_back_rounded),
                          text: 'Studio'),
                    ],
                  ),
                ),
                if (_isProcessing)
                  ValueListenableBuilder<String?>(
                    valueListenable: FfmpegManager.instance.progress,
                    builder: (context, progress, _) => Column(
                      children: [
                        const LinearProgressIndicator(minHeight: 2),
                        if (progress != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(progress,
                                style: const TextStyle(
                                    color: Colors.cyanAccent, fontSize: 11)),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildQuickToolsGrid(),
                      const VideoEditorStudioScreen(),
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
      _MediaTool(
          Icons.image_outlined,
          'First frame',
          'Extract a sharp WebP cover from a video',
          'Image',
          _extractFirstFrame),
      _MediaTool(Icons.movie_filter_outlined, 'Animated preview',
          'Create a lightweight 5-second WebP', 'Social', _createPreview),
      _MediaTool(
          Icons.hd_outlined,
          'Portrait 720p',
          'Prepare a vertical Story or Reel',
          'Social',
          () => _resizeVideo('720x1280', '720P_output.mp4')),
      _MediaTool(Icons.crop_square_rounded, 'Square post',
          'Fit video inside a 1080 × 1080 canvas', 'Social', _squareVideo),
      _MediaTool(Icons.crop_16_9_rounded, 'Landscape 720p',
          'Fit video inside a 16:9 canvas', 'Video', _landscapeVideo),
      _MediaTool(
          Icons.content_cut_rounded,
          'Quick trim',
          'Keep the first 15 seconds without quality loss',
          'Video',
          _trimVideo),
      _MediaTool(Icons.compress_rounded, 'Compress video',
          'Smaller 720p MP4 for sharing', 'Video', _compressVideo),
      _MediaTool(
          Icons.volume_off_rounded,
          'Remove audio',
          'Create a silent copy without re-encoding video',
          'Audio',
          _muteVideo),
      _MediaTool(Icons.audio_file_rounded, 'Extract audio',
          'Save the soundtrack as high-quality M4A', 'Audio', _extractAudio),
      _MediaTool(Icons.graphic_eq_rounded, 'Normalize voice',
          'Balance loudness for clearer speech', 'Audio', _normalizeAudio),
      _MediaTool(Icons.gif_box_rounded, 'Video to GIF',
          'Create a shareable 6-second GIF', 'Social', _videoToGif),
      _MediaTool(Icons.rotate_right_rounded, 'Rotate video',
          'Rotate 90° clockwise and preserve audio', 'Video', _rotateVideo),
      _MediaTool(
          Icons.blur_on_rounded,
          'Reel blur background',
          'Vertical 9:16 with a cinematic blurred backdrop',
          'Social',
          _reelBlur),
      _MediaTool(
          Icons.fast_forward_rounded,
          'Speed up 2×',
          'Double video speed while keeping voice pitch',
          'Effects',
          _speedUpVideo),
      _MediaTool(
          Icons.slow_motion_video_rounded,
          'Slow motion 0.5×',
          'Half-speed video with synchronized audio',
          'Effects',
          _slowMotionVideo),
      _MediaTool(
          Icons.replay_rounded,
          'Reverse clip',
          'Play a short clip and its audio backwards',
          'Effects',
          _reverseVideo),
      _MediaTool(Icons.flip_rounded, 'Mirror video',
          'Flip horizontally for selfie footage', 'Effects', _mirrorVideo),
      _MediaTool(Icons.filter_b_and_w_rounded, 'Black & white',
          'Create a clean monochrome version', 'Effects', _monochromeVideo),
      _MediaTool(Icons.light_mode_outlined, 'Quick enhance',
          'Lift exposure, contrast and saturation', 'Effects', _enhanceVideo),
      _MediaTool(Icons.volume_up_rounded, 'Boost volume',
          'Increase quiet audio by 50%', 'Audio', _boostVolume),
      _MediaTool(Icons.record_voice_over_rounded, 'Voice compressor',
          'Reduce loudness jumps for clearer speech', 'Audio', _compressVoice),
      _MediaTool(Icons.multiline_chart_rounded, 'Audio fade in',
          'Smoothly introduce audio over 2 seconds', 'Audio', _audioFadeIn),
      _MediaTool(Icons.language_rounded, 'Export WebM',
          'Create a web-friendly VP9 video', 'Video', _exportWebM),
      _MediaTool(Icons.photo_outlined, 'HEIC to JPEG',
          'Convert an iPhone photo', 'Image', _heicToJpeg),
      _MediaTool(Icons.video_file_outlined, 'MOV to MP4',
          'Fast remux with no quality loss', 'Video', _movToMp4),
    ];
    final categories = ['All', 'Video', 'Audio', 'Social', 'Effects', 'Image'];
    final filtered = _selectedCategory == 'All'
        ? tools
        : tools.where((tool) => tool.category == _selectedCategory).toList();
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1000
          ? 3
          : constraints.maxWidth >= 600
              ? 2
              : 1;
      return Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.pinkAccent.withOpacity(.16),
                Colors.blue.withOpacity(.12),
              ]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(.08)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: Colors.cyanAccent),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Private by design — files are processed locally in your browser and never uploaded.',
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final category = categories[index];
                return ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = category),
                );
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: filtered.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: columns == 1 ? 190 : 220,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final tool = filtered[index];
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
                            child: Icon(tool.icon,
                                color: Colors.cyanAccent, size: 26),
                          ),
                          const SizedBox(height: 8),
                          Text(tool.category.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2)),
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
                              color:
                                  _isLoaded ? Colors.cyanAccent : bodyTextColor,
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
            ),
          ),
        ],
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
      const maxBrowserFileSize = 500 * 1024 * 1024;
      if (file.size > maxBrowserFileSize) {
        throw StateError(
            'This browser tool supports files up to 500 MB. Use a shorter clip for reliable processing.');
      }
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
    final dimensions = size.split('x');
    final width = dimensions[0];
    final height = dimensions[1];
    await _process(() async {
      if (!await FfmpegManager.instance.runCommand([
        '-i',
        input,
        '-vf',
        'scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2',
        '-c:v',
        'libx264',
        '-preset',
        'veryfast',
        '-c:a',
        'aac',
        output
      ])) return false;
      return FileUtils.downloadBytesInWeb(
        FfmpegManager.instance.ffmpeg?.readFile(output),
        output,
        mimeType: 'video/mp4',
      );
    });
  }

  Future<void> _runVideoTool({
    required String output,
    required List<String> Function(String input) command,
    String mimeType = 'video/mp4',
  }) async {
    final input = await _pickFile();
    if (input == null) return;
    await _process(() async {
      if (!await FfmpegManager.instance.runCommand(command(input))) {
        return false;
      }
      return FileUtils.downloadBytesInWeb(
        FfmpegManager.instance.ffmpeg?.readFile(output),
        output,
        mimeType: mimeType,
      );
    });
  }

  Future<void> _squareVideo() => _runVideoTool(
        output: 'square_1080.mp4',
        command: (input) => [
          '-i',
          input,
          '-vf',
          'scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:(ow-iw)/2:(oh-ih)/2',
          '-c:v',
          'libx264',
          '-preset',
          'veryfast',
          '-c:a',
          'aac',
          'square_1080.mp4'
        ],
      );

  Future<void> _landscapeVideo() => _runVideoTool(
        output: 'landscape_720p.mp4',
        command: (input) => [
          '-i',
          input,
          '-vf',
          'scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2',
          '-c:v',
          'libx264',
          '-preset',
          'veryfast',
          '-c:a',
          'aac',
          'landscape_720p.mp4'
        ],
      );

  Future<void> _trimVideo() => _runVideoTool(
        output: 'trimmed_15s.mp4',
        command: (input) => [
          '-i',
          input,
          '-t',
          '15',
          '-c',
          'copy',
          '-movflags',
          '+faststart',
          'trimmed_15s.mp4'
        ],
      );

  Future<void> _compressVideo() => _runVideoTool(
        output: 'compressed_720p.mp4',
        command: (input) => [
          '-i',
          input,
          '-vf',
          'scale=-2:720',
          '-c:v',
          'libx264',
          '-crf',
          '28',
          '-preset',
          'veryfast',
          '-c:a',
          'aac',
          '-b:a',
          '128k',
          '-movflags',
          '+faststart',
          'compressed_720p.mp4'
        ],
      );

  Future<void> _muteVideo() => _runVideoTool(
        output: 'muted.mp4',
        command: (input) => ['-i', input, '-c:v', 'copy', '-an', 'muted.mp4'],
      );

  Future<void> _extractAudio() => _runVideoTool(
        output: 'soundtrack.m4a',
        mimeType: 'audio/mp4',
        command: (input) => [
          '-i',
          input,
          '-vn',
          '-c:a',
          'aac',
          '-b:a',
          '192k',
          'soundtrack.m4a'
        ],
      );

  Future<void> _normalizeAudio() => _runVideoTool(
        output: 'normalized_voice.mp4',
        command: (input) => [
          '-i',
          input,
          '-c:v',
          'copy',
          '-af',
          'loudnorm=I=-14:TP=-1.5:LRA=11',
          '-c:a',
          'aac',
          '-b:a',
          '192k',
          'normalized_voice.mp4'
        ],
      );

  Future<void> _videoToGif() => _runVideoTool(
        output: 'preview.gif',
        mimeType: 'image/gif',
        command: (input) => [
          '-i',
          input,
          '-t',
          '6',
          '-vf',
          'fps=10,scale=480:-1:flags=lanczos',
          '-loop',
          '0',
          'preview.gif'
        ],
      );

  Future<void> _rotateVideo() => _runVideoTool(
        output: 'rotated_90.mp4',
        command: (input) => [
          '-i',
          input,
          '-vf',
          'transpose=1',
          '-c:v',
          'libx264',
          '-preset',
          'veryfast',
          '-c:a',
          'aac',
          'rotated_90.mp4'
        ],
      );

  Future<void> _reelBlur() => _runVideoTool(
        output: 'reel_blur_720x1280.mp4',
        command: (input) => [
          '-i',
          input,
          '-filter_complex',
          '[0:v]scale=720:1280,boxblur=20:10[bg];[0:v]scale=720:1280:force_original_aspect_ratio=decrease[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2,setsar=1[v]',
          '-map',
          '[v]',
          '-map',
          '0:a?',
          '-c:v',
          'libx264',
          '-preset',
          'veryfast',
          '-c:a',
          'aac',
          '-movflags',
          '+faststart',
          'reel_blur_720x1280.mp4'
        ],
      );

  Future<void> _speedUpVideo() => _runVideoTool(
        output: 'speed_2x.mp4',
        command: (input) => [
          '-i',
          input,
          '-filter_complex',
          '[0:v]setpts=0.5*PTS[v];[0:a]atempo=2.0[a]',
          '-map',
          '[v]',
          '-map',
          '[a]',
          '-c:v',
          'libx264',
          '-preset',
          'veryfast',
          '-c:a',
          'aac',
          'speed_2x.mp4'
        ],
      );

  Future<void> _slowMotionVideo() => _runVideoTool(
        output: 'slow_motion_05x.mp4',
        command: (input) => [
          '-i',
          input,
          '-filter_complex',
          '[0:v]setpts=2.0*PTS[v];[0:a]atempo=0.5[a]',
          '-map',
          '[v]',
          '-map',
          '[a]',
          '-c:v',
          'libx264',
          '-preset',
          'veryfast',
          '-c:a',
          'aac',
          'slow_motion_05x.mp4'
        ],
      );

  Future<void> _reverseVideo() => _runVideoTool(
        output: 'reversed.mp4',
        command: (input) => [
          '-i',
          input,
          '-vf',
          'reverse',
          '-af',
          'areverse',
          '-c:v',
          'libx264',
          '-preset',
          'veryfast',
          '-c:a',
          'aac',
          'reversed.mp4'
        ],
      );

  Future<void> _mirrorVideo() => _runVideoTool(
        output: 'mirrored.mp4',
        command: (input) => [
          '-i',
          input,
          '-vf',
          'hflip',
          '-c:v',
          'libx264',
          '-preset',
          'veryfast',
          '-c:a',
          'copy',
          'mirrored.mp4'
        ],
      );

  Future<void> _monochromeVideo() => _runVideoTool(
        output: 'black_and_white.mp4',
        command: (input) => [
          '-i',
          input,
          '-vf',
          'hue=s=0',
          '-c:v',
          'libx264',
          '-preset',
          'veryfast',
          '-c:a',
          'copy',
          'black_and_white.mp4'
        ],
      );

  Future<void> _enhanceVideo() => _runVideoTool(
        output: 'enhanced.mp4',
        command: (input) => [
          '-i',
          input,
          '-vf',
          'eq=brightness=0.04:contrast=1.08:saturation=1.12',
          '-c:v',
          'libx264',
          '-preset',
          'veryfast',
          '-c:a',
          'copy',
          'enhanced.mp4'
        ],
      );

  Future<void> _boostVolume() => _runVideoTool(
        output: 'volume_boost.mp4',
        command: (input) => [
          '-i',
          input,
          '-c:v',
          'copy',
          '-af',
          'volume=1.5',
          '-c:a',
          'aac',
          'volume_boost.mp4'
        ],
      );

  Future<void> _compressVoice() => _runVideoTool(
        output: 'voice_compressed.mp4',
        command: (input) => [
          '-i',
          input,
          '-c:v',
          'copy',
          '-af',
          'acompressor=threshold=-18dB:ratio=3:attack=20:release=250:makeup=2dB',
          '-c:a',
          'aac',
          '-b:a',
          '192k',
          'voice_compressed.mp4'
        ],
      );

  Future<void> _audioFadeIn() => _runVideoTool(
        output: 'audio_fade_in.mp4',
        command: (input) => [
          '-i',
          input,
          '-c:v',
          'copy',
          '-af',
          'afade=t=in:st=0:d=2',
          '-c:a',
          'aac',
          'audio_fade_in.mp4'
        ],
      );

  Future<void> _exportWebM() => _runVideoTool(
        output: 'web_video.webm',
        mimeType: 'video/webm',
        command: (input) => [
          '-i',
          input,
          '-c:v',
          'libvpx-vp9',
          '-crf',
          '34',
          '-b:v',
          '0',
          '-c:a',
          'libopus',
          '-b:a',
          '128k',
          'web_video.webm'
        ],
      );

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
  final String category;
  final VoidCallback action;

  const _MediaTool(
      this.icon, this.title, this.description, this.category, this.action);
}
