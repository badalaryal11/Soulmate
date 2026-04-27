import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soulmate/data/datasources/chat_database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatDatabaseService migration', () {
    late ChatDatabaseService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = ChatDatabaseService();
    });

    String canonicalId(String userId1, String userId2) {
      return userId1.compareTo(userId2) <= 0
          ? '${userId1}_$userId2'
          : '${userId2}_$userId1';
    }

    String reverseId(String userId1, String userId2) {
      return '${userId1}_$userId2';
    }

    String legacyHashId(String userId1, String userId2) {
      return userId1.hashCode <= userId2.hashCode
          ? '${userId1}_$userId2'
          : '${userId2}_$userId1';
    }

    String encodeMessage({
      required String id,
      required String senderId,
      required String text,
      required int timestamp,
      bool isRead = false,
      int? readAt,
    }) {
      return jsonEncode({
        'id': id,
        'senderId': senderId,
        'text': text,
        'timestamp': timestamp,
        'gameType': null,
        'gameData': null,
        'stickerUrl': null,
        'isRead': isRead,
        'readAt': readAt,
      });
    }

    test('initializeChat migrates reverse-key metadata and messages', () async {
      const userA = 'z_user';
      const userB = 'a_user';
      final canonical = canonicalId(userA, userB);
      final reverse = reverseId(userA, userB);
      expect(reverse, isNot(canonical));

      SharedPreferences.setMockInitialValues({
        'chats_metadata': jsonEncode({
          reverse: {
            'participants': [userA, userB],
            'lastMessage': 'legacy hello',
            'lastMessageTime': 1700000000000,
            'streak': 3,
            'xp': 12,
          },
        }),
        'chat_messages_$reverse': jsonEncode([
          encodeMessage(
            id: 'm_legacy',
            senderId: userA,
            text: 'legacy message',
            timestamp: 1700000000000,
          ),
        ]),
      });

      service = ChatDatabaseService();
      await service.initializeChat(userA, userB);

      final prefs = await SharedPreferences.getInstance();
      final metadata = Map<String, dynamic>.from(
        jsonDecode(prefs.getString('chats_metadata') ?? '{}') as Map,
      );
      expect(metadata.containsKey(canonical), isTrue);
      expect(metadata.containsKey(reverse), isFalse);

      final canonicalData = Map<String, dynamic>.from(
        metadata[canonical] as Map<String, dynamic>,
      );
      expect(
        List<String>.from(canonicalData['participants'] as List),
        containsAll([userA, userB]),
      );
      expect(canonicalData['lastMessage'], 'legacy hello');
      expect(canonicalData['streak'], 3);
      expect(canonicalData['xp'], 12);

      final migratedRaw = prefs.getString('chat_messages_$canonical');
      expect(migratedRaw, isNotNull);
      final migratedMessages = List<String>.from(
        jsonDecode(migratedRaw!) as List,
      );
      expect(migratedMessages, hasLength(1));
      expect(prefs.getString('chat_messages_$reverse'), isNull);
    });

    test(
      'initializeChat deduplicates overlapping messages and keeps read state',
      () async {
        const userA = 'z_user';
        const userB = 'a_user';
        final canonical = canonicalId(userA, userB);
        final reverse = reverseId(userA, userB);

        SharedPreferences.setMockInitialValues({
          'chats_metadata': jsonEncode({
            canonical: {
              'participants': [userB, userA],
              'lastMessage': 'canonical',
              'lastMessageTime': 1200,
              'streak': 1,
              'xp': 5,
            },
            reverse: {
              'participants': [userA, userB],
              'lastMessage': 'reverse',
              'lastMessageTime': 1200,
              'streak': 4,
              'xp': 8,
            },
          }),
          'chat_messages_$canonical': jsonEncode([
            encodeMessage(
              id: 'm_same',
              senderId: userA,
              text: 'same payload canonical',
              timestamp: 1200,
              isRead: false,
            ),
          ]),
          'chat_messages_$reverse': jsonEncode([
            encodeMessage(
              id: 'm_same',
              senderId: userA,
              text: 'same payload reverse',
              timestamp: 1200,
              isRead: true,
              readAt: 1300,
            ),
            encodeMessage(
              id: 'm_only_reverse',
              senderId: userB,
              text: 'extra',
              timestamp: 1250,
            ),
          ]),
        });

        service = ChatDatabaseService();
        await service.initializeChat(userA, userB);

        final prefs = await SharedPreferences.getInstance();
        final migratedRaw = prefs.getString('chat_messages_$canonical');
        expect(migratedRaw, isNotNull);
        expect(prefs.getString('chat_messages_$reverse'), isNull);

        final migrated = List<String>.from(jsonDecode(migratedRaw!) as List)
            .map((raw) => Map<String, dynamic>.from(jsonDecode(raw) as Map))
            .toList();

        expect(migrated, hasLength(2));
        final mergedSame = migrated.firstWhere((m) => m['id'] == 'm_same');
        expect(mergedSame['isRead'], isTrue);
        expect(mergedSame['readAt'], 1300);

        final metadata = Map<String, dynamic>.from(
          jsonDecode(prefs.getString('chats_metadata') ?? '{}') as Map,
        );
        final canonicalData = Map<String, dynamic>.from(
          metadata[canonical] as Map<String, dynamic>,
        );
        expect(canonicalData['xp'], 8);
        expect(canonicalData['streak'], 4);
      },
    );

    test(
      'deleteChat removes canonical and alias keys for same participants',
      () async {
        const userA = 'z_user';
        const userB = 'a_user';
        final canonical = canonicalId(userA, userB);
        final reverse = reverseId(userA, userB);
        final legacy = legacyHashId(userA, userB);
        const unrelated = 'aa_user_bb_user';

        SharedPreferences.setMockInitialValues({
          'chats_metadata': jsonEncode({
            canonical: {
              'participants': [userA, userB],
              'lastMessage': 'canonical',
              'lastMessageTime': 100,
              'streak': 1,
              'xp': 1,
            },
            reverse: {
              'participants': [userA, userB],
              'lastMessage': 'reverse',
              'lastMessageTime': 200,
              'streak': 2,
              'xp': 2,
            },
            if (legacy != canonical && legacy != reverse)
              legacy: {
                'participants': [userA, userB],
                'lastMessage': 'legacy',
                'lastMessageTime': 150,
                'streak': 3,
                'xp': 3,
              },
            unrelated: {
              'participants': ['aa_user', 'bb_user'],
              'lastMessage': 'keep me',
              'lastMessageTime': 999,
              'streak': 9,
              'xp': 9,
            },
          }),
          'chat_messages_$canonical': jsonEncode([
            encodeMessage(
              id: 'm_c',
              senderId: userA,
              text: 'c',
              timestamp: 100,
            ),
          ]),
          'chat_messages_$reverse': jsonEncode([
            encodeMessage(
              id: 'm_r',
              senderId: userB,
              text: 'r',
              timestamp: 200,
            ),
          ]),
          if (legacy != canonical && legacy != reverse)
            'chat_messages_$legacy': jsonEncode([
              encodeMessage(
                id: 'm_l',
                senderId: userA,
                text: 'l',
                timestamp: 150,
              ),
            ]),
          'chat_messages_$unrelated': jsonEncode([
            encodeMessage(
              id: 'm_u',
              senderId: 'aa_user',
              text: 'u',
              timestamp: 999,
            ),
          ]),
        });

        service = ChatDatabaseService();
        await service.deleteChat(canonical);

        final prefs = await SharedPreferences.getInstance();
        final metadata = Map<String, dynamic>.from(
          jsonDecode(prefs.getString('chats_metadata') ?? '{}') as Map,
        );

        expect(metadata.containsKey(canonical), isFalse);
        expect(metadata.containsKey(reverse), isFalse);
        if (legacy != canonical && legacy != reverse) {
          expect(metadata.containsKey(legacy), isFalse);
        }
        expect(metadata.containsKey(unrelated), isTrue);

        expect(prefs.getString('chat_messages_$canonical'), isNull);
        expect(prefs.getString('chat_messages_$reverse'), isNull);
        if (legacy != canonical && legacy != reverse) {
          expect(prefs.getString('chat_messages_$legacy'), isNull);
        }
        expect(prefs.getString('chat_messages_$unrelated'), isNotNull);
      },
    );
  });
}
