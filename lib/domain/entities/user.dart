class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final int age;
  final String city;
  final String country;
  final String imageUrl;
  final String gender;
  final List<String> interests;
  final String? genderPreference;
  final String? bio;
  final int streak;
  final int coins;
  final String? lastLoginDate;
  final List<Map<String, String>> prompts;
  final List<String> badges;
  final List<String> favoriteUserIds;
  final List<String> pinnedUserIds;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.city,
    required this.country,
    required this.imageUrl,
    required this.gender,
    required this.interests,
    this.genderPreference,
    this.bio,
    this.streak = 0,
    this.coins = 0,
    this.lastLoginDate,
    this.prompts = const [],
    this.badges = const [],
    this.favoriteUserIds = const [],
    this.pinnedUserIds = const [],
    this.lastMessage,
    this.lastMessageTime,
  });

  String get fullName => '$firstName $lastName';
  String get locationString => '$city, $country';

  static const Object _undefined = Object();

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    int? age,
    String? city,
    String? country,
    String? imageUrl,
    String? gender,
    List<String>? interests,
    Object? genderPreference = _undefined,
    Object? bio = _undefined,
    int? streak,
    int? coins,
    Object? lastLoginDate = _undefined,
    List<Map<String, String>>? prompts,
    List<String>? badges,
    List<String>? favoriteUserIds,
    List<String>? pinnedUserIds,
    Object? lastMessage = _undefined,
    Object? lastMessageTime = _undefined,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      city: city ?? this.city,
      country: country ?? this.country,
      imageUrl: imageUrl ?? this.imageUrl,
      gender: gender ?? this.gender,
      interests: interests ?? this.interests,
      genderPreference: genderPreference == _undefined ? this.genderPreference : genderPreference as String?,
      bio: bio == _undefined ? this.bio : bio as String?,
      streak: streak ?? this.streak,
      coins: coins ?? this.coins,
      lastLoginDate: lastLoginDate == _undefined ? this.lastLoginDate : lastLoginDate as String?,
      prompts: prompts ?? this.prompts,
      badges: badges ?? this.badges,
      favoriteUserIds: favoriteUserIds ?? this.favoriteUserIds,
      pinnedUserIds: pinnedUserIds ?? this.pinnedUserIds,
      lastMessage: lastMessage == _undefined ? this.lastMessage : lastMessage as String?,
      lastMessageTime: lastMessageTime == _undefined ? this.lastMessageTime : lastMessageTime as DateTime?,
    );
  }
}
