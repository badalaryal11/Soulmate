import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner;

  AuthenticatedHttpClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final idToken = await user.getIdToken();
        if (idToken != null) {
          request.headers['Authorization'] = 'Bearer $idToken';
        }
      } catch (e) {
        // Log error if needed, but continue request
        debugPrint('Error fetching ID token: $e');
      }
    }
    return _inner.send(request);
  }
}
