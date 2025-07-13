import 'dart:convert';

import 'package:flutter_portfolio/view/vlog/hotel_response.dart';
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

  static Future<List<HotelResponse>?> fetchHotelByVideoId(int videoId) async {
    final url =
        'https://api-prod.viiv.ai/videos/$videoId/places?type=hotel&language=ko';
    var response = await http.get(Uri.parse(url));
    try {
      print('Fetching hotel data for video ID: $videoId from $url');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        List result = jsonDecode(response.body) as List;
        print('Parsed hotel data: $result');
        return result.map((e) => HotelResponse.fromJson(e)).toList(); // <-- FIXED
      } else {
        return null;
      }
    } catch (e) {
      print('Error parsing hotel response: $e');
      return null;
    }
  }

}
