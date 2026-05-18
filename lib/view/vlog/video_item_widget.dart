import 'dart:async';
import 'dart:ui';

import 'dart:js' as js;
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view/vlog/feed_service.dart';
import 'package:flutter_portfolio/view/vlog/hotel_response.dart';
import 'package:rxdart/rxdart.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'feed_page.dart';
import 'feed_response.dart';
import 'video_model.dart';

class VideoItem extends StatefulWidget {
  static final Map<String, html.VideoElement> _webPreloadPool = {};
  static const int _maxPreloadedVideos = 8;

  /// Lightweight preload for web iframe/mobile: fetches video metadata and keeps
  /// a small rolling pool so next swipe starts faster.
  static void preloadVideoOnWeb(String? url) {
    if (url == null || url.isEmpty || _webPreloadPool.containsKey(url)) return;
    final video = html.VideoElement()
      ..src = url
      ..preload = 'metadata'
      ..muted = true;
    video.setAttribute('playsinline', 'true');
    video.load();
    _webPreloadPool[url] = video;

    if (_webPreloadPool.length > _maxPreloadedVideos) {
      final firstKey = _webPreloadPool.keys.first;
      final oldVideo = _webPreloadPool.remove(firstKey);
      oldVideo?.removeAttribute('src');
      oldVideo?.load();
    }
  }

  const VideoItem({
    Key? key,
    required this.video,
    required this.autoPlayNext,
    this.onVideoEnd,
    this.onAddVideoTap,
    this.showAddVideoButton = false,
    this.canAddVideo = false,
    this.isAddVideoLoading = false,
    this.addVideoLabel = 'THÊM VIDEO',
  }) : super(key: key);
  final VideoModel video;
  final bool autoPlayNext;
  final VoidCallback? onVideoEnd;
  final VoidCallback? onAddVideoTap;
  final bool showAddVideoButton;
  final bool canAddVideo;
  final bool isAddVideoLoading;
  final String addVideoLabel;
  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  static VideoPlayerController? _activeController;
  static String? _activeVideoKey;

  VideoPlayerController? videoController;
  bool disposed = false;
  bool videoInitialized = false;
  bool autoPlayNext = false;
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
  final BehaviorSubject<List<HotelResponse>> _hotelResponse = BehaviorSubject();
  final BehaviorSubject<bool> _isFetchingHotel = BehaviorSubject();
  final ScrollController scrollController = ScrollController();
  bool _isVisibleEnoughToPlay = true;
  bool _hasNotifiedVideoEnd = false;

  String get _videoKey => '${widget.video.id}-${widget.video.url}';

  ButtonStyle _panelButtonStyle(Color backgroundColor,
      {Color foregroundColor = Colors.white}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }

  TextStyle get _panelButtonTextStyle => const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        shadows: [
          Shadow(
            color: Colors.black87,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      );

  void _playAsActive() {
    final controller = videoController;
    if (controller == null) return;

    if (_activeController != null &&
        !identical(_activeController, controller) &&
        _activeController!.value.isPlaying) {
      try {
        _activeController?.pause();
      } catch (_) {
        // Ignore pause failures from disposed/invalid previous controllers.
      }
    }

    _activeController = controller;
    _activeVideoKey = _videoKey;
    controller.play();
  }

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
    VideoItem.preloadVideoOnWeb(widget.video.url);
    _initVideoController();
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (videoInitialized == false ||
          videoController?.value.isInitialized == false) {
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
      end: const Offset(0, 0), // visible
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

    if (soundState) {
      _onUserTap();
    } else {
      // Keep controls visible initially when muted, then auto-hide after 7s.
      _onUserTap();
    }
  }

  @override
  void didUpdateWidget(covariant VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoPlayNext != widget.autoPlayNext) {
      videoController?.setLooping(!widget.autoPlayNext);
    }
  }

  void _initVideoController() {
    videoController = VideoPlayerController.networkUrl(
            Uri.parse(widget.video.url),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true))
          ..initialize().then((_) {
            if (!mounted || disposed) return;
            setState(() {});
            videoController?.setLooping(!widget.autoPlayNext);
            videoInitialized = true;
            videoController?.addListener(_listenVideoValue);
            setState(() {});
            if (_isVisibleEnoughToPlay) {
              _playAsActive();
            }
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
    if (identical(_activeController, videoController) || _activeVideoKey == _videoKey) {
      _activeController = null;
      _activeVideoKey = null;
    }
    videoController?.removeListener(_listenVideoValue);
    videoController?.dispose();
    _currentSpot.close();
    _volumeStream.close();
    _loggerStream.close();
    _showButtonPanel.close();
    _timer?.cancel();
    _hidePanelTimer?.cancel();
    disposed = true;
    _hotelResponse.close();
    _isFetchingHotel.close();
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
    final duration = videoController?.value.duration ?? Duration.zero;
    final spot = findClosestSpot(_spots, videoPosition.inSeconds.toDouble());
    _currentSpot.add(spot);

    if (videoController?.value.isInitialized == true &&
        duration > Duration.zero &&
        videoPosition >= duration - const Duration(milliseconds: 250)) {
      if (_hasNotifiedVideoEnd) return;
      _hasNotifiedVideoEnd = true;
      widget.onVideoEnd?.call();
    } else {
      _hasNotifiedVideoEnd = false;
    }
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
      _playAsActive();
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

    User? user = widget.video.user;
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
                    key: Key('video-${widget.video.id}-${widget.video.url}'),
                    onVisibilityChanged: (VisibilityInfo info) {
                      if (disposed) return;
                      final visibleFraction = info.visibleFraction;

                      // Hysteresis avoids rapid pause/play toggles while swiping.
                      if (visibleFraction < 0.35) {
                        _isVisibleEnoughToPlay = false;
                        videoController?.pause();
                      } else if (visibleFraction > 0.7) {
                        _isVisibleEnoughToPlay = true;
                        _playAsActive();
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
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      _onUserTap();
                    },
                    child: Container(
                        width: 50,
                        height: 50,
                        color: Colors.deepOrangeAccent.withValues(alpha: 0.5),
                        child: const Icon(Icons.upgrade, color: Colors.white)),
                  ),
                ),
              );
            }),
        if (user != null)
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.thumb_up, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('${widget.video.like ?? 0}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.remove_red_eye,
                                color: Colors.white),
                            const SizedBox(width: 4),
                            Text('${widget.video.view ?? 0}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16)),
                          ],
                        ),
                      ),
                      Image.network(user.photoURL ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover, errorBuilder: (_, __, ___) {
                        return const Icon(Icons.person,
                            size: 50, color: Colors.white);
                      }),
                    ],
                  ),
                  Text('${user.nickname}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),

        /// Buttons Panel
        SlideTransition(
          position: _offsetAnimation,
          child: Align(
            alignment: Alignment.bottomRight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  margin: const EdgeInsets.only(left: 12, right: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0.07),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showAddVideoButton) ...[
                    ElevatedButton.icon(
                      onPressed: (widget.canAddVideo && !widget.isAddVideoLoading)
                          ? widget.onAddVideoTap
                          : null,
                      style: _panelButtonStyle(
                        Colors.cyanAccent.withValues(alpha: 0.95),
                        foregroundColor: Colors.black,
                      ),
                      icon: widget.isAddVideoLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.video_call),
                      label: Text(widget.addVideoLabel,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 8),
                  ],

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
                                color: Colors.black.withValues(alpha: 0.5),
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
                        style: _panelButtonStyle(Colors.green),
                        icon: Icon(soundOn ? Icons.volume_up : Icons.volume_off,
                            color: Colors.white),
                        label: Text(soundOn ? 'Tắt âm thanh' : 'Mở âm thanh',
                            style: _panelButtonTextStyle),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  /// Find hotel
                  StreamBuilder<bool>(
                      stream: _isFetchingHotel,
                      builder: (context, snapshot) {
                        bool isFetching = snapshot.data ?? false;
                        return ElevatedButton.icon(
                          onPressed: () {
                            if (isFetching) return;
                            _isFetchingHotel.add(true);
                            FeedService.fetchHotelByVideoId(widget.video.id)
                                .then((response) {
                              if (context.mounted) {
                                if (response != null) {
                                  _hotelResponse.add(response);
                                  showModalBottomSheet(
                                    context: context,
                                    useRootNavigator: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                    ),
                                    builder: (_) => _buildHotelSheet(context),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Không tìm thấy khách sạn'),
                                    ),
                                  );
                                }
                              }
                              _isFetchingHotel.add(false);
                            }).whenComplete(() {
                              _isFetchingHotel.add(false);
                            });
                          },
                          style: _panelButtonStyle(Colors.green),
                          icon: isFetching
                              ? const CircularProgressIndicator()
                              : const Icon(Icons.home, color: Colors.white),
                          label: Text(
                              isFetching
                                  ? 'Đang tìm kiếm '
                                  : 'Tìm chỗ ở gần video',
                              style: _panelButtonTextStyle),
                        );
                      }),
                  const SizedBox(height: 8),

                  /// Name desc
                  ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        useRootNavigator: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (_) => _buildVideoNameDescSheet(context),
                      );
                    },
                    style: _panelButtonStyle(Colors.blueAccent.shade700),
                    icon: const Icon(Icons.perm_media, color: Colors.white),
                    label: Text(
                      'Mô tả về video',
                      style: _panelButtonTextStyle,
                    ),
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
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (_) => _buildSpotSheet(context),
                      );
                    },
                    style: _panelButtonStyle(Colors.amber.shade700),
                    icon: const Icon(Icons.map, color: Colors.white),
                    label: Text(
                      'Hiển thị vị trí trong vlog',
                      style: _panelButtonTextStyle,
                    ),
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
                    style: _panelButtonStyle(
                      Colors.greenAccent.shade400,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.quick_contacts_dialer_outlined),
                    label: Text(
                      'Liện hệ khi gặp lỗi',
                      style: _panelButtonTextStyle.copyWith(color: Colors.black87),
                    ),
                  ),
                ],
              ),
                ),
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
                  child: Row(
                    children: [
                      Image.network(
                        e.thumbnail?.url ?? '',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          e.addressName?.en ?? '',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    });
  }

  Widget _buildVideoNameDescSheet(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video.name ?? '',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                widget.video.description ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelSheet(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<List<HotelResponse>>(
        stream: _hotelResponse,
        builder: (context, snapshot) {
          final hotelResponse = snapshot.data;
          if (hotelResponse == null) {
            return const Center(child: Text('Không có thông tin khách sạn'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Khách sạn gần video: ${widget.video.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: hotelResponse.isEmpty
                    ? const Text('Không tìm thấy khách sạn gần video này',
                        style: TextStyle(fontSize: 16, color: Colors.red))
                    : ListView.builder(
                        itemCount: hotelResponse.length,
                        itemBuilder: (context, index) {
                          final hotel = hotelResponse[index];
                          final imageUrl = hotel.photos.isNotEmpty
                              ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${hotel.photos.first.referenceId}&key=YOUR_GOOGLE_MAPS_API_KEY'
                              : null;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (imageUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imageUrl,
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, progress) =>
                                                progress == null
                                                    ? child
                                                    : const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Text(
                                    hotel.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    hotel.formattedAddress,
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 16),
                                      const SizedBox(width: 6),
                                      Text(hotel.phoneNumber),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (hotel.website != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.link, size: 16),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            hotel.website!,
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 8),
                                  if (hotel.product != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.attach_money,
                                            size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${hotel.product!.price.toString()} ${hotel.product!.currency}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          size: 16, color: Colors.orange),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${hotel.rating} (${hotel.userRatingsTotal} đánh giá)',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
