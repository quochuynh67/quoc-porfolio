import 'feed_response.dart';

class VideoModel {
  int id;
  String url;
  String? thumbnail;
  List<Spots> spots;
  User? user;
  String? name;
  String? description;
  int? like;
  int? view;
  VideoModel(this.url, this.thumbnail, this.spots, {
    this.user,
    this.name,
    this.description,
    this.like,
    this.view,
    required this.id,
  });
}


class HotelModel {
  
}