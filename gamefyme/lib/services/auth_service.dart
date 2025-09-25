import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Endereço da sua API local. Use 127.0.0.1 para emulador web
  // e 10.0.2.2 para emulador Android.
  final String _baseUrl = "http://127.0.0.1:8000/api/usuarios";
  final _storage = const FlutterSecureStorage();

  // Salva o token de acesso de forma segura no dispositivo
  Future<void> _saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // Recupera o token de acesso salvo
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Remove o token ao fazer logout
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }

  /// Realiza o login do usuário na API.
  /// Retorna um Map com 'success' (true/false) e 'message'.
  Future<Map<String, dynamic>> login(String email, String senha) async {
    final url = Uri.parse("$_baseUrl/login/");
    final body = jsonEncode({
      'emailusuario': email,
      'password': senha, // A API espera a chave 'password'
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Acessa o token de acesso dentro do objeto 'tokens' na resposta da API
        final String accessToken = responseBody['tokens']['access'];
        await _saveToken(accessToken);
        return {'success': true, 'message': 'Login bem-sucedido!'};
      } else {
        // Retorna a mensagem de erro fornecida pela API
        return {'success': false, 'message': responseBody['detail'] ?? responseBody['erro'] ?? 'Credenciais inválidas.'};
      }
    } catch (e) {
      debugPrint("Erro na requisição de login: $e");
      return {'success': false, 'message': 'Erro de conexão. Verifique se a API está rodando.'};
    }
  }
  
  /// Realiza o cadastro de um novo usuário na API.
  /// Retorna um Map com 'success' (true/false) e 'message'.
  Future<Map<String, dynamic>> register({
    required String nome,
    required String email,
    required String senha,
    required String confSenha,
  }) async {
    final url = Uri.parse("$_baseUrl/cadastro/");
    final body = jsonEncode({
      'nmusuario': nome,
      'emailusuario': email,
      'senha': senha,
      'confsenha': confSenha,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Após o cadastro, a API também retorna o token de acesso
        final String accessToken = responseBody['tokens']['access'];
        await _saveToken(accessToken);
        return {'success': true, 'message': responseBody['message']};
      } else {
        return {'success': false, 'message': responseBody['erro'] ?? 'Ocorreu um erro no cadastro.'};
      }
    } catch (e) {
      debugPrint("Erro na requisição de cadastro: $e");
      return {'success': false, 'message': 'Erro de conexão. Verifique se a API está rodando.'};
    }
  }
}

