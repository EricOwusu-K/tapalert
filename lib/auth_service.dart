import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register user
  Future<void> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String surname,
    required String phone,
    String? token, // <-- token passed from UI
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // Fetch token if not provided
      token ??= await FirebaseMessaging.instance.getToken();

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'firstName': firstName,
        'surname': surname,
        'email': email,
        'phone': phone,
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Registration failed: $e");
    }
  }

  // Sign in using phone & password
  Future<void> signInWithPhoneAndPassword({
    required String phone,
    required String password,
  }) async {
    try {
      // Find user by phone
      QuerySnapshot query =
          await _firestore
              .collection('users')
              .where('phone', isEqualTo: phone)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        throw Exception("Phone number not found.");
      }

      String email = query.docs.first['email'];
      String uid = query.docs.first['uid'];

      // Login using email/password
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Update token after login
      String? newToken = await FirebaseMessaging.instance.getToken();
      if (newToken != null) {
        await updateUserToken(uid: uid, token: newToken);
      }
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  // Update user FCM token
  Future<void> updateUserToken({
    required String uid,
    required String token,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Failed to update token: $e");
    }
  }

  // Get currently logged-in Firebase user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
