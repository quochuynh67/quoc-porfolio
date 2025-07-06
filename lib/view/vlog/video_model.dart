import 'feed_response.dart';

class VideoModel {
  String url;
  String? thumbnail;
  List<Spots> spots;
  VideoModel(this.url, this.thumbnail, this.spots);
}