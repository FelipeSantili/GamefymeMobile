import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/models.dart'; // Vamos criar este arquivo a seguir

class ApiService {
  final AuthService _authService = AuthService();
  // Use 10.0.2.2 para emulador Android, 127.0.0.1 para web/desktop
  static const String _baseRoot = 'http://127.0.0.1:8000/api';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Usuario> fetchUsuario() async {
    final url = Uri.parse('$_baseRoot/usuarios/me/');
    final res = await http.get(url, headers: await _getHeaders());
    if (res.statusCode == 200) {
      return Usuario.fromJson(json.decode(utf8.decode(res.bodyBytes)));
    } else {
      throw Exception('Falha ao carregar dados do usuário');
    }
  }

  Future<List<Atividade>> fetchAtividades() async {
    final url = Uri.parse('$_baseRoot/atividades/');
    final res = await http.get(url, headers: await _getHeaders());
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) => Atividade.fromJson(e)).toList();
    } else {
      throw Exception('Falha ao carregar atividades');
    }
  }

  Future<List<Conquista>> fetchUsuarioConquistas() async {
    final url = Uri.parse('$_baseRoot/conquistas/usuario/');
    final res = await http.get(url, headers: await _getHeaders());
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) => Conquista.fromJson(e, desbloqueada: true)).take(5).toList();
    } else {
      throw Exception('Falha ao carregar conquistas do usuário');
    }
  }

  Future<List<DesafioPendente>> fetchDesafiosPendentes() async {
    final url = Uri.parse('$_baseRoot/desafios/');
    final res = await http.get(url, headers: await _getHeaders());
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) => DesafioPendente.fromJson(e)).take(1).toList();
    } else {
      throw Exception('Falha ao carregar desafios');
    }
  }

  Future<bool> realizarAtividade(int atividadeId) async {
    final url = Uri.parse('$_baseRoot/atividades/$atividadeId/realizar/');
    final res = await http.post(url, headers: await _getHeaders());
    return res.statusCode == 200;
  }

  // --- NOVO MÉTODO PARA CADASTRAR ATIVIDADE ---
  Future<Map<String, dynamic>> cadastrarAtividade({
    required String nome,
    required String descricao,
    required String peso,
    required String recorrencia,
    required int tpEstimado,
  }) async {
    final url = Uri.parse('$_baseRoot/atividades/');
    final body = jsonEncode({
      'nmatividade': nome,
      'dsatividade': descricao,
      'peso': peso,
      'recorrencia': recorrencia,
      'tpestimado': tpEstimado,
      // A API precisa lidar com a data e situação, ou podemos enviar daqui
      'dtatividade': DateTime.now().toIso8601String(),
    });

    try {
      final response = await http.post(url, headers: await _getHeaders(), body: body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Atividade criada com sucesso!'};
      } else {
        final responseBody = jsonDecode(response.body);
        return {'success': false, 'message': responseBody.toString()};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<List<Notificacao>> fetchNotificacoes() async {
    final url = Uri.parse('$_baseRoot/notificacoes/');
    final res = await http.get(url, headers: await _getHeaders());
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) => Notificacao.fromJson(e)).toList();
    } else {
      throw Exception('Falha ao carregar notificações');
    }
  }

  Future<void> marcarNotificacaoComoLida(int notificacaoId) async {
    final url = Uri.parse('$_baseRoot/notificacoes/$notificacaoId/marcar-como-lida/');
    await http.post(url, headers: await _getHeaders());
  }
}