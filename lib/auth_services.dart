import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

ValueNotifier<AuthServices> authServices = ValueNotifier(AuthServices());

class AuthServices {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  //google sign in
  Future<UserCredential?> signInWithGoogle() async {
<<<<<<< HEAD
    try {
      // begin interative signin process
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      // obtain auth details from request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final GoogleSignInClientAuthorization? googleAuthz = await googleUser
          .authorizationClient
          .authorizationForScopes([]);

      // create a new credential for the user
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuthz?.accessToken,
        idToken: googleAuth.idToken,
      );

      //sign in
      return await firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      return null;
    }
=======
    // begin interative signin process
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // check if user cancels
    if (googleUser == null) return null;

    // obtain auth details from request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // create a new credential for the user
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    //sign in
    return await firebaseAuth.signInWithCredential(credential);
>>>>>>> origin/master
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    return await firebaseAuth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    return await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }
}
