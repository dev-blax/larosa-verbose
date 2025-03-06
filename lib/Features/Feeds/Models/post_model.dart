class HashTag {
  final String name;
  final int id;

  HashTag({required this.name, required this.id});

  factory HashTag.fromJson(Map<String, dynamic> json) {
    return HashTag(
      name: json['name'] as String,
      id: json['id'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'id': id,
  };
}

class Post {
  final int id;
  final int favorites;
  final String country;
  final double activityScore;
  final int? adults;
  final String? reservationType;
  final String caption;
  final double? discountPercentage;
  final int verificationStatus;
  final bool? breakfastIncluded;
  final bool liked;
  final int shares;
  final String duration;
  final String path;
  final List<HashTag>? hashTags;
  final double? rate;
  final int? children;
  final double? price;
  final int views;
  final double height;
  final int likes;
  final String? thumbnail;
  final int comments;
  final String accountType;
  final String? profilePicture;
  final List<String>? tags;
  final String? availabilityStatus;
  final String? unit;
  final String names;
  final double? discountedPrice;
  final int profileId;
  final List<String>? mentions;
  final String name;
  final String? location;
  final int time;
  final String contentTypes;
  final bool showShare;
  final bool favorite;
  final String username;

  Post({
    required this.id,
    required this.favorites,
    required this.country,
    required this.activityScore,
    this.adults,
    this.reservationType,
    required this.caption,
    this.discountPercentage,
    required this.verificationStatus,
    this.breakfastIncluded,
    required this.liked,
    required this.shares,
    required this.duration,
    required this.path,
    this.hashTags,
    this.rate,
    this.children,
    this.price,
    required this.views,
    required this.height,
    required this.likes,
    this.thumbnail,
    required this.comments,
    required this.accountType,
    this.profilePicture,
    this.tags,
    this.availabilityStatus,
    this.unit,
    required this.names,
    this.discountedPrice,
    required this.profileId,
    this.mentions,
    required this.name,
    this.location,
    required this.time,
    required this.contentTypes,
    required this.showShare,
    required this.favorite,
    required this.username,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      favorites: json['favorites'] as int,
      country: json['country'] as String,
      activityScore: (json['activity_score'] as num).toDouble(),
      adults: json['adults'] as int?,
      reservationType: json['reservation_type'] as String?,
      caption: json['caption'] as String,
      discountPercentage: json['discount_percentage'] as double?,
      verificationStatus: json['verification_status'] as int,
      breakfastIncluded: json['breakfast_included'] as bool?,
      liked: json['liked'] as bool,
      shares: json['shares'] as int,
      duration: json['duration'] as String,
      path: json['path'] as String,
      hashTags: (json['hashTags'] as List<dynamic>?)?.map((e) => HashTag.fromJson(e as Map<String, dynamic>)).toList(),
      rate: json['rate'] as double?,
      children: json['children'] as int?,
      price: json['price'] as double?,
      views: json['views'] as int,
      height: (json['height'] as num).toDouble(),
      likes: json['likes'] as int,
      thumbnail: json['thumbnail'] as String?,
      comments: json['comments'] as int,
      accountType: json['accountType'] as String,
      profilePicture: json['profile_picture'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      availabilityStatus: json['availability_status'] as String?,
      unit: json['unit'] as String?,
      names: json['names'] as String,
      discountedPrice: json['discountedPrice'] as double?,
      profileId: json['profileId'] as int,
      mentions: (json['mentions'] as List<dynamic>?)?.map((e) => e as String).toList(),
      name: json['name'] as String,
      location: json['location'] as String?,
      time: json['time'] as int,
      contentTypes: json['contentTypes'] as String,
      showShare: json['showShare'] as bool,
      favorite: json['favorite'] as bool,
      username: json['username'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'favorites': favorites,
      'country': country,
      'activity_score': activityScore,
      'adults': adults,
      'reservation_type': reservationType,
      'caption': caption,
      'discount_percentage': discountPercentage,
      'verification_status': verificationStatus,
      'breakfast_included': breakfastIncluded,
      'liked': liked,
      'shares': shares,
      'duration': duration,
      'path': path,
      'hashTags': hashTags?.map((tag) => tag.toJson()).toList(),
      'rate': rate,
      'children': children,
      'price': price,
      'views': views,
      'height': height,
      'likes': likes,
      'thumbnail': thumbnail,
      'comments': comments,
      'accountType': accountType,
      'profile_picture': profilePicture,
      'tags': tags,
      'availability_status': availabilityStatus,
      'unit': unit,
      'names': names,
      'discountedPrice': discountedPrice,
      'profileId': profileId,
      'mentions': mentions,
      'name': name,
      'location': location,
      'time': time,
      'contentTypes': contentTypes,
      'showShare': showShare,
      'favorite': favorite,
      'username': username,
    };
  }
}