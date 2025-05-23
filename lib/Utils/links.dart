class LarosaLinks {
  LarosaLinks._();
  static const String baseurl = 'https://burnished-core-439210-f6.uc.r.appspot.com';
  static const String socketUrl = 'https://burnished-core-439210-f6.uc.r.appspot.com/ws';
  static const String baseWsUrl = 'wss://burnished-core-439210-f6.uc.r.appspot.com/ws/websocket';
  static const String nakedBaseUrl = 'burnished-core-439210-f6.uc.r.appspot.com';
  static const String countriesEndpoint = '/countries/all';
  static const String registrationEndpoint = '/api/v1/auth/register';
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String forgetPassword = '$baseurl/api/v1/auth/forgot-password';
  static const String verifyForgotPassword = '$baseurl/api/v1/auth/reset-password';
  static const String allFeeds = '$baseurl/feeds/fetch';
  static const String likePost = '$baseurl/like/save';
  static const String fetchComments = '$baseurl/comments/post';
  static const String newComment = '$baseurl/comments/new';
  static const String newPost = '/PostEditDelete/upload';
  static const String feedsEndpoint = '/feeds/fetch';
  static const String brandProfile = '/brand/myProfile';
  static const String socialLogin = '/api/v1/auth/social';
  static const String notifyOnline = '/app/user/addUser';
  // Reels endpoints
  static const String reelsFetch = '$baseurl/reels/fetch';
  static const String reelsFavourite = '$baseurl/favorites/update';
  static const String reelsLike = '$baseurl/like/save';

  // discover
  static const String discover = '$baseurl/search/discover';

  // Cart
  static const String cartList = '$baseurl/cart/list';
  static const String reservationList = '$baseurl/api/v1/reservation-cart/view';
  static const String cartAddItem = '$baseurl/cart/add-item';
  static const String cartRemoveItem = '$baseurl/cart/remove-item';
  static const String addCartItemQuantity = '$baseurl/cart/increase-quantity';
  static const String decreaseCartItemQuantity = '$baseurl/cart/decrease-quantity';


  
}
