import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Layanan autentikasi — membungkus FirebaseAuth supaya halaman UI
/// tidak perlu tahu detail implementasi Firebase secara langsung.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Daftar akun baru dengan email & password, lalu simpan nama
  /// pelatih ke koleksi Firestore `coaches/{uid}`.
  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(name);

    await FirebaseFirestore.instance
        .collection('coaches')
        .doc(credential.user!.uid)
        .set({
      'name': name,
      'username': username,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Firebase otomatis login-kan akun yang baru dibuat. Kita sign-out
    // paksa di sini supaya pengguna diarahkan balik ke halaman Login
    // dan harus login manual, bukan langsung masuk ke Home.
    await _auth.signOut();
  }

  Future<void> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() {
    return _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Ubah nama tampilan pelatih. Diperbarui di Firebase Auth
  /// (displayName) sekaligus di dokumen Firestore `coaches/{uid}`.
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Belum login');

    await user.updateDisplayName(name);
    await FirebaseFirestore.instance
        .collection('coaches')
        .doc(user.uid)
        .update({'name': name});
  }

  /// Ganti password. Firebase mewajibkan re-autentikasi (masukkan
  /// password lama) sebelum boleh mengganti ke password baru — ini
  /// proteksi bawaan supaya orang lain yang kebetulan memegang HP
  /// dalam keadaan masih login tidak bisa sembarangan ganti password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw StateError('Belum login');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  /// Menerjemahkan kode error FirebaseAuth ke pesan berbahasa Indonesia
  /// yang lebih mudah dipahami pengguna.
  String readableError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Email sudah terdaftar. Silakan masuk.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'weak-password':
          return 'Password terlalu lemah, minimal 6 karakter.';
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          return 'Email atau password salah.';
        case 'user-disabled':
          return 'Akun ini telah dinonaktifkan.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Coba lagi nanti.';
        case 'network-request-failed':
          return 'Tidak ada koneksi internet.';
        default:
          return 'Terjadi kesalahan (${error.code}).';
      }
    }
    return 'Terjadi kesalahan tak terduga.';
  }
}