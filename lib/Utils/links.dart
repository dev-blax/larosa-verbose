class LarosaLinks {
  LarosaLinks._();

  // static const String baseurl =
  //     'http://explorelarosa2-env.eba-7tvkaxyw.af-south-1.elasticbeanstalk.com';

  static const String baseurl = 'https://exploretest.uc.r.appspot.com';
  // static const String nakedBaseUrl =
  //     'explorelarosa2-env.eba-7tvkaxyw.af-south-1.elasticbeanstalk.com';

  static const String nakedBaseUrl = 'exploretest.uc.r.appspot.com';
  static const String countriesEndpoint = '/countries/all';
  static const String registrationEndpoint = '/api/v1/auth/register';
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String forgetPassword = '/api/v1/auth/forgot-password';
  static const String allFeeds = '/feeds/fetch';
  static const String likePost = '$baseurl/like/save';
  static const String fetchComments = '$baseurl/comments/post';
  static const String newComment = '$baseurl/comments/new';
  // feeds
  static const String newPost = '/PostEditDelete/upload';
  static const String feedsEndpoint = '/feeds/fetch';

  // profiles
  static const String brandProfile = '/brand/myProfile';

  // chats
  static const String notifyOnline = '/app/user/addUser';

  //
}
