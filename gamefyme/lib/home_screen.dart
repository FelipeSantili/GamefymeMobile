import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'config/app_colors.dart';
import 'services/auth_service.dart';

// Em um projeto maior, cada uma dessas seções (Models, Services, etc.)
// estaria em seu próprio arquivo. Para esta tela, mantê-los aqui é prático.

//region --- MODELS ---
class Usuario {
  final int id;
  final String nome;
  final String imagemPerfil;
  final int nivel;
  final int exp;
  final int streakAtual;
  final List<StreakDia> streakData;

  Usuario({
    required this.id,
    required this.nome,
    required this.imagemPerfil,
    required this.nivel,
    required this.exp,
    required this.streakAtual,
    required this.streakData,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    var streakList = (json['streak_data'] as List<dynamic>?)
            ?.map((e) => StreakDia.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return Usuario(
      id: json['idusuario'] ?? 0,
      nome: json['nmusuario'] ?? 'Usuário',
      imagemPerfil: json['imagem_perfil'] ?? 'avatar1.png',
      nivel: json['nivelusuario'] ?? 1,
      exp: json['expusuario'] ?? 0,
      streakAtual: json['streak_atual'] ?? 0,
      streakData: streakList,
    );
  }
}

class StreakDia {
  final String diaSemana;
  final String data;
  final String imagem;

  StreakDia({
    required this.diaSemana,
    required this.data,
    required this.imagem,
  });

  factory StreakDia.fromJson(Map<String, dynamic> json) {
    return StreakDia(
      diaSemana: json['dia_semana'] ?? 'N/A',
      data: json['data'] ?? '',
      imagem: json['imagem'] ?? 'fogo-inativo.png',
    );
  }
}

class Atividade {
  final int id;
  final String nome;
  final int xp;

  Atividade({required this.id, required this.nome, required this.xp});

  factory Atividade.fromJson(Map<String, dynamic> json) {
    return Atividade(
      id: json['idatividade'] ?? 0,
      nome: json['nmatividade'] ?? 'Atividade sem nome',
      xp: json['expatividade'] ?? 0,
    );
  }
}

class Conquista {
  final int id;
  final String nome;
  final String imagem;

  Conquista({required this.id, required this.nome, required this.imagem});

  factory Conquista.fromJson(Map<String, dynamic> json) {
    return Conquista(
      id: json['idconquista'] ?? 0,
      nome: json['nmconquista'] ?? '',
      imagem: json['nmimagem'] ?? 'default.png',
    );
  }
}
//endregion

//region --- SERVICES ---
class ApiConfig {
  static const String baseRoot = 'http://127.0.0.1:8000/api';
}

class ApiService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Usuario> fetchUsuario() async {
    final url = Uri.parse('${ApiConfig.baseRoot}/usuarios/me/');
    final res = await http.get(url, headers: await _getHeaders());
    if (res.statusCode == 200) {
      return Usuario.fromJson(json.decode(res.body));
    } else {
      throw Exception('Falha ao carregar dados do usuário');
    }
  }

  Future<List<Atividade>> fetchAtividades() async {
    final url = Uri.parse('${ApiConfig.baseRoot}/atividades/');
    final res = await http.get(url, headers: await _getHeaders());
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      return data.map((e) => Atividade.fromJson(e)).toList();
    } else {
      throw Exception('Falha ao carregar atividades');
    }
  }

  Future<List<Conquista>> fetchUsuarioConquistas() async {
    final url = Uri.parse('${ApiConfig.baseRoot}/conquistas/usuario/');
    final res = await http.get(url, headers: await _getHeaders());
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(res.body);
      return data.map((e) => Conquista.fromJson(e)).toList();
    } else {
      throw Exception('Falha ao carregar conquistas');
    }
  }
  
  Future<bool> realizarAtividade(int atividadeId) async {
    final url = Uri.parse('${ApiConfig.baseRoot}/atividades/$atividadeId/realizar/');
    final res = await http.post(url, headers: await _getHeaders());
    return res.statusCode == 200;
  }
}
//endregion

// Define os possíveis estados da tela
enum ScreenState { loading, loaded, error }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  ScreenState _screenState = ScreenState.loading;
  Usuario? _usuario;
  List<Atividade> _atividades = [];
  List<Conquista> _conquistas = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    if (!mounted) return;
    setState(() => _screenState = ScreenState.loading);

    try {
      // Busca todos os dados em paralelo para mais performance
      final results = await Future.wait([
        _apiService.fetchUsuario(),
        _apiService.fetchAtividades(),
        _apiService.fetchUsuarioConquistas(),
      ]);

      if (!mounted) return;
      setState(() {
        _usuario = results[0] as Usuario;
        _atividades = results[1] as List<Atividade>;
        _conquistas = results[2] as List<Conquista>;
        _screenState = ScreenState.loaded;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados da home: $e');
      if (!mounted) return;
      setState(() => _screenState = ScreenState.error);
    }
  }
  
  Future<void> _realizarAtividade(Atividade atividade) async {
    final success = await _apiService.realizarAtividade(atividade.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${atividade.nome}" realizada (+${atividade.xp} XP)!')),
      );
      // Recarrega os dados para atualizar a tela
      _carregarDados();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível realizar a atividade.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundoEscuro,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregarDados,
          color: AppColors.roxoClaro,
          backgroundColor: AppColors.fundoCard,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildBody(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.verdeLima,
        onPressed: () { /* TODO: Navegar para tela de criar atividade */ },
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.roxoHeader,
      pinned: true,
      title: const Text('GamefyME', style: TextStyle(fontSize: 32)),
      actions: [
        if (_screenState == ScreenState.loaded && _usuario != null)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildUserLevelAvatar(_usuario!),
          ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_screenState) {
      case ScreenState.loading:
        return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
      case ScreenState.error:
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Erro ao carregar dados.', style: TextStyle(color: AppColors.branco)),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: _carregarDados, child: const Text('Tentar Novamente')),
              ],
            ),
          ),
        );
      case ScreenState.loaded:
        final filteredActivities = _atividades
            .where((a) => a.nome.toLowerCase().contains(_searchText.toLowerCase()))
            .toList();
            
        return SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (_usuario != null) _buildPerfilCard(_usuario!),
              const SizedBox(height: 24),
              _buildConquistasPreview(_conquistas),
              const SizedBox(height: 24),
              _buildDesafiosCard(), // TODO: Fazer este card dinâmico
              const SizedBox(height: 24),
              _buildAtividadesSection(filteredActivities),
            ]),
          ),
        );
    }
  }
  
  Widget _buildUserLevelAvatar(Usuario user) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.branco,
          child: CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage("assets/avatares/${user.imagemPerfil}"),
            onBackgroundImageError: (_, __) {}, // Evita crash se a imagem não existir
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.roxoProfundo,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              user.nivel.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerfilCard(Usuario user) {
    // ... Implementação do card do perfil, agora seguro
    return Container(
        // ... (código do card como no seu original, mas usando `user` em vez de `_usuario!`)
    );
  }

  Widget _buildConquistasPreview(List<Conquista> conquistas) {
    // ... Implementação do card de conquistas
    return Container();
  }
  
  Widget _buildDesafiosCard() {
    // ... Implementação do card de desafios
    return Container();
  }
  
  Widget _buildAtividadesSection(List<Atividade> atividades) {
    // ... Implementação da seção de atividades
    return Container();
  }
}
