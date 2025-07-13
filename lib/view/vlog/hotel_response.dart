class HotelResponse {
  final List<int> spotIds;
  final StatusWithMe statusWithMe;
  final List<TypeGroup> typeGroup;
  final List<String> types;
  final String placeId;
  final String name;
  final String address;
  final String longAddress;
  final String formattedAddress;
  final String phoneNumber;
  final String intlPhoneNumber;
  final List<Photo> photos;
  final double rating;
  final int userRatingsTotal;
  final bool hasReview;
  final Location location;
  final String? website;
  final Product? product;

  HotelResponse({
    required this.spotIds,
    required this.statusWithMe,
    required this.typeGroup,
    required this.types,
    required this.placeId,
    required this.name,
    required this.address,
    required this.longAddress,
    required this.formattedAddress,
    required this.phoneNumber,
    required this.intlPhoneNumber,
    required this.photos,
    required this.rating,
    required this.userRatingsTotal,
    required this.hasReview,
    required this.location,
    this.website,
    this.product,
  });

  factory HotelResponse.fromJson(Map<String, dynamic> json) {
    return HotelResponse(
      spotIds: List<int>.from(json['spot_ids']),
      statusWithMe: StatusWithMe.fromJson(json['status_with_me']),
      typeGroup: (json['type_group'] as List)
          .map((e) => TypeGroup.fromJson(e))
          .toList(),
      types: List<String>.from(json['types']),
      placeId: json['place_id'],
      name: json['name'],
      address: json['address'],
      longAddress: json['long_address'],
      formattedAddress: json['formatted_address'],
      phoneNumber: json['phone_number'],
      intlPhoneNumber: json['intl_phone_number'],
      photos:
      (json['photos'] as List).map((e) => Photo.fromJson(e)).toList(),
      rating: (json['rating'] as num).toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      hasReview: json['has_review'],
      location: Location.fromJson(json['location']),
      website: json['website'],
      product: json['product'] != null
          ? Product.fromJson(json['product'])
          : null,
    );
  }
}

class StatusWithMe {
  final bool bookmarked;

  StatusWithMe({required this.bookmarked});

  factory StatusWithMe.fromJson(Map<String, dynamic> json) {
    return StatusWithMe(bookmarked: json['bookmarked']);
  }
}

class TypeGroup {
  final String type;
  final String group;
  final Label label;
  final int order;

  TypeGroup({
    required this.type,
    required this.group,
    required this.label,
    required this.order,
  });

  factory TypeGroup.fromJson(Map<String, dynamic> json) {
    return TypeGroup(
      type: json['type'],
      group: json['group'],
      label: Label.fromJson(json['label']),
      order: json['order'],
    );
  }
}

class Photo {
  final String referenceId;

  Photo({required this.referenceId});

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(referenceId: json['reference_id']);
  }
}

class Location {
  final double lat;
  final double lng;

  Location({required this.lat, required this.lng});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

class Product {
  final int productId;
  final int productType;
  final String? productLabel;
  final String areaLabel;
  final String rank;
  final String clickUrl;
  final int price;
  final String currency;

  Product({
    required this.productId,
    required this.productType,
    this.productLabel,
    required this.areaLabel,
    required this.rank,
    required this.clickUrl,
    required this.price,
    required this.currency,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['product_id'],
      productType: json['product_type'],
      productLabel: json['product_label'],
      areaLabel: json['area_label'],
      rank: json['rank'],
      clickUrl: json['click_url'],
      price: json['price'],
      currency: json['currency'],
    );
  }
}


class Label {
  final String en;
  final String ja;
  final String ko;

  Label({
    required this.en,
    required this.ja,
    required this.ko,
  });

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      en: json['en'],
      ja: json['ja'],
      ko: json['ko'],
    );
  }
}