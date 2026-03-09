import 'dart:developer' as developer;
import 'dart:math';
import '../../core/constants/interests.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  static const List<String> _bioPool = [
    'Adventure seeker 🌍 | Always planning the next trip',
    'Dog lover & bookworm 📚 | Cozy nights > wild nights',
    'Fitness junkie 💪 | Weekend chef 🍳',
    'Creative soul 🎨 | Music is my therapy',
    'Coffee addict ☕ | Sunset chaser 🌅',
    'Tech nerd by day, foodie by night 🍕',
    'Living life one hike at a time 🏔️',
    'Yoga enthusiast 🧘 | Plant parent 🌿',
    'Film buff 🎬 | Amateur photographer 📸',
    'Spontaneous traveler ✈️ | Storyteller at heart',
    'Gym mornings, Netflix evenings 🎧',
    'Aspiring chef 👨‍🍳 | Board game champion 🎲',
    'Nature lover 🌻 | Star gazer at night ✨',
    'Dancing through life 💃 | Karaoke king 🎤',
    'Old soul with a young heart 💛',
    'Football fanatic ⚽ | Pizza connoisseur 🍕',
    'Ocean vibes 🌊 | Beach bum at heart',
    'Cat person 🐱 | Tea over coffee, always',
    'Weekend warrior 🚴 | Trail runner',
    'Art gallery hopper 🖼️ | Wine enthusiast 🍷',
    'Podcast addict 🎙️ | Early bird 🌅',
    'Thrill seeker 🎢 | Road trip lover 🚗',
    'Minimalist living ✨ | Big dreamer',
    'Guitar player 🎸 | Campfire storyteller 🔥',
  ];

  static String _pickBio(String id) {
    return _bioPool[id.hashCode.abs() % _bioPool.length];
  }

  UserModel({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.age,
    required super.city,
    required super.country,
    required super.imageUrl,
    required super.gender,
    required super.interests,
    super.genderPreference,
    super.bio,
    super.streak = 0,
    super.coins = 0,
    super.lastLoginDate,
    super.prompts = const [],
    super.badges = const [],
    super.favoriteUserIds = const [],
  });

  // Factory for RandomUser API
  factory UserModel.fromRandomUser(Map<String, dynamic> json) {
    try {
      final name = json['name'] ?? {};
      final location = json['location'] ?? {};
      final picture = json['picture'] ?? {};
      final dob = json['dob'] ?? {};
      final login = json['login'] ?? {};

      // Random interests generation
      final random = Random();
      final allInterests = List<String>.from(AppInterests.list);
      allInterests.shuffle(random);
      final userInterests = allInterests.take(random.nextInt(3) + 3).toList();

      return UserModel(
        id: login['uuid'] ?? login['username'] ?? '',
        email: json['email'] ?? '',
        firstName: name['first'] ?? '',
        lastName: name['last'] ?? '',
        age: dob['age'] ?? 0,
        city: location['city'] ?? '',
        country: location['country'] ?? '',
        imageUrl: picture['large'] ?? '',
        gender: json['gender'] ?? '',
        interests: userInterests,
        bio: _pickBio(login['uuid'] ?? login['username'] ?? ''),
        streak: 0,
        coins: 0,
        lastLoginDate: DateTime.now().toIso8601String(),
        prompts: [],
        badges: [],
        favoriteUserIds: [],
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error parsing RandomUser JSON',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Factory for DummyJSON API
  factory UserModel.fromDummyJson(Map<String, dynamic> json) {
    try {
      final random = Random();
      final allInterests = List<String>.from(AppInterests.list);
      allInterests.shuffle(random);
      final userInterests = allInterests.take(random.nextInt(3) + 3).toList();

      final address = json['address'] ?? {};

      return UserModel(
        id: json['id'].toString(), // DummyJSON IDs are integers
        email: json['email'] ?? '',
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        age: json['age'] ?? 0,
        city: address['city'] ?? '',
        country:
            address['country'] ?? 'USA', // DummyJSON often uses US addresses
        imageUrl: json['image'] ?? '',
        gender: json['gender'] ?? '',
        interests: userInterests,
        bio: json['company']?['title'] != null
            ? '${json['company']['title']} at ${json['company']['name']}'
            : _pickBio(json['id'].toString()),
        streak: 0,
        coins: 0,
        lastLoginDate: DateTime.now().toIso8601String(),
        prompts: [],
        badges: [],
        favoriteUserIds: [],
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error parsing User JSON',
        error: e,
        stackTrace: stackTrace,
      );
      developer.log('JSON content: $json');
      rethrow;
    }
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'city': city,
      'country': country,
      'imageUrl': imageUrl,
      'gender': gender,
      'interests': interests,
      'genderPreference': genderPreference,
      'bio': bio,
      'streak': streak,
      'coins': coins,
      'lastLoginDate': lastLoginDate,
      'prompts': prompts,
      'badges': badges,
      'favoriteUserIds': favoriteUserIds,
    };
  }

  // Factory from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      age: map['age'] ?? 0,
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      gender: map['gender'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      genderPreference: map['genderPreference'],
      bio: map['bio'],
      streak: map['streak'] ?? 0,
      coins: map['coins'] ?? 0,
      lastLoginDate: map['lastLoginDate'],
      prompts: List<Map<String, String>>.from(
        (map['prompts'] as List<dynamic>?)?.map(
              (p) => Map<String, String>.from(p),
            ) ??
            [],
      ),
      badges: List<String>.from(map['badges'] ?? []),
      favoriteUserIds: List<String>.from(map['favoriteUserIds'] ?? []),
    );
  }
}
