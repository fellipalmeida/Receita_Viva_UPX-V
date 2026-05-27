import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final _auth = FirebaseAuth.instance;

  User? get usuarioAtual => _auth.currentUser;

  Future<User> entrar(String email, String senha) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: senha,
    );
    return result.user!;
  }

  Future<User> cadastrar(String email, String senha) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );
    return result.user!;
  }

  Future<void> sair() async => _auth.signOut();

  Future<void> excluirConta() async {
    await _auth.currentUser?.delete();
  }
}
