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
    this.lastMessage,
    this.lastMessageTime,
  });

  String get fullName => '$firstName $lastName';
  String get locationString => '$city, $country';

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
    String? genderPreference,
    String? bio,
    int? streak,
    int? coins,
    String? lastLoginDate,
    List<Map<String, String>>? prompts,
    List<String>? badges,
    List<String>? favoriteUserIds,
    String? lastMessage,
    DateTime? lastMessageTime,
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
      genderPreference: genderPreference ?? this.genderPreference,
      bio: bio ?? this.bio,
      streak: streak ?? this.streak,
      coins: coins ?? this.coins,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      prompts: prompts ?? this.prompts,
      badges: badges ?? this.badges,
      favoriteUserIds: favoriteUserIds ?? this.favoriteUserIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
}
