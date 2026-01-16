class User {
  final String id;
  final String firstName;
  final String lastName;
  final int age;
  final String city;
  final String country;
  final String imageUrl;
  final String gender;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.city,
    required this.country,
    required this.imageUrl,
    required this.gender,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final location = json['location'];
    final dob = json['dob'];
    final picture = json['picture'];
    final login = json['login'];

    return User(
      id: login['uuid'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: name['first'] ?? '',
      lastName: name['last'] ?? '',
      age: dob['age'] ?? 0,
      city: location['city'] ?? '',
      country: location['country'] ?? '',
      imageUrl: picture['large'] ?? '',
      gender: json['gender'] ?? '',
    );
  }

  String get fullName => '$firstName $lastName';
  String get locationString => '$city, $country';
}
