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
  });

  // Factory for RandomUser API (keep existing)
  factory User.fromJson(Map<String, dynamic> json) {
    final email = json['email'] ?? '';
    final name = json['name'];
    final location = json['location'];
    final dob = json['dob'];
    final picture = json['picture'];
    final login = json['login'];

    // Randomly assign 3-5 interests
    final random = Random();
    final allInterests = List<String>.from(AppInterests.list);
    allInterests.shuffle(random);
    final userInterests = allInterests.take(random.nextInt(3) + 3).toList();

    return User(
      id: login['uuid'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      firstName: name['first'] ?? '',
      lastName: name['last'] ?? '',
      age: dob['age'] ?? 0,
      city: location['city'] ?? '',
      country: location['country'] ?? '',
      imageUrl: picture['large'] ?? '',
      gender: json['gender'] ?? '',
      interests: userInterests,
    );
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
    );
  }

  String get fullName => '$firstName $lastName';
  String get locationString => '$city, $country';
}
