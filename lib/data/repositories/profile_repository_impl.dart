import 'package:e_commerce_app/data/datasources/store_api.dart';
import 'package:e_commerce_app/data/datasources/api_paths.dart';
import 'package:e_commerce_app/data/datasources/firestore_services.dart';
import 'package:e_commerce_app/data/models/user_data.dart';
import 'package:e_commerce_app/domain/entities/app_user.dart';
import 'package:e_commerce_app/domain/repositories/profile_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final firebaseServices = FirestoreServices.instance;

  @override
  Future<AppUser> getUserData(String userId) async {
    final docSnapshot =
        await firebaseServices.firestore.doc(ApiPaths.user(userId)).get();
    final data = docSnapshot.data();
    if (docSnapshot.exists && data != null) {
      final email = FirebaseAuth.instance.currentUser?.email;
      if (email != null && data['email'] != email) {
        await firebaseServices.updateData(
          path: ApiPaths.user(userId),
          data: {'email': email},
        );
        data['email'] = email;
      }
      return UserData.fromMap(data);
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final providerId =
        currentUser?.providerData.isNotEmpty == true
            ? currentUser!.providerData.first.providerId
            : 'password';
    final fallbackUser = UserData(
      id: userId,
      username:
          currentUser?.displayName ??
          currentUser?.email?.split('@').first ??
          'User',
      email: currentUser?.email ?? '',
      createdAt: DateTime.now().toIso8601String(),
      providerId: providerId,
      photoUrl: currentUser?.photoURL ?? '',
    );
    await firebaseServices.setData(
      path: ApiPaths.user(userId),
      data: fallbackUser.toMap(),
    );
    return fallbackUser;
  }

  @override
  Future<void> changeUserEmail(String userId, String newEmail) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.email != newEmail) {
      await currentUser.verifyBeforeUpdateEmail(newEmail);
    }
    // Firebase Auth changes the email only after the verification link is used.
  }

  @override
  Future<void> changeUserName(String userId, String newName) async =>
      await firebaseServices.updateData(
        path: ApiPaths.user(userId),
        data: {'username': newName},
      );

  @override
  Future<void> changeUserPassword(String userId, String newPassword) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await currentUser.updatePassword(newPassword);
    }
  }

  @override
  Future<void> updateUserPhoto(String userId, String photoUrl) async =>
      await firebaseServices.updateData(
        path: ApiPaths.user(userId),
        data: {'photoUrl': photoUrl},
      );

  @override
  Future<void> deleteUser(String userId) async =>
      await StoreApi.instance.request('account', method: 'DELETE');
}
