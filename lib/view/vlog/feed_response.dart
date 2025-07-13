class FeedResponse {
  List<Results>? results;
  Pagination? pagination;

  FeedResponse({this.results, this.pagination});

  FeedResponse.fromJson(Map<String, dynamic> json) {
    if (json['results'] != null) {
      results = <Results>[];
      json['results'].forEach((v) {
        results!.add(new Results.fromJson(v));
      });
    }
    pagination = json['pagination'] != null
        ? new Pagination.fromJson(json['pagination'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.results != null) {
      data['results'] = this.results!.map((v) => v.toJson()).toList();
    }
    if (this.pagination != null) {
      data['pagination'] = this.pagination!.toJson();
    }
    return data;
  }
}

class Results {
  int? id;
  User? user;
  String? name;
  String? status;
  int? likeCount;
  int? viewCount;
  int? resourceCount;
  int? commentCount;
  String? resource;
  int? scrapVideo;
  int? duration;
  String? publishedAt;
  String? createdAt;
  String? updatedAt;
  String? language;
  String? description;
  String? phase;
  String? unblockedAt;
  int? placeCount;
  Source? source;
  List<Thumbnails>? thumbnails;
  List<Tags>? tags;
  List<Categories>? categories;
  List<Spots>? spots;

  Results(
      {this.id,
        this.user,
        this.name,
        this.status,
        this.likeCount,
        this.viewCount,
        this.resourceCount,
        this.commentCount,
        this.resource,
        this.scrapVideo,
        this.duration,
        this.publishedAt,
        this.createdAt,
        this.updatedAt,
        this.language,
        this.description,
        this.phase,
        this.unblockedAt,
        this.placeCount,
        this.source,
        this.thumbnails,
        this.tags,
        this.categories,
        this.spots});

  Results.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
    name = json['name'];
    status = json['status'];
    likeCount = json['likeCount'];
    viewCount = json['viewCount'];
    resourceCount = json['resourceCount'];
    commentCount = json['commentCount'];
    resource = json['resource'];
    scrapVideo = json['scrapVideo'];
    duration = json['duration'];
    publishedAt = json['publishedAt'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    language = json['language'];
    description = json['description'];
    phase = json['phase'];
    unblockedAt = json['unblocked_at'];
    placeCount = json['place_count'];
    source =
    json['source'] != null ? new Source.fromJson(json['source']) : null;
    if (json['thumbnails'] != null) {
      thumbnails = <Thumbnails>[];
      json['thumbnails'].forEach((v) {
        thumbnails!.add(new Thumbnails.fromJson(v));
      });
    }
    if (json['tags'] != null) {
      tags = <Tags>[];
      json['tags'].forEach((v) {
        tags!.add(new Tags.fromJson(v));
      });
    }
    if (json['categories'] != null) {
      categories = <Categories>[];
      json['categories'].forEach((v) {
        categories!.add(new Categories.fromJson(v));
      });
    }
    if (json['spots'] != null) {
      spots = <Spots>[];
      json['spots'].forEach((v) {
        spots!.add(new Spots.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    data['name'] = this.name;
    data['status'] = this.status;
    data['likeCount'] = this.likeCount;
    data['viewCount'] = this.viewCount;
    data['resourceCount'] = this.resourceCount;
    data['commentCount'] = this.commentCount;
    data['resource'] = this.resource;
    data['scrapVideo'] = this.scrapVideo;
    data['duration'] = this.duration;
    data['publishedAt'] = this.publishedAt;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['language'] = this.language;
    data['description'] = this.description;
    data['phase'] = this.phase;
    data['unblocked_at'] = this.unblockedAt;
    data['place_count'] = this.placeCount;
    if (this.source != null) {
      data['source'] = this.source!.toJson();
    }
    if (this.thumbnails != null) {
      data['thumbnails'] = this.thumbnails!.map((v) => v.toJson()).toList();
    }
    if (this.tags != null) {
      data['tags'] = this.tags!.map((v) => v.toJson()).toList();
    }
    if (this.categories != null) {
      data['categories'] = this.categories!.map((v) => v.toJson()).toList();
    }
    if (this.spots != null) {
      data['spots'] = this.spots!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class User {
  int? id;
  String? nickname;
  String? photoURL;
  StatusWithMe? statusWithMe;

  User({this.id, this.nickname, this.photoURL, this.statusWithMe});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nickname = json['nickname'];
    photoURL =json['avatar']?['url'] ?? json['photoURL'];
    statusWithMe = json['statusWithMe'] != null
        ? new StatusWithMe.fromJson(json['statusWithMe'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['nickname'] = this.nickname;
    data['photoURL'] = this.photoURL;
    if (this.statusWithMe != null) {
      data['statusWithMe'] = this.statusWithMe!.toJson();
    }
    return data;
  }
}

class StatusWithMe {
  bool? following;
  bool? follower;
  bool? blocking;
  bool? blocker;

  StatusWithMe({this.following, this.follower, this.blocking, this.blocker});

  StatusWithMe.fromJson(Map<String, dynamic> json) {
    following = json['following'];
    follower = json['follower'];
    blocking = json['blocking'];
    blocker = json['blocker'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['following'] = this.following;
    data['follower'] = this.follower;
    data['blocking'] = this.blocking;
    data['blocker'] = this.blocker;
    return data;
  }
}

class Source {
  int? id;
  String? url;
  String? streamUrl;
  ResponsiveUrl? responsiveUrl;
  int? scaleWidth;
  int? scaleHeight;

  Source(
      {this.id,
        this.url,
        this.streamUrl,
        this.responsiveUrl,
        this.scaleWidth,
        this.scaleHeight});

  Source.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    url = json['url'];
    streamUrl = json['streamUrl'];
    responsiveUrl = json['responsiveUrl'] != null
        ? new ResponsiveUrl.fromJson(json['responsiveUrl'])
        : null;
    scaleWidth = json['scaleWidth'];
    scaleHeight = json['scaleHeight'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['url'] = this.url;
    data['streamUrl'] = this.streamUrl;
    if (this.responsiveUrl != null) {
      data['responsiveUrl'] = this.responsiveUrl!.toJson();
    }
    data['scaleWidth'] = this.scaleWidth;
    data['scaleHeight'] = this.scaleHeight;
    return data;
  }
}

class ResponsiveUrl {
  Medium? medium;
  Medium? low;
  Medium? high;

  ResponsiveUrl({this.medium, this.low, this.high});

  ResponsiveUrl.fromJson(Map<String, dynamic> json) {
    medium =
    json['medium'] != null ? new Medium.fromJson(json['medium']) : null;
    low = json['low'] != null ? new Medium.fromJson(json['low']) : null;
    high = json['high'] != null ? new Medium.fromJson(json['high']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.medium != null) {
      data['medium'] = this.medium!.toJson();
    }
    if (this.low != null) {
      data['low'] = this.low!.toJson();
    }
    if (this.high != null) {
      data['high'] = this.high!.toJson();
    }
    return data;
  }
}

class Medium {
  String? url;

  Medium({this.url});

  Medium.fromJson(Map<String, dynamic> json) {
    url = json['url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['url'] = this.url;
    return data;
  }
}

class Thumbnails {
  int? id;
  Formats? formats;
  String? url;
  String? streamUrl;
  String? responsiveUrl;

  Thumbnails(
      {this.id, this.formats, this.url, this.streamUrl, this.responsiveUrl});

  Thumbnails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    formats =
    json['formats'] != null ? new Formats.fromJson(json['formats']) : null;
    url = json['url'];
    streamUrl = json['streamUrl'];
    responsiveUrl = json['responsiveUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    if (this.formats != null) {
      data['formats'] = this.formats!.toJson();
    }
    data['url'] = this.url;
    data['streamUrl'] = this.streamUrl;
    data['responsiveUrl'] = this.responsiveUrl;
    return data;
  }
}

class Formats {
  Medium? small;
  Medium? thumbnail;

  Formats({this.small, this.thumbnail});

  Formats.fromJson(Map<String, dynamic> json) {
    small = json['small'] != null ? new Medium.fromJson(json['small']) : null;
    thumbnail = json['thumbnail'] != null
        ? new Medium.fromJson(json['thumbnail'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.small != null) {
      data['small'] = this.small!.toJson();
    }
    if (this.thumbnail != null) {
      data['thumbnail'] = this.thumbnail!.toJson();
    }
    return data;
  }
}

class Tags {
  int? id;
  String? name;
  bool? isDefault;
  int? order;
  String? language;

  Tags({this.id, this.name, this.isDefault, this.order, this.language});

  Tags.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    isDefault = json['isDefault'];
    order = json['order'];
    language = json['language'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['isDefault'] = this.isDefault;
    data['order'] = this.order;
    data['language'] = this.language;
    return data;
  }
}

class Categories {
  int? id;
  String? title;
  String? publishedAt;
  String? createdAt;
  String? updatedAt;
  Label? label;
  int? order;
  Medium? thumbnail;
  Background? background;

  Categories(
      {this.id,
        this.title,
        this.publishedAt,
        this.createdAt,
        this.updatedAt,
        this.label,
        this.order,
        this.thumbnail,
        this.background});

  Categories.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    publishedAt = json['published_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    label = json['label'] != null ? new Label.fromJson(json['label']) : null;
    order = json['order'];
    thumbnail = json['thumbnail'] != null
        ? new Medium.fromJson(json['thumbnail'])
        : null;
    background = json['background'] != null
        ? new Background.fromJson(json['background'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['published_at'] = this.publishedAt;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    if (this.label != null) {
      data['label'] = this.label!.toJson();
    }
    data['order'] = this.order;
    if (this.thumbnail != null) {
      data['thumbnail'] = this.thumbnail!.toJson();
    }
    if (this.background != null) {
      data['background'] = this.background!.toJson();
    }
    return data;
  }
}

class Label {
  String? en;
  String? ja;
  String? ko;

  Label({this.en, this.ja, this.ko});

  Label.fromJson(Map<String, dynamic> json) {
    en = json['en'];
    ja = json['ja'];
    ko = json['ko'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['en'] = this.en;
    data['ja'] = this.ja;
    data['ko'] = this.ko;
    return data;
  }
}

class Thumbnail {
  int? id;
  String? name;
  int? width;
  int? height;
  Formats? formats;
  String? hash;
  String? ext;
  String? mime;
  double? size;
  String? url;
  String? previewUrl;
  String? createdAt;
  String? updatedAt;
  String? waveform;
  String? streamUrl;
  String? responsiveUrl;

  Thumbnail(
      {this.id,
        this.name,
        this.width,
        this.height,
        this.formats,
        this.hash,
        this.ext,
        this.mime,
        this.size,
        this.url,
        this.previewUrl,
        this.createdAt,
        this.updatedAt,
        this.waveform,
        this.streamUrl,
        this.responsiveUrl});

  Thumbnail.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    width = json['width'];
    height = json['height'];
    formats = json['formats'];
    hash = json['hash'];
    ext = json['ext'];
    mime = json['mime'];
    size = json['size'];
    url = json['url'];
    previewUrl = json['previewUrl'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    waveform = json['waveform'];
    streamUrl = json['streamUrl'];
    responsiveUrl = json['responsiveUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['width'] = this.width;
    data['height'] = this.height;
    data['formats'] = this.formats;
    data['hash'] = this.hash;
    data['ext'] = this.ext;
    data['mime'] = this.mime;
    data['size'] = this.size;
    data['url'] = this.url;
    data['previewUrl'] = this.previewUrl;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['waveform'] = this.waveform;
    data['streamUrl'] = this.streamUrl;
    data['responsiveUrl'] = this.responsiveUrl;
    return data;
  }
}

class Background {
  int? id;
  String? name;
  int? width;
  int? height;
  Formats? formats;
  String? hash;
  String? ext;
  String? mime;
  double? size;
  String? url;
  String? previewUrl;
  String? createdAt;
  String? updatedAt;
  String? waveform;
  String? streamUrl;
  String? responsiveUrl;

  Background(
      {this.id,
        this.name,
        this.width,
        this.height,
        this.formats,
        this.hash,
        this.ext,
        this.mime,
        this.size,
        this.url,
        this.previewUrl,
        this.createdAt,
        this.updatedAt,
        this.waveform,
        this.streamUrl,
        this.responsiveUrl});

  Background.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    width = json['width'];
    height = json['height'];
    formats =
    json['formats'] != null ? new Formats.fromJson(json['formats']) : null;
    hash = json['hash'];
    ext = json['ext'];
    mime = json['mime'];
    size = json['size'];
    url = json['url'];
    previewUrl = json['previewUrl'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    waveform = json['waveform'];
    streamUrl = json['streamUrl'];
    responsiveUrl = json['responsiveUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['width'] = this.width;
    data['height'] = this.height;
    if (this.formats != null) {
      data['formats'] = this.formats!.toJson();
    }
    data['hash'] = this.hash;
    data['ext'] = this.ext;
    data['mime'] = this.mime;
    data['size'] = this.size;
    data['url'] = this.url;
    data['previewUrl'] = this.previewUrl;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['waveform'] = this.waveform;
    data['streamUrl'] = this.streamUrl;
    data['responsiveUrl'] = this.responsiveUrl;
    return data;
  }
}

class Small {
  String? ext;
  String? url;
  String? hash;
  String? mime;
  String? name;
  String? path;
  double? size;
  int? width;
  int? height;

  Small(
      {this.ext,
        this.url,
        this.hash,
        this.mime,
        this.name,
        this.path,
        this.size,
        this.width,
        this.height});

  Small.fromJson(Map<String, dynamic> json) {
    ext = json['ext'];
    url = json['url'];
    hash = json['hash'];
    mime = json['mime'];
    name = json['name'];
    path = json['path'];
    size = json['size'];
    width = json['width'];
    height = json['height'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['ext'] = this.ext;
    data['url'] = this.url;
    data['hash'] = this.hash;
    data['mime'] = this.mime;
    data['name'] = this.name;
    data['path'] = this.path;
    data['size'] = this.size;
    data['width'] = this.width;
    data['height'] = this.height;
    return data;
  }
}

class Spots {
  int? id;
  double? startTime;
  String? gpsString;
  int? order;
  Label? addressName;
  Medium? thumbnail;

  Spots(
      {this.id,
        this.startTime,
        this.gpsString,
        this.order,
        this.addressName,
        this.thumbnail});

  Spots.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    startTime = json['startTime'];
    gpsString = json['gpsString'];
    order = json['order'];
    addressName = json['addressName'] != null
        ? new Label.fromJson(json['addressName'])
        : null;
    thumbnail = json['thumbnail'] != null
        ? new Medium.fromJson(json['thumbnail'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['startTime'] = this.startTime;
    data['gpsString'] = this.gpsString;
    data['order'] = this.order;
    if (this.addressName != null) {
      data['addressName'] = this.addressName!.toJson();
    }
    if (this.thumbnail != null) {
      data['thumbnail'] = this.thumbnail!.toJson();
    }
    return data;
  }
}


class Pagination {
  int? page;
  int? pageSize;
  int? pageCount;
  int? total;

  Pagination({this.page, this.pageSize, this.pageCount, this.total});

  Pagination.fromJson(Map<String, dynamic> json) {
    page = json['page'];
    pageSize = json['pageSize'];
    pageCount = json['pageCount'];
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['page'] = page;
    data['pageSize'] = pageSize;
    data['pageCount'] = pageCount;
    data['total'] = total;
    return data;
  }
}
