import 'package:flutter/material.dart';
import 'package:flutter_portfolio/view/vlog/supabase_video_service.dart';
import 'package:rxdart/rxdart.dart';

import 'feed_response.dart';
import 'feed_service.dart';
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
  final PageController pageController = PageController();
  final BehaviorSubject<List<VideoModel>> videoStream = BehaviorSubject();
  Pagination? pagination;
  final storageService = StorageService();
  List<VideoModel> supaBaseVideos = [];
  bool isOnlyChillVideo = false;
  bool autoPlayNext = false;

  @override
  void initState() {
    isOnlyChillVideo = widget.isPlayChillVideoAtFirst;
    if (isOnlyChillVideo) {
      _fetchSupaBaseVideo().whenComplete(() {
        videoStream.add(supaBaseVideos);
      });
    } else {
      _fetchSupaBaseVideo().whenComplete(() {
        FeedService.fetchFeedVideo(1).then((value) {
          final data = value.results?.map((e) {
            final thumbnail = e.thumbnails?.first.url;
            return VideoModel(
              e.source!.url!,
              thumbnail,
              e.spots ?? [],
              user: e.user,
              name: e.name,
              description: e.description,
              like: e.likeCount,
              view: e.viewCount,
              id: e.id!,
            );
          }).toList() ??
              [];
          videoStream.add(_insertEach5SupaBaseVideo(
              supaBaseVideos, data));
          pagination = value.pagination;
        });
      });
    }
    super.initState();
  }

  Future<void> _fetchSupaBaseVideo() async {
    // Get public URLs
    try {
      final publicUrls =
          await storageService.listBucketUrls(bucketName: 'videos', limit: 500);
      supaBaseVideos = publicUrls.map((url) {
        return VideoModel(
          url,
          null, // Assuming no thumbnail for Supabase videos
          [],
          user: User(
              id: DateTime.now().millisecondsSinceEpoch, nickname: 'Quốc 67k1'),
          // Assuming no user data available
          name: 'Video của Quốc 67K1 chèn test quảng cáo',
          description: 'video quảng cáo chèn vào của quốc',
          like: 9999,
          view: 9999,
          id: DateTime.now().millisecondsSinceEpoch,
        );
      }).toList();
    } catch (e) {
      print('Error fetching public URLs: $e');
    }
  }

  List<VideoModel> _insertEach5SupaBaseVideo(
      List<VideoModel> supaBaseVideos, List<VideoModel> currentVideos) {
    // if one video in current, add 5 supabase videos before it
    if (currentVideos.isEmpty) return supaBaseVideos;
    List<VideoModel> result = [];
    int supaBaseIndex = 0;
    for (int i = 0; i < currentVideos.length; i++) {
      if (i > 0 && i % 5 == 0 && supaBaseIndex < supaBaseVideos.length) {
        result.add(supaBaseVideos[supaBaseIndex]);
        supaBaseIndex++;
      }
      result.add(currentVideos[i]);
    }
    // Add remaining supabase videos if any
    while (supaBaseIndex < supaBaseVideos.length) {
      result.add(supaBaseVideos[supaBaseIndex]);
      supaBaseIndex++;
    }
    return result;
  }

  @override
  void dispose() {
    videoStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              FeedService.fetchFeedVideo(1).then((value) {
                final data = value.results?.map((e) {
                      final thumbnail = e.thumbnails?.first.url;
                      return VideoModel(
                        e.source!.url!,
                        thumbnail,
                        e.spots ?? [],
                        user: e.user,
                        name: e.name,
                        description: e.description,
                        like: e.likeCount,
                        view: e.viewCount,
                        id: e.id!,
                      );
                    }).toList() ??
                    [];
                videoStream
                    .add(_insertEach5SupaBaseVideo(supaBaseVideos, data));
                pagination = value.pagination;
              });
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
                      itemCount: data.length,
                      onPageChanged: (index) {
                        if (index == data.length - 1) {
                          bool canLoadMore = (pagination?.page ?? 0) <
                              (pagination?.pageCount ?? 0);
                          int? currentPage = pagination?.page;
                          if (!canLoadMore || currentPage == null) return;
                          int nextPage = currentPage + 1;
                          FeedService.fetchFeedVideo(nextPage).then((value) {
                            final current = videoStream.valueOrNull ?? [];
                            final newData = value.results?.map((e) {
                                  final thumbnail = e.thumbnails?.first.url;
                                  return VideoModel(
                                    e.source!.url!,
                                    thumbnail,
                                    e.spots ?? [],
                                    user: e.user,
                                    name: e.name,
                                    description: e.description,
                                    like: e.likeCount,
                                    view: e.viewCount,
                                    id: e.id!,
                                  );
                                }).toList() ??
                                [];
                            current.addAll(newData);
                            videoStream.add(_insertEach5SupaBaseVideo(
                                supaBaseVideos, data));
                            pagination = value.pagination;
                          });
                        }
                      },
                      itemBuilder: (_, index) =>
                          VideoItem(video: data.elementAt(index), onVideoEnd: (){
                            if (autoPlayNext) {
                              int nextPage = (pageController.page?.toInt() ?? 0) + 1;
                              if (nextPage < data.length) {
                                pageController.jumpToPage(nextPage);
                              }
                            }
                          }),
                    );
                  }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'CHỈ NGHE VIDEO THƯ GIÃN',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 10),
                    Switch(
                        value: isOnlyChillVideo,
                        onChanged: (value) {
                          setState(() {
                            isOnlyChillVideo = value;
                          });
                          videoStream.add([]);

                          if (isOnlyChillVideo) {
                            supaBaseVideos.shuffle();
                            videoStream.add(supaBaseVideos);
                            pageController.jumpToPage(
                                (pageController.page?.toInt() ?? 0) + 1);
                          } else {
                            _fetchSupaBaseVideo().whenComplete(() {
                              FeedService.fetchFeedVideo(1).then((value) {
                                final data = value.results?.map((e) {
                                      final thumbnail = e.thumbnails?.first.url;
                                      return VideoModel(
                                        e.source!.url!,
                                        thumbnail,
                                        e.spots ?? [],
                                        user: e.user,
                                        name: e.name,
                                        description: e.description,
                                        like: e.likeCount,
                                        view: e.viewCount,
                                        id: e.id!,
                                      );
                                    }).toList() ??
                                    [];
                                videoStream.add(_insertEach5SupaBaseVideo(
                                    supaBaseVideos, data));
                                pagination = value.pagination;
                              });
                            });
                          }
                        }),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'TỰ ĐỘNG PHÁT VIDEO TIẾP THEO',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 10),
                    Switch(
                        value: autoPlayNext,
                        onChanged: (value) {
                          setState(() {
                            autoPlayNext = value;
                          });
                        }),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
