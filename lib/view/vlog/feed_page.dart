import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view/customer_service/src/pages/auth.dart';
import 'package:flutter_portfolio/view/vlog/supabase_video_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'feed_response.dart';
import 'video_item_widget.dart';
import 'video_model.dart';

bool soundState = false;

class FeedPage extends StatefulWidget {
  const FeedPage({Key? key, required this.isPlayChillVideoAtFirst}) : super(key: key);

  final bool isPlayChillVideoAtFirst;
  @override
  State<StatefulWidget> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  static const String _viewType = 'reactjs-vlog-iframe';
  static bool _isFactoryRegistered = false;
  bool _useReactVlog = true; // Default to loading the ReactJS version

  static const String _ownerSupabaseUserId =
      String.fromEnvironment('OWNER_SUPABASE_USER_ID', defaultValue: '');
  static const String _ownerSupabaseEmail =
      String.fromEnvironment('OWNER_SUPABASE_EMAIL', defaultValue: '');
  static const Duration _uploadCooldownDuration = Duration(minutes: 2);
  static const String _uploadCooldownStorageKey = 'vlog_upload_last_at_v1';

  final PageController pageController = PageController();
  final BehaviorSubject<List<VideoModel>> videoStream = BehaviorSubject();
  final storageService = StorageService();
  List<VideoModel> supaBaseVideos = [];
  bool isOnlyChillVideo = true;
  bool autoPlayNext = false;
  bool isUploadingVideo = false;
  bool canCurrentUserUpload = false;
  DateTime? lastUploadAt;
  Timer? _uploadCooldownTimer;
  bool _isLoadingSupaBasePage = false;
  bool _hasMoreSupaBaseVideo = true;
  int _supaBaseOffset = 0;
  static const int _supaBasePageSize = 50;
  int _currentPageIndex = 0;
  StreamSubscription<supa.AuthState>? _authSub;

  void _preloadUpcomingVideos(List<VideoModel> videos, int fromIndex,
      {int count = 2}) {
    if (videos.isEmpty) return;
    final start = fromIndex.clamp(0, videos.length - 1);
    final endExclusive = (start + count).clamp(start, videos.length);
    for (int i = start; i < endExclusive; i++) {
      VideoItem.preloadVideoOnWeb(videos[i].url);
    }
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb && !_isFactoryRegistered) {
      _isFactoryRegistered = true;
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'https://quoc-research-retrogame.web.app/?feature=vlog'
          ..style.border = '0'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'autoplay; fullscreen; gamepad';
        return iframe;
      });
    }
    _bindAuthState();
    _initializeUploadGuard();
    isOnlyChillVideo = widget.isPlayChillVideoAtFirst;
    _fetchSupaBaseVideo(reset: true).whenComplete(() {
      videoStream.add(List<VideoModel>.from(supaBaseVideos));
      _preloadUpcomingVideos(supaBaseVideos, 0, count: 3);
    });
  }

  void _bindAuthState() {
    _authSub = supa.Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (!mounted) return;
      _refreshUploadPermission();
    });
  }

  Future<void> _initializeUploadGuard() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_uploadCooldownStorageKey);
    if (stored != null) {
      lastUploadAt = DateTime.fromMillisecondsSinceEpoch(stored);
      _startUploadCooldownTickerIfNeeded();
    }

    _refreshUploadPermission();
  }

  void _refreshUploadPermission() {
    final hasOwnerConfig =
        _ownerSupabaseUserId.isNotEmpty || _ownerSupabaseEmail.isNotEmpty;
    final allowed = hasOwnerConfig
        ? storageService.isCurrentUserOwner(
            ownerUserId: _ownerSupabaseUserId,
            ownerEmail: _ownerSupabaseEmail,
          )
        : (storageService.currentUserId != null);
    setState(() {
      canCurrentUserUpload = allowed;
    });
  }

  Duration get _remainingUploadCooldown {
    if (lastUploadAt == null) return Duration.zero;
    final elapsed = DateTime.now().difference(lastUploadAt!);
    final remaining = _uploadCooldownDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get _isCooldownActive => _remainingUploadCooldown > Duration.zero;

  String get _cooldownText {
    final remaining = _remainingUploadCooldown;
    if (remaining <= Duration.zero) return '';
    final mm = remaining.inMinutes.toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void _startUploadCooldownTickerIfNeeded() {
    _uploadCooldownTimer?.cancel();
    if (!_isCooldownActive) return;
    _uploadCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_isCooldownActive) {
        timer.cancel();
      }
      setState(() {});
    });
  }

  Future<void> _markUploadCooldownNow() async {
    lastUploadAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_uploadCooldownStorageKey, lastUploadAt!.millisecondsSinceEpoch);
    _startUploadCooldownTickerIfNeeded();
  }

  VideoModel _toSupabaseVideo(String url, {String uploaderName = 'Quốc 67k1'}) {
    return VideoModel(
      url,
      null,
      [],
      user: User(
          id: DateTime.now().millisecondsSinceEpoch, nickname: uploaderName),
      name: 'Video của Quốc 67K1 chèn test quảng cáo',
      description: 'video quảng cáo chèn vào của quốc',
      like: 9999,
      view: 9999,
      id: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _fetchSupaBaseVideo({bool reset = false}) async {
    if (_isLoadingSupaBasePage) return;
    if (reset) {
      _supaBaseOffset = 0;
      _hasMoreSupaBaseVideo = true;
      supaBaseVideos = [];
    }
    if (!_hasMoreSupaBaseVideo) return;

    _isLoadingSupaBasePage = true;
    try {
      final entries = await storageService.listBucketVideoEntries(
        bucketName: 'videos',
        limit: _supaBasePageSize,
        offset: _supaBaseOffset,
      );

      if (entries.isEmpty) {
        _hasMoreSupaBaseVideo = false;
        return;
      }

      _supaBaseOffset += entries.length;
      if (entries.length < _supaBasePageSize) {
        _hasMoreSupaBaseVideo = false;
      }
      final loadedPage = ((_supaBaseOffset - 1) ~/ _supaBasePageSize) + 1;
      debugPrint(
          '[VLOG][SUPABASE] page=$loadedPage loaded=${entries.length} pageSize=$_supaBasePageSize hasMore=$_hasMoreSupaBaseVideo totalLoaded=$_supaBaseOffset');

      final newVideos = entries
        .map((e) => _toSupabaseVideo(e.publicUrl, uploaderName: e.uploaderName))
        .toList()
        ..shuffle();
      supaBaseVideos.addAll(newVideos);
    } catch (e) {
      print('Error fetching public URLs: $e');
    } finally {
      _isLoadingSupaBasePage = false;
    }
  }

  Future<void> _loadMoreSupabaseForChillModeIfNeeded(int index) async {
    final current = videoStream.valueOrNull ?? [];
    if (current.isEmpty) return;

    // Prefetch next page when user is near the end.
    if (index < current.length - 3) return;

    final oldLength = supaBaseVideos.length;
    await _fetchSupaBaseVideo();
    if (!mounted || supaBaseVideos.length == oldLength) return;

    videoStream.add(List<VideoModel>.from(supaBaseVideos));
    _preloadUpcomingVideos(videoStream.valueOrNull ?? [], index + 1, count: 3);
  }

  Future<void> _pickAndUploadVideo() async {
    if (isUploadingVideo) return;

    final currentUser = supa.Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      await showDialog(
          context: context,
          builder: (_) {
            return const AlertDialog(
              backgroundColor: Colors.transparent,
              content: AuthScreen(),
              contentPadding: EdgeInsets.all(0),
            );
          });
      _refreshUploadPermission();
      return;
    }

    if (!canCurrentUserUpload) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chỉ chủ tài khoản mới được thêm video')),
        );
      }
      return;
    }
    if (_isCooldownActive) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng chờ $_cooldownText trước khi thêm video tiếp theo')),
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: const ['mp4', 'mov', 'm4v', 'webm'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không đọc được dữ liệu video để upload')),
        );
      }
      return;
    }

    setState(() => isUploadingVideo = true);
    try {
      final uploaderName = _currentUploaderName(currentUser);
      final publicUrl = await storageService.uploadVideoBytes(
        bucketName: 'videos',
        bytes: bytes,
        originalFileName: file.name,
        uploaderName: uploaderName,
        uploaderUserId: currentUser.id,
      );
      final uploadedVideo = _toSupabaseVideo(publicUrl, uploaderName: uploaderName);
      supaBaseVideos.insert(0, uploadedVideo);

      final current = videoStream.valueOrNull ?? [];
      final next = List<VideoModel>.from(current);
      next.insert(0, uploadedVideo);
      videoStream.add(next);
      await _markUploadCooldownNow();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thêm video thành công: ${file.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isUploadingVideo = false);
      }
    }
  }

  String _currentUploaderName(supa.User user) {
    final metadata = user.userMetadata;
    final first = (metadata?['first_name'] as String?)?.trim() ?? '';
    final last = (metadata?['last_name'] as String?)?.trim() ?? '';
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;

    final email = user.email ?? '';
    if (email.contains('@')) {
      return email.split('@').first;
    }
    return 'Người dùng';
  }

  Widget _buildControlPanel(BuildContext context) {
    return const SizedBox.shrink();
    // return Align(
    //   alignment: Alignment.topRight,
    //   child: Padding(
    //     padding: const EdgeInsets.all(10),
    //     child: ConstrainedBox(
    //       constraints: const BoxConstraints(maxWidth: 520),
    //       child: Container(
    //         decoration: BoxDecoration(
    //           color: Colors.black.withValues(alpha: 0.55),
    //           borderRadius: BorderRadius.circular(16),
    //           border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
    //           boxShadow: [
    //             BoxShadow(
    //               color: Colors.black.withValues(alpha: 0.25),
    //               blurRadius: 18,
    //               offset: const Offset(0, 8),
    //             ),
    //           ],
    //         ),
    //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    //         child: Column(
    //           mainAxisSize: MainAxisSize.min,
    //           children: [
    //             Row(
    //               children: [
    //                 Expanded(
    //                   child: ElevatedButton.icon(
    //                     onPressed: canUploadNow ? _pickAndUploadVideo : null,
    //                     icon: isUploadingVideo
    //                         ? const SizedBox(
    //                             width: 16,
    //                             height: 16,
    //                             child: CircularProgressIndicator(strokeWidth: 2),
    //                           )
    //                         : const Icon(Icons.video_call),
    //                     label: Text(isUploadingVideo
    //                         ? 'ĐANG THÊM VIDEO...'
    //                         : _isCooldownActive
    //                             ? 'THÊM VIDEO ($_cooldownText)'
    //                             : 'THÊM VIDEO'),
    //                   ),
    //                 ),
    //               ],
    //             ),
    //             const SizedBox(height: 8),
    //             // Row(
    //             //   children: [
    //             //     const Expanded(
    //             //       child: Text(
    //             //         'CHỈ NGHE VIDEO THƯ GIÃN',
    //             //         style: TextStyle(
    //             //           color: Colors.white,
    //             //           fontWeight: FontWeight.w700,
    //             //         ),
    //             //       ),
    //             //     ),
    //             //     Switch(
    //             //         value: isOnlyChillVideo,
    //             //         onChanged: (value) {
    //             //           setState(() {
    //             //             isOnlyChillVideo = value;
    //             //           });
    //             //           videoStream.add([]);
    //             //
    //             //           if (isOnlyChillVideo) {
    //             //             supaBaseVideos.shuffle();
    //             //             videoStream.add(supaBaseVideos);
    //             //             _preloadUpcomingVideos(supaBaseVideos, 0, count: 3);
    //             //             pageController.jumpToPage(
    //             //                 (pageController.page?.toInt() ?? 0) + 1);
    //             //           } else {
    //             //             _fetchSupaBaseVideo(reset: true).whenComplete(() {
    //             //               FeedService.fetchFeedVideo(1).then((value) {
    //             //                 final data = value.results?.map((e) {
    //             //                       final thumbnail = e.thumbnails?.first.url;
    //             //                       return VideoModel(
    //             //                         e.source!.url!,
    //             //                         thumbnail,
    //             //                         e.spots ?? [],
    //             //                         user: e.user,
    //             //                         name: e.name,
    //             //                         description: e.description,
    //             //                         like: e.likeCount,
    //             //                         view: e.viewCount,
    //             //                         id: e.id!,
    //             //                       );
    //             //                     }).toList() ??
    //             //                     [];
    //             //                 videoStream.add(_insertEach5SupaBaseVideo(
    //             //                     supaBaseVideos, data));
    //             //                 _preloadUpcomingVideos(
    //             //                     videoStream.valueOrNull ?? [], 0,
    //             //                     count: 3);
    //             //                 pagination = value.pagination;
    //             //               });
    //             //             });
    //             //           }
    //             //         }),
    //             //   ],
    //             // ),
    //             // Row(
    //             //   children: [
    //             //     const Expanded(
    //             //       child: Text(
    //             //         'TỰ ĐỘNG PHÁT VIDEO TIẾP THEO',
    //             //         style: TextStyle(
    //             //           color: Colors.white,
    //             //           fontWeight: FontWeight.w700,
    //             //         ),
    //             //       ),
    //             //     ),
    //             //     Switch(
    //             //         value: autoPlayNext,
    //             //         onChanged: (value) {
    //             //           setState(() {
    //             //             autoPlayNext = value;
    //             //           });
    //             //         }),
    //             //   ],
    //             // ),
    //             Align(
    //               alignment: Alignment.centerLeft,
    //               child: Text(
    //                 canCurrentUserUpload
    //                     ? (_isCooldownActive
    //                         ? 'Bạn có thể thêm video tiếp theo sau $_cooldownText'
    //                         : 'Bạn có quyền thêm video')
    //                     : 'Chỉ tài khoản của bạn mới được thêm video',
    //                 style: TextStyle(
    //                   color: Colors.white.withValues(alpha: 0.8),
    //                   fontSize: 12,
    //                 ),
    //               ),
    //             ),
    //           ],
    //         ),
    //       ),
    //     ),
    //   ),
    // );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _uploadCooldownTimer?.cancel();
    videoStream.close();
    super.dispose();
  }

  Widget _buildVersionSelector() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSelectorTab(
              title: '⚡ ReactJS (Mượt mà)',
              isActive: _useReactVlog,
              onTap: () {
                setState(() {
                  _useReactVlog = true;
                });
              },
            ),
            _buildSelectorTab(
              title: '💙 Canvaskit (Native)',
              isActive: !_useReactVlog,
              onTap: () {
                setState(() {
                  _useReactVlog = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorTab({required String title, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    
    if (_useReactVlog && kIsWeb) {
      content = const SizedBox.expand(
        child: HtmlElementView(viewType: _viewType),
      );
    } else {
      content = Scaffold(
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await _fetchSupaBaseVideo(reset: true);
                videoStream.add(List<VideoModel>.from(supaBaseVideos));
                _preloadUpcomingVideos(videoStream.valueOrNull ?? [], 0,
                    count: 3);
              },
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: StreamBuilder<List<VideoModel>>(
                    stream: videoStream,
                    builder: (context, snapshot) {
                      final data = snapshot.data ?? [];
                      return PageView.builder(
                        controller: pageController,
                        scrollDirection: Axis.vertical,
                        allowImplicitScrolling: true,
                        itemCount: data.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPageIndex = index;
                          });
                          _preloadUpcomingVideos(data, index + 1);
                          _loadMoreSupabaseForChillModeIfNeeded(index);
                        },
                        itemBuilder: (_, index) {
                          final canAddVideoNow = !isUploadingVideo;
                          final addVideoLabel = isUploadingVideo
                              ? 'ĐANG THÊM...'
                              : _isCooldownActive
                                  ? 'THÊM VIDEO ($_cooldownText)'
                                  : 'THÊM VIDEO';

                          return VideoItem(
                            video: data.elementAt(index),
                            autoPlayNext: autoPlayNext,
                            isCurrentPage: index == _currentPageIndex,
                            showAddVideoButton: true,
                            canAddVideo: canAddVideoNow,
                            isAddVideoLoading: isUploadingVideo,
                            addVideoLabel: addVideoLabel,
                            onAddVideoTap: _pickAndUploadVideo,
                            onVideoEnd: () {
                              if (autoPlayNext) {
                                int nextPage = index + 1;
                                if (nextPage < data.length) {
                                  pageController.animateToPage(
                                    nextPage,
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeOut,
                                  );
                                }
                              }
                            },
                          );
                        },
                      );
                    }),
              ),
            ),
            _buildControlPanel(context)
          ],
        ),
      );
    }

    return Stack(
      children: [
        content,
        _buildVersionSelector(),
      ],
    );
  }
}



