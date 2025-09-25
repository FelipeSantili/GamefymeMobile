import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

import 'config/app_colors.dart';
import 'services/auth_service.dart';
import 'main.dart'; // Import para a WelcomePage no logout

// Em um projeto maior, cada uma dessas seções (Models, Services, etc.)
// estaria em seu próprio arquivo. Para esta tela, mantê-los aqui é prático.

//region --- MODELS ---
class Usuario {
  final int id;
  final String nome;
  final String imagemPerfil;
  final int nivel;
  final int exp;
  final int expTotalNivel; // Adicionado para a barra de progresso
  final int streakAtual;
  final List<StreakDia> streakData;

  Usuario({
    required this.id,
    required this.nome,
    required this.imagemPerfil,
    required this.nivel,
    required this.exp,
    required this.expTotalNivel,
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
      expTotalNivel: json['exp_total_nivel'] ?? 1000, // API precisa enviar isso
      streakAtual: json['streak_atual'] ?? 0,
      streakData: streakList,
    );
  }
}

class StreakDia {
  final String diaSemana;
  final String imagem;

  StreakDia({
    required this.diaSemana,
    required this.imagem,
  });

  factory StreakDia.fromJson(Map<String, dynamic> json) {
    return StreakDia(
      diaSemana: json['dia_semana'] ?? 'N/A',
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

class DesafioPendente {
  final int id;
  final String nome;
  final int progresso;
  final int meta;
  final int xp;

  DesafioPendente({
    required this.id,
    required this.nome,
    required this.progresso,
    required this.meta,
    required this.xp,
  });

  factory DesafioPendente.fromJson(Map<String, dynamic> json) {
    return DesafioPendente(
      id: json['iddesafio'] ?? 0,
      nome: json['nmdesafio'] ?? 'Desafio sem nome',
      progresso: json['progresso_atual'] ?? 0, // API precisa enviar isso
      meta: json['parametro'] ?? 1, // API precisa enviar isso
      xp: json['expdesafio'] ?? 0,
    );
  }
}

class Conquista {
  final int id;
  final String nome;
  final String imagem;
  final bool desbloqueada;

  Conquista({
    required this.id,
    required this.nome,
    required this.imagem,
    required this.desbloqueada,
  });

  factory Conquista.fromJson(Map<String, dynamic> json, {bool desbloqueada = false}) {
    // A API de conquistas do usuário retorna um objeto aninhado 'conquista'
    final conquistaData = json.containsKey('conquista') ? json['conquista'] : json;
    
    return Conquista(
      id: conquistaData['idconquista'] ?? 0,
      nome: conquistaData['nmconquista'] ?? '',
      imagem: conquistaData['nmimagem'] ?? 'recorrencia.png',
      desbloqueada: desbloqueada,
    );
  }
}
//endregion

//region --- SERVICES ---
class ApiService {
  final AuthService _authService = AuthService();
  static const String baseRoot = 'http://127.0.0.1:8000/api'; // Use 10.0.2.2 para emulador Android

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Usuario> fetchUsuario() async {
    final url = Uri.parse('$baseRoot/usuarios/me/');
    final res = await http.get(url, headers: await _getHeaders());
    if (res.statusCode == 200) {
      return Usuario.fromJson(json.decode(utf8.decode(res.bodyBytes)));
    } else {
      throw Exception('Falha ao carregar dados do usuário');
    }
  }

  Future<List<Atividade>> fetchAtividades() async {
    final url = Uri.parse('$baseRoot/atividades/');
    final res = await http.get(url, headers: await _getHeaders());
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) => Atividade.fromJson(e)).toList();
    } else {
      throw Exception('Falha ao carregar atividades');
    }
  }
  
  // Busca apenas as 5 conquistas mais recentes do usuário
  Future<List<Conquista>> fetchUsuarioConquistas() async {
    final url = Uri.parse('$baseRoot/conquistas/usuario/');
    final res = await http.get(url, headers: await _getHeaders());
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      return data.map((e) => Conquista.fromJson(e, desbloqueada: true)).take(5).toList();
    } else {
      throw Exception('Falha ao carregar conquistas do usuário');
    }
  }

  // Busca os desafios pendentes
  Future<List<DesafioPendente>> fetchDesafiosPendentes() async {
    // NOTA: O ideal é que a API tenha um endpoint específico para desafios *pendentes*
    // com o progresso atual. Aqui, estamos adaptando o endpoint de desafios gerais.
    final url = Uri.parse('$baseRoot/desafios/');
    final res = await http.get(url, headers: await _getHeaders());
    if (res.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
      // Pegando apenas o primeiro desafio para a UI
      return data.map((e) => DesafioPendente.fromJson(e)).take(1).toList();
    } else {
      throw Exception('Falha ao carregar desafios');
    }
  }

  Future<bool> realizarAtividade(int atividadeId) async {
    final url = Uri.parse('$baseRoot/atividades/$atividadeId/realizar/');
    final res = await http.post(url, headers: await _getHeaders());
    return res.statusCode == 200;
  }
}
//endregion

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
  List<DesafioPendente> _desafios = [];
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
      final results = await Future.wait([
        _apiService.fetchUsuario(),
        _apiService.fetchAtividades(),
        _apiService.fetchUsuarioConquistas(),
        _apiService.fetchDesafiosPendentes(),
      ]);

      if (!mounted) return;
      setState(() {
        _usuario = results[0] as Usuario;
        _atividades = results[1] as List<Atividade>;
        _conquistas = results[2] as List<Conquista>;
        _desafios = results[3] as List<DesafioPendente>;
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
      _carregarDados();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível realizar a atividade.')),
      );
    }
  }

  void _handleMenuSelection(String value) {
    if (value == 'sair') {
      _authService.logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (Route<dynamic> route) => false,
      );
    }
    // TODO: Implementar navegação para outras telas (Configuração, Relatório, etc.)
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundoEscuro,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregarDados,
          color: AppColors.verdeLima,
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
        child: const Icon(Icons.add, color: AppColors.fundoEscuro, size: 30),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.roxoHeader,
      pinned: true,
      elevation: 0,
      toolbarHeight: 60,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          _usuario?.nome ?? 'GamefyME',
          style: const TextStyle(fontSize: 24),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: [
        if (_screenState == ScreenState.loaded && _usuario != null)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildUserMenuButton(_usuario!),
          ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_screenState) {
      case ScreenState.loading:
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator(color: AppColors.verdeLima)),
        );
      case ScreenState.error:
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Erro ao carregar dados.', style: TextStyle(color: AppColors.branco)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _carregarDados,
                  child: const Text('Tentar Novamente'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.roxoClaro),
                ),
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
              _buildUserInfoCard(_usuario!),
              const SizedBox(height: 16),
              _buildStreakAndConquistasCard(_usuario!.streakData, _conquistas),
              const SizedBox(height: 16),
              _buildSectionTitle("Desafios pendentes"),
              ..._desafios.map((d) => _buildDesafioCard(d)).toList(),
              const SizedBox(height: 16),
              _buildSectionTitle("Atividades"),
              _buildAtividadesSection(filteredActivities),
            ]),
          ),
        );
    }
  }

 Widget _buildUserMenuButton(Usuario user) {
  return PopupMenuButton<String>(
    onSelected: _handleMenuSelection,
    color: AppColors.fundoCard,
    offset: const Offset(0, 50),
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        enabled: false,
        child: Column(
          children: [
            _buildUserLevelAvatar(user, radius: 40),
            const SizedBox(height: 10),
            const Divider(color: AppColors.cinzaSub),
          ],
        ),
      ),
      _buildPopupMenuItem(icon: Icons.settings, text: 'Configuração', value: 'config'),
      _buildPopupMenuItem(icon: Icons.bar_chart, text: 'Relatório', value: 'relatorio'),
      _buildPopupMenuItem(icon: Icons.emoji_events, text: 'Desafios', value: 'desafios'),
      _buildPopupMenuItem(icon: Icons.star, text: 'Conquistas', value: 'conquistas'),
      _buildPopupMenuItem(icon: Icons.list_alt, text: 'Atividades', value: 'atividades'),
      const PopupMenuDivider(height: 1),
      _buildPopupMenuItem(icon: Icons.exit_to_app, text: 'Sair', value: 'sair'),
    ],
    child: _buildUserLevelAvatar(user, radius: 24),
  );
}

PopupMenuEntry<String> _buildPopupMenuItem({required IconData icon, required String text, required String value}) {
  return PopupMenuItem<String>(
    value: value,
    child: Row(
      children: [
        Icon(icon, color: AppColors.branco),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: AppColors.branco)),
      ],
    ),
  );
}


  Widget _buildUserLevelAvatar(Usuario user, {required double radius}) {
    final progress = user.exp / max(1, user.expTotalNivel);
    return SizedBox(
      width: (radius + 6) * 2,
      height: (radius + 6) * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: AppColors.roxoProfundo,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.verdeLima),
            ),
          ),
          CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.fundoCard,
            child: CircleAvatar(
              radius: radius - 4,
              backgroundImage: AssetImage("assets/avatares/${user.imagemPerfil}"),
              onBackgroundImageError: (_, __) {},
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.roxoProfundo,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fundoEscuro, width: 2),
              ),
              child: Text(
                user.nivel.toString(),
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(Usuario user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.roxoProfundo,
            child: CircleAvatar(
              radius: 46,
              backgroundImage: AssetImage("assets/avatares/${user.imagemPerfil}"),
              onBackgroundImageError: (_, __) {},
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.nome,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakAndConquistasCard(List<StreakDia> streakData, List<Conquista> conquistas) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Conquistas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: conquistas
                .map((c) => Image.asset("assets/conquistas/${c.imagem}", width: 32, height: 32))
                .toList(),
          ),
          const Divider(color: AppColors.cinzaSub, height: 24),
          const Text("Dias contínuos de atividades", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: streakData
                .map((dia) => Column(
                      children: [
                        Text(dia.diaSemana, style: const TextStyle(fontSize: 12, color: AppColors.cinzaSub)),
                        const SizedBox(height: 4),
                        Image.asset("assets/images/${dia.imagem}", width: 24),
                      ],
                    ))
                .toList(),
          )
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(color: AppColors.branco, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDesafioCard(DesafioPendente desafio) {
    double progresso = desafio.progresso / max(1, desafio.meta);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desafio.nome, style: const TextStyle(color: AppColors.branco, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progresso,
                        backgroundColor: AppColors.roxoProfundo,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.amareloClaro),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text("${desafio.progresso}/${desafio.meta}", style: const TextStyle(color: AppColors.cinzaSub, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text("${desafio.xp}xp", style: const TextStyle(color: AppColors.amareloClaro, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAtividadesSection(List<Atividade> atividades) {
    return Column(
      children: [
        TextField(
          onChanged: (value) => setState(() => _searchText = value),
          style: const TextStyle(color: AppColors.branco),
          decoration: InputDecoration(
            hintText: "Nome da atividade",
            prefixIcon: const Icon(Icons.search, color: AppColors.cinzaSub),
            filled: true,
            fillColor: AppColors.fundoCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (atividades.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text("Nenhuma atividade encontrada.", style: TextStyle(color: AppColors.cinzaSub)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: atividades.length,
            itemBuilder: (context, index) {
              final atividade = atividades[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.roxoMedio,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.verdeLima, size: 28),
                    onPressed: () => _realizarAtividade(atividade),
                  ),
                  title: Text(atividade.nome, style: const TextStyle(color: AppColors.branco)),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.cinzaSub),
                    onPressed: () { /* TODO: Implementar lógica de remover/cancelar */ },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}