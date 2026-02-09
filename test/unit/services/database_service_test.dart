import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soulmate/data/services/database_service.dart';
import 'package:soulmate/data/models/user_model.dart';

// Generate mocks for FirebaseFirestore, CollectionReference, DocumentReference, DocumentSnapshot, QuerySnapshot
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  Query,
  QueryDocumentSnapshot,
])
import 'database_service_test.mocks.dart';

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockCollectionReference;
  late MockDocumentReference<Map<String, dynamic>> mockDocumentReference;
  late DatabaseService databaseService;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollectionReference = MockCollectionReference();
    mockDocumentReference = MockDocumentReference();

    // Inject mock firestore
    databaseService = DatabaseService(firestore: mockFirestore);
  });

  group('DatabaseService', () {
    test('saveUser saves user to firestore', () async {
      final user = User(
        id: 'test_uid',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        age: 25,
        city: 'New York',
        country: 'USA',
        imageUrl: 'http://example.com/image.jpg',
        gender: 'Male',
        interests: ['Coding', 'Music'],
      );

      // Mock Firestore chain
      when(
        mockFirestore.collection('users'),
      ).thenReturn(mockCollectionReference);
      when(
        mockCollectionReference.doc('test_uid'),
      ).thenReturn(mockDocumentReference);
      when(mockDocumentReference.set(any, any)).thenAnswer((_) async {});

      await databaseService.saveUser(user);

      verify(mockFirestore.collection('users')).called(1);
      verify(mockCollectionReference.doc('test_uid')).called(1);
      verify(mockDocumentReference.set(user.toMap(), any)).called(1);
    });

    test('updateUserField updates user data', () async {
      // Mock Firestore chain
      when(
        mockFirestore.collection('users'),
      ).thenReturn(mockCollectionReference);
      when(
        mockCollectionReference.doc('test_uid'),
      ).thenReturn(mockDocumentReference);
      when(mockDocumentReference.update(any)).thenAnswer((_) async {});

      await databaseService.updateUserField('test_uid', {
        'firstName': 'Updated Name',
      });

      verify(mockFirestore.collection('users')).called(1);
      verify(mockCollectionReference.doc('test_uid')).called(1);
      verify(
        mockDocumentReference.update({'firstName': 'Updated Name'}),
      ).called(1);
    });
  });
}
