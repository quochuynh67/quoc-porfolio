import 'dart:async';

import 'dart:js' as js;
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_web/video_player_web.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'feed_page.dart';
import 'feed_response.dart';
import 'video_model.dart';

class VideoItem extends StatefulWidget {
  const VideoItem({
    Key? key,
    required this.video,
  }) : super(key: key);
  final VideoModel video;

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  VideoPlayerController? videoController;
  bool disposed = false;
  bool videoInitialized = false;
  int debugTapCount = 0;
  List<Spots> _spots = [];
  Timer? _timer;
  Timer? _hidePanelTimer;
  late final AnimationController _slideController;
  late final Animation<Offset> _offsetAnimation;

  final BehaviorSubject<Spots?> _currentSpot = BehaviorSubject();
  final BehaviorSubject<bool> _volumeStream = BehaviorSubject();
  final BehaviorSubject<String> _loggerStream = BehaviorSubject();
  final BehaviorSubject<bool> _showButtonPanel = BehaviorSubject();
  final ScrollController scrollController = ScrollController();

  @override
  bool get wantKeepAlive => false;

  void _setLogger(String message) {
    String current = _loggerStream.valueOrNull ?? '';
    current += "\n $message\n|\nv";
    _loggerStream.add(current);
  }

  @override
  void initState() {
    super.initState();
    _spots = List.from(widget.video.spots);
    _initVideoController();
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (videoInitialized == false || videoController?.value.isInitialized == false) {
        setState(() {});
        _initVideoController();
        if (soundState) {
          enableSound();
        } else {
          disableSound();
        }
        _pauseOrPlay();
        timer.cancel();
      }
    });

    js.context.callMethod('logger',
        ['VideoDetailWidget.initState ===> Playing ${widget.video.url}']);
    _setLogger('Đang tải trạng thái video');
    if (soundState) {
      enableSound();
    } else {
      disableSound();
    }

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // hidden (below)
      end: const Offset(0, 0),   // visible
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    _showButtonPanel.listen((show) {
      if (show) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    });

    _onUserTap();
  }

  void _initVideoController() {
    videoController =
    VideoPlayerController.networkUrl(Uri.parse(widget.video.url))
      ..initialize().then((_) {
        setState(() {});
        videoController?.setLooping(true);
        videoInitialized = true;
        videoController?.addListener(_listenVideoValue);
        setState(() {});
        videoController?.play();
      }).onError((error, stackTrace) {
        js.context.callMethod('logger', [
          'VideoPlayerController.onError ===> Playing ${widget.video.url}, e $error, stackTrace $stackTrace'
        ]);
        _setLogger(
            'VideoPlayerController.onError ===> Playing ${widget.video.url}, e $error, stackTrace $stackTrace');
      }).catchError((e) {
        js.context.callMethod('logger', [
          'VideoPlayerController.catchError ===> Playing ${widget.video.url}, e $e'
        ]);
        _setLogger(
            'VideoPlayerController.catchError ===> Playing ${widget.video.url}, e $e');
      });
  }

  @override
  void dispose() {
    videoController?.removeListener(_listenVideoValue);
    videoController?.dispose();
    _currentSpot.close();
    _volumeStream.close();
    _loggerStream.close();
    _showButtonPanel.close();
    _timer?.cancel();
    _hidePanelTimer?.cancel();
    disposed = true;
    super.dispose();
  }

  void _listenVideoValue() {
    if (videoController?.value.hasError == true) {
      js.context.callMethod('logger', [
        'VideoPlayerController.listener ===> Playing ${widget.video.url}, e ${videoController?.value.errorDescription}'
      ]);
      _setLogger(
          'VideoPlayerController.listener ===> Playing ${widget.video.url}, e ${videoController?.value.errorDescription}');
    }
    final videoPosition = videoController?.value.position ?? Duration.zero;
    final spot = findClosestSpot(_spots, videoPosition.inSeconds.toDouble());
    _currentSpot.add(spot);
  }

  void enableSound() {
    soundState = true;
    videoController?.setVolume(1.0);
    _volumeStream.add(true);
  }

  void disableSound() {
    soundState = false;
    videoController?.setVolume(0.0);
    _volumeStream.add(false);
  }

  void showButtonPanel() {
    _showButtonPanel.add(true);
  }

  void hideButtonPanel() {
    _showButtonPanel.add(false);
  }

  Spots? findClosestSpot(List<Spots> spotsList, double playingTime) {
    double closestDifference = double.infinity;
    Spots? closestSpot;

    for (Spots spot in spotsList) {
      double difference = (spot.startTime! - playingTime).abs();
      if (difference < closestDifference) {
        closestDifference = difference;
        closestSpot = spot;
      }
    }

    return closestSpot;
  }

  void _pauseOrPlay() {
    if (videoController == null) return;
    if (videoController!.value.isPlaying) {
      videoController?.pause();
    } else {
      videoController?.play();
    }
  }

  void _onUserTap() {
    // Show panel
    _showButtonPanel.add(true);

    // Cancel previous timer if any
    _hidePanelTimer?.cancel();

    // Start a new timer to hide after 3 seconds
    _hidePanelTimer = Timer(const Duration(seconds: 7), () {
      _showButtonPanel.add(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _setLogger(
        'VideoDetailWidget.build ===> Playing ${widget.video.url} ---- videoController.value.isInitialized ${videoController?.value.isInitialized}');

    js.context.callMethod('logger', [
      'VideoDetailWidget.build ===> Playing ${widget.video.url} ---- videoController.value.isInitialized ${videoController?.value.isInitialized}'
    ]);

    return Stack(
      children: [
        /// Video area
        InkWell(
          onTapDown: (e) {
            debugTapCount += 1;
            if (debugTapCount == 10) {
              setState(() {});
            } else if (debugTapCount > 10) {
              debugTapCount = 0;
              setState(() {});
            }
            _pauseOrPlay();
            // 👇 Show panel and reset hide timer
            _onUserTap();
          },
          child: Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: videoController != null && videoInitialized
                ? VisibilityDetector(
                key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
                onVisibilityChanged: (VisibilityInfo info) {
                  if (disposed) return;
                  var visiblePercentage = info.visibleFraction * 100;
                  if (visiblePercentage < 1) {
                    videoController?.pause();
                  } else {
                    videoController?.play();
                  }
                },
                child: Align(
                    alignment: Alignment.center,
                    child: VideoPlayer(videoController!)))
                : widget.video.thumbnail != null
                ? Stack(
              alignment: Alignment.center,
              children: [
                Image.network(widget.video.thumbnail!,
                    fit: BoxFit.cover),
                InkWell(
                  onTap: () {
                    setState(() {});
                    _initVideoController();
                    if (soundState) {
                      enableSound();
                    } else {
                      disableSound();
                    }
                    _pauseOrPlay();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(25)),
                    padding: const EdgeInsets.all(16.0),
                    child: const Text('Bấm để tải và phát',
                        style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            )
                : const SizedBox(
                width: 50,
                height: 50,
                child: Center(child: CircularProgressIndicator())),
          ),
        ),
        StreamBuilder<bool>(
          stream: _showButtonPanel,
          builder: (context, snapshot) {
            bool showPanel = snapshot.data ?? false;
            if (showPanel) {
              return const SizedBox.shrink();
            }
            return Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: (){
                    _onUserTap();
                  },
                  child: Container(
                      width: 50,height: 50,
                      color: Colors.deepOrangeAccent.withValues(alpha: 0.5),
                      child: const Icon(Icons.upgrade, color: Colors.white)),
                ),
              ),
            );
          }
        ),
        /// Buttons Panel
        SlideTransition(
          position: _offsetAnimation,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              margin: const EdgeInsets.only(left: 12, right: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Logger output
                  StreamBuilder<String>(
                    stream: _loggerStream,
                    builder: (context, snapshot) {
                      String log = snapshot.data ?? '';
                      return debugTapCount == 10
                          ? GestureDetector(
                        onDoubleTapDown: (_) {
                          debugTapCount = 0;
                          setState(() {});
                        },
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
                          child: Text(
                            log,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      )
                          : const SizedBox();
                    },
                  ),

                  /// Volume button
                  StreamBuilder<bool>(
                    stream: _volumeStream,
                    builder: (context, snapshot) {
                      bool soundOn = snapshot.data ?? false;
                      return ElevatedButton.icon(
                        onPressed: () {
                          soundOn ? disableSound() : enableSound();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                        icon: Icon(
                            soundOn ? Icons.volume_up : Icons.volume_off),
                        label:
                        Text(soundOn ? 'Tắt âm thanh' : 'Mở âm thanh'),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  /// Show spots
                  ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        useRootNavigator: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16)),
                        ),
                        builder: (_) => _buildSpotSheet(context),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    icon: const Icon(Icons.map),
                    label: const Text('Hiển thị tuyến đi trong vlog'),
                  ),

                  // const SizedBox(height: 8),
                  //
                  // /// Open VIIV
                  // ElevatedButton.icon(
                  //   onPressed: () {
                  //     js.context.callMethod(
                  //         'openBrowser', ['https://viiv.app']);
                  //   },
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.pinkAccent,
                  //     shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(10)),
                  //     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  //   ),
                  //   icon: const Icon(Icons.open_in_new),
                  //   label: const Text('Xem nhiều vlog hơn tại ViiV'),
                  // ),
                  const SizedBox(height: 8),
                  /// Request feature
                  ElevatedButton.icon(
                    onPressed: () {
                      html.window.parent?.postMessage({
                        'type': 'CONTACT_CALLBACK', // You can customize this
                        'data': 'Flutter iframe button pressed',
                      }, '*'); // Replace '*' with the parent origin for security
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    icon: const Icon(Icons.quick_contacts_dialer_outlined),
                    label: const Text('Liện hệ khi gặp lỗi'),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSpotSheet(BuildContext context) {
    return StatefulBuilder(builder: (context, setState) {
      return StreamBuilder<Spots?>(
        stream: _currentSpot,
        builder: (context, snapshot) {
          final cSpot = snapshot.data;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              controller: scrollController,
              itemCount: widget.video.spots.length,
              itemBuilder: (_, i) {
                final e = widget.video.spots[i];
                final isSelected = cSpot?.id == e.id;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color:
                    isSelected ? Colors.pinkAccent : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    e.addressName?.en ?? '',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    });
  }
}
