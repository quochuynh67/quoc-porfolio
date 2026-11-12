import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_wasm/ffmpeg_wasm.dart';
import 'package:flutter_portfolio/view/media_tool/screen/extensions.dart';
import 'package:image_size_getter/image_size_getter.dart' as isg;
import 'package:rxdart/rxdart.dart';
import 'package:screenshot/screenshot.dart';

import '../ffmpeg_manager.dart';
import '../file_utils.dart';
import 'widget/crop_box/crop_box.dart';
import 'widget/media_ui.dart';
import 'widget/overlay_config_widget.dart';

enum QuoteExportRatio { ratio916, ratio169, ratio11 }

class QuoteSource {
  bool isVideo;
  Uint8List bytes;
  Size mediaSize;

  QuoteSource(this.isVideo, this.bytes, this.mediaSize);

  static bool isVideoType(String ext) {
    return ext.contains('mp4');
  }
}

class OverlayConfigModel {
  String text;
  double fontSize;
  double dx;
  double dy;
  Color backgroundTextColor;
  Color textColor;
  String type;
  TextStyle textStyle;

  OverlayConfigModel(
      {required this.text,
      required this.fontSize,
      required this.dx,
      required this.textStyle,
      required this.dy,
      required this.type,
      required this.backgroundTextColor,
      required this.textColor});

  OverlayConfigModel copyWith(
      {String? text,
      double? fontSize,
      double? dx,
      double? dy,
      Color? backgroundTextColor,
      String? type,
      TextStyle? textStyle,
      Color? textColor}) {
    return OverlayConfigModel(
      backgroundTextColor: backgroundTextColor ?? this.backgroundTextColor,
      fontSize: fontSize ?? this.fontSize,
      dy: dy ?? this.dy,
      dx: dx ?? this.dx,
      type: type ?? this.type,
      textStyle: textStyle ?? this.textStyle,
      text: text ?? this.text,
      textColor: textColor ?? this.textColor,
    );
  }
}

class QuoteMakerScreen extends StatefulWidget {
  const QuoteMakerScreen({Key? key}) : super(key: key);

  @override
  State<QuoteMakerScreen> createState() => VlogMakerScreenState();
}

class VlogMakerScreenState extends State<QuoteMakerScreen> {
  ScreenshotController screenshotController = ScreenshotController();

  FilePickerResult? filePickerResult;
  final previewWidgetKey = GlobalKey();
  final titleWidgetKey = GlobalKey();
  final subtitleWidgetKey = GlobalKey();
  final authorWidgetKey = GlobalKey();

  /// Emit changes
  final mediaList = ValueNotifier<List<QuoteSource>>([]);
  final testMediaList = ValueNotifier<List<QuoteSource>>([]);
  final BehaviorSubject<OverlayConfigModel?> currentOverlaySelected =
      BehaviorSubject();
  final audioList = ValueNotifier<List<String>>([]);
  // final progress = ValueNotifier<ProgressParam?>(null);
  // final cmdStream = ValueNotifier<String>('');

  final previewRect = ValueNotifier<Rect?>(null);
  final titleRect = ValueNotifier<Rect?>(null);
  final subTitleRect = ValueNotifier<Rect?>(null);
  final authorRect = ValueNotifier<Rect?>(null);

  final BehaviorSubject<Offset> overlayConfigPosition = BehaviorSubject();

  /// crop & ratio preview
  final quoteRatio = ValueNotifier(QuoteExportRatio.ratio916);
  final cropRect = ValueNotifier(const Rect.fromLTRB(0.0, 0.0, 1.0, 1.0));

  /// overlay
  final BehaviorSubject<OverlayConfigModel> titleOverlay =
      BehaviorSubject.seeded(OverlayConfigModel(
          dx: 50.0,
          dy: 50.0,
          text: 'Title ',
          fontSize: 16,
          type: 'text1',
          textStyle: TextStyle(),
          backgroundTextColor: Colors.black.withOpacity(0.4),
          textColor: Colors.white));

  final BehaviorSubject<OverlayConfigModel> subtitleOverlay =
      BehaviorSubject.seeded(OverlayConfigModel(
          dx: 50.0,
          dy: 150.0,
          text: 'Sub-title',
          type: 'text2',
          fontSize: 16,
          textStyle: TextStyle(),
          backgroundTextColor: Colors.black.withOpacity(0.4),
          textColor: Colors.white));

  final BehaviorSubject<OverlayConfigModel> authorOverlay =
      BehaviorSubject.seeded(OverlayConfigModel(
          dx: 50.0,
          dy: 200.0,
          text: 'Author',
          type: 'text3',
          fontSize: 25,
          textStyle: TextStyle(),
          backgroundTextColor: Colors.black.withOpacity(0.4),
          textColor: Colors.white));

  /// CMD
  List<String> cmd = [];
  List<String> clipInput = [
    '-loop',
    '1',
    '-i',
    'background.jpg',
  ];
  List<String> audioInput = [];

  @override
  void initState() {
    // FfmpegManager.instance.loadFFmpeg(() {}, setLog: false);
    // if(FfmpegManager.instance.isLoaded) {
    //   FfmpegManager.instance.ffmpeg?.setProgress((p) {
    //     progress.value = p;
    //   });
    // }
    super.initState();
  }

  @override
  void dispose() {
    mediaList.dispose();
    testMediaList.dispose();
    audioList.dispose();
    previewRect.dispose();
    titleRect.dispose();
    subTitleRect.dispose();
    authorRect.dispose();
    quoteRatio.dispose();
    cropRect.dispose();
    currentOverlaySelected.close();
    titleOverlay.close();
    subtitleOverlay.close();
    authorOverlay.close();
    overlayConfigPosition.close();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) calculatePreviewWidgetSize();
    });
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant QuoteMakerScreen oldWidget) {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) calculatePreviewWidgetSize();
    });
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: MediaTabHeader(
                    title: 'Quote video maker',
                    subtitle:
                        'Pick an image and music, place your text, then export.'),
              ),
              const SizedBox(height: 12),
              MediaPanel(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: pickVideoImageFiles,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('Chọn ảnh'),
                    ),
                    ValueListenableBuilder<List<String>>(
                      valueListenable: audioList,
                      builder: (context, value, _) => OutlinedButton.icon(
                        onPressed: pickAudioFiles,
                        icon: Icon(
                            value.isEmpty
                                ? Icons.music_note_outlined
                                : Icons.check_circle_outline,
                            size: 18),
                        label: Text(
                            value.isEmpty ? 'Chọn nhạc nền' : 'Đã chọn nhạc'),
                      ),
                    ),
                    ValueListenableBuilder<QuoteExportRatio>(
                      valueListenable: quoteRatio,
                      builder: (context, ratio, _) =>
                          SegmentedButton<QuoteExportRatio>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                            visualDensity: VisualDensity.compact),
                        segments: const [
                          ButtonSegment(
                              value: QuoteExportRatio.ratio916,
                              label: Text('9:16')),
                          ButtonSegment(
                              value: QuoteExportRatio.ratio169,
                              label: Text('16:9')),
                          ButtonSegment(
                              value: QuoteExportRatio.ratio11,
                              label: Text('1:1')),
                        ],
                        selected: {ratio},
                        onSelectionChanged: (s) =>
                            _handleChangeQuoteRatio(s.first),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _captureAndExport(),
                      icon: const Icon(Icons.movie_creation_outlined, size: 18),
                      label: const Text('Xuất 1080p'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _captureAndExport(is480p: true),
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Xuất 480p'),
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder<List<String>>(
                valueListenable: audioList,
                builder: (context, value, _) => value.isEmpty
                    ? const SizedBox()
                    : Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(value.first.trim().replaceAll('\n', '  '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xFFB4B8C5), fontSize: 12)),
                        ),
                      ),
              ),
              const SizedBox(height: 12),

              /// QuoteCanvas
              ///
              ValueListenableBuilder<QuoteExportRatio>(
                builder: (context, value, _) {
                  Size size = _getSupportSizeByRatio(ratio: value);
                  return Expanded(
                    child: Center(
                      child: Screenshot(
                        controller: screenshotController,
                        key: previewWidgetKey,
                        child: AspectRatio(
                          aspectRatio: size.aspectRatio,
                          child: ValueListenableBuilder(
                              valueListenable: mediaList,
                              builder: (context, sourceValue, _) {
                                return ValueListenableBuilder<Rect>(
                                    valueListenable: cropRect,
                                    builder: (context, cropRectValue, _) {
                                      return sourceValue.isEmpty
                                          ? Container(
                                              decoration: BoxDecoration(
                                                color: mediaPanelColor,
                                                border: Border.all(
                                                    color: mediaPanelBorder),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: const MediaEmptyState(
                                                  icon: Icons
                                                      .add_photo_alternate_outlined,
                                                  label:
                                                      'Chọn ảnh để bắt đầu thiết kế quote'),
                                            )
                                          : Stack(
                                              children: [
                                                /// QuoteCanvasEditor
                                                ///
                                                CropBox(
                                                    clipSize: sourceValue
                                                        .first.mediaSize,
                                                    cropRatio: size,
                                                    cropRect: cropRectValue,
                                                    backgroundColor:
                                                        Colors.cyan,
                                                    cropRectUpdateEnd:
                                                        (Rect rect) {
                                                      cropRect.value = rect;
                                                    },
                                                    child: Container(
                                                      color: Colors.grey,
                                                      child: (sourceValue
                                                              .first.isVideo)
                                                          ? const Center(
                                                              child:
                                                                  Text('Video'))
                                                          : Image.memory(
                                                              sourceValue
                                                                  .first.bytes,
                                                              fit:
                                                                  BoxFit.cover),
                                                    )),

                                                /// TextOverlay
                                                ///
                                                StreamBuilder<
                                                        OverlayConfigModel>(
                                                    stream: titleOverlay,
                                                    builder:
                                                        (context, snapshot) {
                                                      final titleOverlayValue =
                                                          snapshot.data;
                                                      if (titleOverlayValue ==
                                                          null)
                                                        return const SizedBox();
                                                      return Positioned(
                                                        top: titleOverlayValue
                                                            .dy,
                                                        left: titleOverlayValue
                                                            .dx,
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            currentOverlaySelected
                                                                .add(null);
                                                            Future.delayed(
                                                                const Duration(
                                                                    milliseconds:
                                                                        100),
                                                                () {
                                                              currentOverlaySelected
                                                                  .add(
                                                                      titleOverlayValue);
                                                            });
                                                          },
                                                          onPanUpdate:
                                                              (details) {
                                                            titleOverlay.value = titleOverlay.value.copyWith(
                                                                dx: titleOverlay
                                                                        .value
                                                                        .dx +
                                                                    details
                                                                        .delta
                                                                        .dx,
                                                                dy: titleOverlay
                                                                        .value
                                                                        .dy +
                                                                    details
                                                                        .delta
                                                                        .dy,
                                                                text: titleOverlay
                                                                    .value.text,
                                                                textColor: titleOverlay
                                                                    .value
                                                                    .textColor,
                                                                fontSize: titleOverlay
                                                                    .value
                                                                    .fontSize,
                                                                textStyle: titleOverlay
                                                                    .value
                                                                    .textStyle,
                                                                type: titleOverlay.value.type,
                                                                backgroundTextColor: titleOverlay.value.backgroundTextColor);
                                                          },
                                                          child: Container(
                                                            color: titleOverlayValue
                                                                .backgroundTextColor
                                                                .withOpacity(
                                                                    0.4),
                                                            key: titleWidgetKey,
                                                            child: Text(
                                                                titleOverlayValue
                                                                    .text,
                                                                style: titleOverlayValue
                                                                    .textStyle
                                                                    .copyWith(
                                                                        fontSize:
                                                                            titleOverlayValue
                                                                                .fontSize,
                                                                        color: titleOverlayValue
                                                                            .textColor)),
                                                          ),
                                                        ),
                                                      );
                                                    }),

                                                StreamBuilder<
                                                        OverlayConfigModel>(
                                                    stream: subtitleOverlay,
                                                    builder:
                                                        (context, snapshot) {
                                                      final subtitleOverlayValue =
                                                          snapshot.data;
                                                      if (subtitleOverlayValue ==
                                                          null)
                                                        return const SizedBox();
                                                      return Positioned(
                                                        top:
                                                            subtitleOverlayValue
                                                                .dy,
                                                        left:
                                                            subtitleOverlayValue
                                                                .dx,
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            currentOverlaySelected
                                                                .add(null);
                                                            Future.delayed(
                                                                const Duration(
                                                                    milliseconds:
                                                                        100),
                                                                () {
                                                              currentOverlaySelected
                                                                  .add(
                                                                      subtitleOverlayValue);
                                                            });
                                                          },
                                                          onPanUpdate:
                                                              (details) {
                                                            subtitleOverlay.value = subtitleOverlay.value.copyWith(
                                                                dx: subtitleOverlay.value.dx +
                                                                    details
                                                                        .delta
                                                                        .dx,
                                                                dy: subtitleOverlay
                                                                        .value
                                                                        .dy +
                                                                    details
                                                                        .delta
                                                                        .dy,
                                                                text: subtitleOverlay
                                                                    .value.text,
                                                                textColor: subtitleOverlay
                                                                    .value
                                                                    .textColor,
                                                                fontSize: subtitleOverlay
                                                                    .value
                                                                    .fontSize,
                                                                textStyle:
                                                                    subtitleOverlay
                                                                        .value
                                                                        .textStyle,
                                                                type: subtitleOverlay.value.type,
                                                                backgroundTextColor: subtitleOverlay.value.backgroundTextColor);
                                                          },
                                                          child: Container(
                                                            color: subtitleOverlayValue
                                                                .backgroundTextColor
                                                                .withOpacity(
                                                                    0.4),
                                                            key:
                                                                subtitleWidgetKey,
                                                            child: Text(
                                                                subtitleOverlayValue
                                                                    .text,
                                                                style: subtitleOverlayValue
                                                                    .textStyle
                                                                    .copyWith(
                                                                        fontSize:
                                                                            subtitleOverlayValue
                                                                                .fontSize,
                                                                        color: subtitleOverlayValue
                                                                            .textColor)),
                                                          ),
                                                        ),
                                                      );
                                                    }),

                                                StreamBuilder<
                                                        OverlayConfigModel>(
                                                    stream: authorOverlay,
                                                    builder:
                                                        (context, snapshot) {
                                                      final authorOverlayValue =
                                                          snapshot.data;
                                                      if (authorOverlayValue ==
                                                          null)
                                                        return const SizedBox();
                                                      return Positioned(
                                                        top: authorOverlayValue
                                                            .dy,
                                                        left: authorOverlayValue
                                                            .dx,
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            currentOverlaySelected
                                                                .add(null);
                                                            Future.delayed(
                                                                const Duration(
                                                                    milliseconds:
                                                                        100),
                                                                () {
                                                              currentOverlaySelected
                                                                  .add(
                                                                      authorOverlayValue);
                                                            });
                                                          },
                                                          onPanUpdate:
                                                              (details) {
                                                            authorOverlay.value = authorOverlay.value.copyWith(
                                                                dx: authorOverlay.value.dx +
                                                                    details
                                                                        .delta
                                                                        .dx,
                                                                dy: authorOverlay
                                                                        .value
                                                                        .dy +
                                                                    details
                                                                        .delta
                                                                        .dy,
                                                                text: authorOverlay
                                                                    .value.text,
                                                                textColor: authorOverlay
                                                                    .value
                                                                    .textColor,
                                                                fontSize: authorOverlay
                                                                    .value
                                                                    .fontSize,
                                                                textStyle:
                                                                    authorOverlay
                                                                        .value
                                                                        .textStyle,
                                                                type: authorOverlay.value.type,
                                                                backgroundTextColor: authorOverlay.value.backgroundTextColor);
                                                          },
                                                          child: Container(
                                                            color: authorOverlayValue
                                                                .backgroundTextColor
                                                                .withOpacity(
                                                                    0.4),
                                                            key:
                                                                authorWidgetKey,
                                                            child: Text(
                                                                authorOverlayValue
                                                                    .text,
                                                                style: authorOverlayValue
                                                                    .textStyle
                                                                    .copyWith(
                                                                        fontSize:
                                                                            authorOverlayValue
                                                                                .fontSize,
                                                                        color: authorOverlayValue
                                                                            .textColor)),
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                              ],
                                            );
                                    });
                              }),
                        ),
                      ),
                    ),
                  );
                },
                valueListenable: quoteRatio,
              ),
            ],
          ),

          /// ConfigOverlayWidget
          ///
          StreamBuilder<Offset>(
              stream: overlayConfigPosition,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Offset.zero;
                return Positioned(
                  top: position.dy,
                  left: position.dx,
                  width: MediaQuery.sizeOf(context).width < 440
                      ? MediaQuery.sizeOf(context).width - 32
                      : 400,
                  child: StreamBuilder<OverlayConfigModel?>(
                      stream: currentOverlaySelected,
                      builder: (context, snapshot) {
                        final value = snapshot.data;
                        if (value == null) return const SizedBox();
                        return GestureDetector(
                          onPanUpdate: (details) {
                            overlayConfigPosition.add(Offset(
                                position.dx + details.delta.dx,
                                position.dy + details.delta.dy));
                          },
                          child: OverlayConfigWidget(
                            previewRect: Rect.zero,
                            overlay: value,
                            onClosed: () {
                              currentOverlaySelected.add(null);
                            },
                            onBackgroundTextColorUpdated: (v) {
                              switch (value.type) {
                                case 'text1':
                                  final temp = titleOverlay.value.copyWith(
                                      dx: titleOverlay.value.dx,
                                      dy: titleOverlay.value.dy,
                                      text: titleOverlay.value.text,
                                      textColor: titleOverlay.value.textColor,
                                      fontSize: titleOverlay.value.fontSize,
                                      backgroundTextColor: v);
                                  titleOverlay.value = temp;
                                  break;
                                case 'text2':
                                  final temp = subtitleOverlay.value.copyWith(
                                      dx: subtitleOverlay.value.dx,
                                      dy: subtitleOverlay.value.dy,
                                      text: subtitleOverlay.value.text,
                                      textColor:
                                          subtitleOverlay.value.textColor,
                                      fontSize: subtitleOverlay.value.fontSize,
                                      backgroundTextColor: v);
                                  subtitleOverlay.value = temp;
                                  break;
                                case 'text3':
                                  final temp = authorOverlay.value.copyWith(
                                      dx: authorOverlay.value.dx,
                                      dy: authorOverlay.value.dy,
                                      text: authorOverlay.value.text,
                                      textColor: authorOverlay.value.textColor,
                                      fontSize: authorOverlay.value.fontSize,
                                      backgroundTextColor: v);
                                  authorOverlay.value = temp;
                                  break;
                              }
                            },
                            onFontSizeUpdated: (v) {
                              switch (value.type) {
                                case 'text1':
                                  final temp = titleOverlay.value.copyWith(
                                      dx: titleOverlay.value.dx,
                                      dy: titleOverlay.value.dy,
                                      text: titleOverlay.value.text,
                                      textColor: titleOverlay.value.textColor,
                                      fontSize: v,
                                      backgroundTextColor: titleOverlay
                                          .value.backgroundTextColor);
                                  titleOverlay.value = temp;
                                  break;
                                case 'text2':
                                  final temp = subtitleOverlay.value.copyWith(
                                      dx: subtitleOverlay.value.dx,
                                      dy: subtitleOverlay.value.dy,
                                      text: subtitleOverlay.value.text,
                                      textColor:
                                          subtitleOverlay.value.textColor,
                                      fontSize: v,
                                      backgroundTextColor: subtitleOverlay
                                          .value.backgroundTextColor);
                                  subtitleOverlay.value = temp;
                                  break;
                                case 'text3':
                                  final temp = authorOverlay.value.copyWith(
                                      dx: authorOverlay.value.dx,
                                      dy: authorOverlay.value.dy,
                                      text: authorOverlay.value.text,
                                      textColor: authorOverlay.value.textColor,
                                      fontSize: v,
                                      backgroundTextColor: authorOverlay
                                          .value.backgroundTextColor);
                                  authorOverlay.value = temp;
                                  break;
                              }
                            },
                            onTextColorUpdated: (v) {
                              switch (value.type) {
                                case 'text1':
                                  final temp = titleOverlay.value.copyWith(
                                      dx: titleOverlay.value.dx,
                                      dy: titleOverlay.value.dy,
                                      text: titleOverlay.value.text,
                                      textColor: v,
                                      fontSize: titleOverlay.value.fontSize,
                                      backgroundTextColor: titleOverlay
                                          .value.backgroundTextColor);
                                  titleOverlay.value = temp;
                                  break;
                                case 'text2':
                                  final temp = subtitleOverlay.value.copyWith(
                                      dx: subtitleOverlay.value.dx,
                                      dy: subtitleOverlay.value.dy,
                                      text: subtitleOverlay.value.text,
                                      textColor: v,
                                      fontSize: subtitleOverlay.value.fontSize,
                                      backgroundTextColor: subtitleOverlay
                                          .value.backgroundTextColor);
                                  subtitleOverlay.value = temp;
                                  break;
                                case 'text3':
                                  final temp = authorOverlay.value.copyWith(
                                      dx: authorOverlay.value.dx,
                                      dy: authorOverlay.value.dy,
                                      text: authorOverlay.value.text,
                                      textColor: v,
                                      fontSize: authorOverlay.value.fontSize,
                                      backgroundTextColor: authorOverlay
                                          .value.backgroundTextColor);
                                  authorOverlay.value = temp;
                                  break;
                              }
                            },
                            onTextUpdated: (v) {
                              switch (value.type) {
                                case 'text1':
                                  final temp = titleOverlay.value.copyWith(
                                      dx: titleOverlay.value.dx,
                                      dy: titleOverlay.value.dy,
                                      text: v,
                                      textColor: titleOverlay.value.textColor,
                                      fontSize: titleOverlay.value.fontSize,
                                      backgroundTextColor: titleOverlay
                                          .value.backgroundTextColor);
                                  titleOverlay.value = temp;
                                  break;
                                case 'text2':
                                  final temp = subtitleOverlay.value.copyWith(
                                      dx: subtitleOverlay.value.dx,
                                      dy: subtitleOverlay.value.dy,
                                      text: v,
                                      textColor:
                                          subtitleOverlay.value.textColor,
                                      fontSize: subtitleOverlay.value.fontSize,
                                      backgroundTextColor: subtitleOverlay
                                          .value.backgroundTextColor);

                                  subtitleOverlay.value = temp;
                                  break;
                                case 'text3':
                                  final temp = authorOverlay.value.copyWith(
                                      dx: authorOverlay.value.dx,
                                      dy: authorOverlay.value.dy,
                                      text: v,
                                      textColor: authorOverlay.value.textColor,
                                      fontSize: authorOverlay.value.fontSize,
                                      backgroundTextColor: authorOverlay
                                          .value.backgroundTextColor);

                                  authorOverlay.value = temp;
                                  break;
                              }
                            },
                            onTextStyleUpdated: (v, textStyle) {
                              switch (value.type) {
                                case 'text1':
                                  final temp = titleOverlay.value.copyWith(
                                    dx: titleOverlay.value.dx,
                                    dy: titleOverlay.value.dy,
                                    text: titleOverlay.value.text,
                                    textColor: titleOverlay.value.textColor,
                                    fontSize: titleOverlay.value.fontSize,
                                    backgroundTextColor:
                                        titleOverlay.value.backgroundTextColor,
                                    textStyle: textStyle,
                                  );
                                  titleOverlay.value = temp;
                                  break;
                                case 'text2':
                                  final temp = subtitleOverlay.value.copyWith(
                                      dx: subtitleOverlay.value.dx,
                                      dy: subtitleOverlay.value.dy,
                                      text: subtitleOverlay.value.text,
                                      textColor:
                                          subtitleOverlay.value.textColor,
                                      fontSize: subtitleOverlay.value.fontSize,
                                      backgroundTextColor: subtitleOverlay
                                          .value.backgroundTextColor,
                                      textStyle: textStyle);
                                  subtitleOverlay.value = temp;
                                  break;
                                case 'text3':
                                  final temp = authorOverlay.value.copyWith(
                                      dx: authorOverlay.value.dx,
                                      dy: authorOverlay.value.dy,
                                      text: authorOverlay.value.text,
                                      textColor: authorOverlay.value.textColor,
                                      fontSize: authorOverlay.value.fontSize,
                                      backgroundTextColor: authorOverlay
                                          .value.backgroundTextColor,
                                      textStyle: textStyle);
                                  authorOverlay.value = temp;
                                  break;
                              }
                            },
                          ),
                        );
                      }),
                );
              }),
        ],
      ),
    );
  }

  void _captureAndExport({bool is480p = false}) {
    screenshotController
        .capture(delay: const Duration(milliseconds: 10))
        .then((capturedImage) async {
      final memoryImageSize =
          isg.ImageSizeGetter.getSize(isg.MemoryInput(capturedImage!));
      final mediaSize = Size(
          memoryImageSize.width.toDouble(), memoryImageSize.height.toDouble());
      testMediaList.value = [QuoteSource(false, capturedImage, mediaSize)];
      FfmpegManager.instance.ffmpeg?.writeFile('background.jpg', capturedImage);
      final backgroundImageFile =
          FfmpegManager.instance.ffmpeg?.readFile('background.jpg');
      if (backgroundImageFile?.isNotEmpty == true) {
        _handleExport(is480p: is480p);
      }
    }).catchError((onError) {
      _showMessage('Add an image before exporting.', isError: true);
    });
  }

  Future<void> pickAudioFiles() async {
    try {
      filePickerResult = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['mp3'],
          allowMultiple: false);

      if (filePickerResult != null) {
        audioInput.clear();
        List<String> picked = [];
        for (int i = 0; i < filePickerResult!.files.length; ++i) {
          final file = filePickerResult!.files.elementAt(i);
          FfmpegManager.instance.ffmpeg?.writeFile('audio$i.mp3', file.bytes!);
          picked.add(''
              '\n- Tên audio file: ${file.name} '
              '\n- extension: ${file.extension} '
              '\n- bytes: ${file.bytes?.length}');

          audioInput.addAll(['-i', 'audio$i.mp3']);
        }
        audioList.value = picked;
      }
    } catch (e) {
      if (!mounted) return;
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
          allowCompression: false,
          allowMultiple: false);

      if (filePickerResult != null) {
        List<QuoteSource> picked = [];
        for (int i = 0; i < filePickerResult!.files.length; ++i) {
          final file = filePickerResult!.files.elementAt(i);
          bool isVideo = QuoteSource.isVideoType(file.extension ?? '');
          final memoryImageSize =
              isg.ImageSizeGetter.getSize(isg.MemoryInput(file.bytes!));
          Size mediaSize = Size(memoryImageSize.width.toDouble(),
              memoryImageSize.height.toDouble());
          picked.add(QuoteSource(isVideo, file.bytes!, mediaSize));
        }
        mediaList.value = picked;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video/image files: $e')),
      );
    }
  }

  Future<void> _handleExport({bool is480p = false}) async {
    if (!FfmpegManager.instance.isLoaded) {
      _showMessage('Media engine is not ready.', isError: true);
      return;
    }
    if (audioInput.isEmpty) {
      _showMessage('Select background music first.', isError: true);
      return;
    }
    cmd.clear();
    cmd.insertAll(0, audioInput);
    cmd.insertAll(0, clipInput);

    /// ffmpeg -loop 1 -framerate 30 -i input_image.jpg -i input_audio.mp3 -c:v
    /// libx264 -tune stillimage -c:a aac -strict experimental
    /// -b:a 192k -shortest output_video.mp4
    Size size = _getSupportSizeByRatio(is480p: is480p);
    cmd.addAll([
      '-vf',
      'scale=${size.width}:${size.height},format=yuv420p',
      '-c:v',
      'libx264',
      '-tune',
      'stillimage',
      '-c:a',
      'aac',
      '-strict',
      'experimental',
      '-b:a',
      '192k',
      '-shortest',
      'output.mp4'
    ]);

    // cmdStream.value = cmd.toString();
    final success = await FfmpegManager.instance.runCommand(cmd);
    if (!mounted) return;
    if (!success) {
      _showMessage('Could not export the quote video.', isError: true);
      return;
    }
    final exportBytes = FfmpegManager.instance.ffmpeg?.readFile('output.mp4');
    if (exportBytes == null || exportBytes.isEmpty) {
      _showMessage('The exported video is empty.', isError: true);
      return;
    }
    FileUtils.downloadVideoOutputInWeb('output.mp4');
    _showMessage('Quote video exported successfully.');
  }

  void _handleChangeQuoteRatio(QuoteExportRatio ratio) {
    quoteRatio.value = ratio;
    _resetAllOverlayOffset();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) calculatePreviewWidgetSize();
    });
  }

  void calculatePreviewWidgetSize() {
    previewRect.value = previewWidgetKey.globalPaintBounds;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : null,
    ));
  }

  void _resetAllOverlayOffset() {
    cropRect.value = const Rect.fromLTRB(0.0, 0.0, 1.0, 1.0);

    titleOverlay.value = titleOverlay.value.copyWith(
        dx: 50.0,
        dy: 100.0,
        text: titleOverlay.value.text,
        textColor: titleOverlay.value.textColor,
        fontSize: titleOverlay.value.fontSize,
        backgroundTextColor: titleOverlay.value.backgroundTextColor);

    subtitleOverlay.value = subtitleOverlay.value.copyWith(
        dx: 50.0,
        dy: 150.0,
        text: subtitleOverlay.value.text,
        textColor: subtitleOverlay.value.textColor,
        fontSize: subtitleOverlay.value.fontSize,
        backgroundTextColor: subtitleOverlay.value.backgroundTextColor);

    authorOverlay.value = authorOverlay.value.copyWith(
        dx: 50.0,
        dy: 200.0,
        text: authorOverlay.value.text,
        textColor: authorOverlay.value.textColor,
        fontSize: authorOverlay.value.fontSize,
        backgroundTextColor: authorOverlay.value.backgroundTextColor);
  }

  Size _getSupportSizeByRatio({QuoteExportRatio? ratio, bool is480p = false}) {
    if (is480p) {
      switch (ratio ?? quoteRatio.value) {
        case QuoteExportRatio.ratio916:
          return const Size(360, 640);
        case QuoteExportRatio.ratio169:
          return const Size(640, 360);
        case QuoteExportRatio.ratio11:
          return const Size(480, 480);
      }
    }
    switch (ratio ?? quoteRatio.value) {
      case QuoteExportRatio.ratio916:
        return const Size(1080, 1920);
      case QuoteExportRatio.ratio169:
        return const Size(1920, 1080);
      case QuoteExportRatio.ratio11:
        return const Size(1080, 1080);
    }
  }

  bool isExceedRectWidth(Rect? textRect, Rect? previewRect) {
    if (textRect == null || previewRect == null) return false;
    return textRect.right > previewRect.right;
  }

  bool isExceedRectHeight(Rect? textRect, Rect? previewRect) {
    if (textRect == null || previewRect == null) return false;
    return textRect.bottom > previewRect.bottom;
  }

  bool isExceedRectLeftTop(Rect? textRect, Rect? previewRect) {
    if (textRect == null || previewRect == null) return false;
    return textRect.top <= previewRect.top || textRect.left <= previewRect.left;
  }
}
