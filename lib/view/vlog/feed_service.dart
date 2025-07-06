import 'dart:convert';

import 'package:http/http.dart' as http;

import 'feed_response.dart';

class FeedService {
  static const String koreanVideoEndpoint =
      'https://api-prod.viiv.ai/v2/videos?isCount=true&type=filter_mix_trending';

  static Future<FeedResponse> fetchFeedVideo(int page,
      {int pageSize = 15}) async {
    final url = '$koreanVideoEndpoint&page=$page&pageSize=$pageSize';
    var response = await http.get(Uri.parse(url));
    return FeedResponse.fromJson(jsonDecode(response.body));
  }
}

