import 'dart:developer' as developer;
import 'dart:math';
import '../constants/interests.dart';

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
  });

  // Factory for RandomUser API
  factory User.fromRandomUser(Map<String, dynamic> json) {
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

      return User(
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
        bio:
            "Explorer of the world | Coffee enthusiast", // RandomUser doesn't have bio/company usually
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
  factory User.fromDummyJson(Map<String, dynamic> json) {
    try {
      final random = Random();
      final allInterests = List<String>.from(AppInterests.list);
      allInterests.shuffle(random);
      final userInterests = allInterests.take(random.nextInt(3) + 3).toList();

      final address = json['address'] ?? {};

      return User(
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
            : "Here to find my soulmate!",
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
    };
  }

  // Factory from Firestore Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
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
    );
  }

  String get fullName => '$firstName $lastName';
  String get locationString => '$city, $country';
}
