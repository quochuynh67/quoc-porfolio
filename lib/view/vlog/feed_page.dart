import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'feed_response.dart';
import 'feed_service.dart';
import 'video_item_widget.dart';
import 'video_model.dart';

bool soundState = false;

class FeedPage extends StatefulWidget {
  const FeedPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final PageController pageController = PageController();
  final BehaviorSubject<List<VideoModel>> videoStream = BehaviorSubject();
  Pagination? pagination;

  @override
  void initState() {
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
      videoStream.add(data);
      pagination = value.pagination;
    });
    super.initState();
  }

  @override
  void dispose() {
    videoStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
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
            videoStream.add(data);
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
                        videoStream.add(current);
                        pagination = value.pagination;
                      });
                    }
                  },
                  itemBuilder: (_, index) =>
                      VideoItem(video: data.elementAt(index)),
                );
              }),
        ),
      ),
    );
  }
}
