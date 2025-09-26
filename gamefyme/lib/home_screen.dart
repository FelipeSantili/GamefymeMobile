import 'package:flutter/material.dart';
import 'package:gamefymobile/realizar_atividade_screen.dart';
import 'dart:math';

import 'config/app_colors.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'models/models.dart';
import 'main.dart';
import 'cadastro_atividade_screen.dart';

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
  List<Notificacao> _notificacoes = [];
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
        _apiService.fetchNotificacoes(),
      ]);

      if (!mounted) return;
      setState(() {
        _usuario = results[0] as Usuario;
        _atividades = results[1] as List<Atividade>;
        _conquistas = results[2] as List<Conquista>;
        _desafios = results[3] as List<DesafioPendente>;
        _notificacoes = results[4] as List<Notificacao>;
        _screenState = ScreenState.loaded;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados da home: $e');
      if (!mounted) return;
      setState(() => _screenState = ScreenState.error);
    }
  }

  Future<bool?> _showRemoveConfirmationDialog(Atividade atividade) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C), // Cor de fundo do modal
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.roxoClaro,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Remover\nAtividade?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Nome da Atividade
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.roxoProfundo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  atividade.nome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),

              // Botões de Ação
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(true), // Retorna true
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.roxoClaro,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Sim",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(false), // Retorna false
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.roxoClaro,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Não",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleMenuSelection(String value) {
    if (value == 'sair') {
      _authService.logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (Route<dynamic> route) => false,
      );
    }
    // TODO: Implementar navegação para outras telas
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
          child: CustomScrollView(slivers: [_buildAppBar(), _buildBody()]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.verdeLima,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CadastroAtividadeScreen(),
            ),
          );
          if (result == true) {
            _carregarDados();
          }
        },
        child: const Icon(Icons.add, color: AppColors.fundoEscuro, size: 30),
      ),
    );
  }

  Widget _buildAppBar() {
    int naoLidas = _notificacoes.where((n) => !n.lida).length;

    return SliverAppBar(
      backgroundColor: AppColors.roxoHeader,
      pinned: true,
      elevation: 0,
      toolbarHeight: 60,
      automaticallyImplyLeading: false, // Remove o botão de voltar
      title: Text(
        _usuario?.nome ?? 'GamefyME',
        style: const TextStyle(fontSize: 24),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        _buildNotificationButton(naoLidas),
        if (_screenState == ScreenState.loaded && _usuario != null)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildUserMenuButton(_usuario!),
          ),
      ],
    );
  }

  Widget _buildNotificationButton(int naoLidas) {
    return PopupMenuButton<int>(
      onSelected: (id) async {
        await _apiService.marcarNotificacaoComoLida(id);
        _carregarDados();
      },
      color: AppColors.fundoCard,
      icon: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.notifications, color: AppColors.branco, size: 30),
          if (naoLidas > 0)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.roxoHeader, width: 2),
                ),
                child: Text(
                  '$naoLidas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      itemBuilder: (context) {
        if (_notificacoes.isEmpty) {
          return [
            const PopupMenuItem(
              enabled: false,
              child: Text(
                "Nenhuma notificação",
                style: TextStyle(color: AppColors.cinzaSub),
              ),
            ),
          ];
        }
        return _notificacoes.map((notificacao) {
          return PopupMenuItem<int>(
            value: notificacao.id,
            child: ListTile(
              leading: Icon(
                notificacao.lida
                    ? Icons.check_circle_outline
                    : Icons.circle_notifications,
                color: notificacao.lida
                    ? AppColors.cinzaSub
                    : AppColors.amareloClaro,
              ),
              title: Text(
                notificacao.mensagem,
                style: TextStyle(
                  color: notificacao.lida
                      ? AppColors.cinzaSub
                      : AppColors.branco,
                ),
              ),
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildBody() {
    switch (_screenState) {
      case ScreenState.loading:
        return const SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.verdeLima),
          ),
        );
      case ScreenState.error:
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Erro ao carregar dados.',
                  style: TextStyle(color: AppColors.branco),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _carregarDados,
                  child: const Text('Tentar Novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.roxoClaro,
                  ),
                ),
              ],
            ),
          ),
        );
      case ScreenState.loaded:
        final filteredActivities = _atividades
            .where(
              (a) => a.nome.toLowerCase().contains(_searchText.toLowerCase()),
            )
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
        _buildPopupMenuItem(
          icon: Icons.settings,
          text: 'Configuração',
          value: 'config',
        ),
        _buildPopupMenuItem(
          icon: Icons.bar_chart,
          text: 'Relatório',
          value: 'relatorio',
        ),
        _buildPopupMenuItem(
          icon: Icons.emoji_events,
          text: 'Desafios',
          value: 'desafios',
        ),
        _buildPopupMenuItem(
          icon: Icons.star,
          text: 'Conquistas',
          value: 'conquistas',
        ),
        _buildPopupMenuItem(
          icon: Icons.list_alt,
          text: 'Atividades',
          value: 'atividades',
        ),
        const PopupMenuDivider(height: 1),
        _buildPopupMenuItem(
          icon: Icons.exit_to_app,
          text: 'Sair',
          value: 'sair',
        ),
      ],
      child: _buildUserLevelAvatar(user, radius: 24),
    );
  }

  PopupMenuEntry<String> _buildPopupMenuItem({
    required IconData icon,
    required String text,
    required String value,
  }) {
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
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.verdeLima,
              ),
            ),
          ),
          CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.fundoCard,
            child: CircleAvatar(
              radius: radius - 4,
              backgroundImage: AssetImage(
                "assets/avatares/${user.imagemPerfil}",
              ),
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
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
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
              backgroundImage: AssetImage(
                "assets/avatares/${user.imagemPerfil}",
              ),
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

  Widget _buildStreakAndConquistasCard(
    List<StreakDia> streakData,
    List<Conquista> conquistas,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Conquistas",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: conquistas
                .map(
                  (c) => Image.asset(
                    "assets/conquistas/${c.imagem}",
                    width: 32,
                    height: 32,
                  ),
                )
                .toList(),
          ),
          const Divider(color: AppColors.cinzaSub, height: 24),
          const Text(
            "Dias contínuos de atividades",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: streakData
                .map(
                  (dia) => Column(
                    children: [
                      Text(
                        dia.diaSemana,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.cinzaSub,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Image.asset("assets/images/${dia.imagem}", width: 24),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.branco,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
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
                Text(
                  desafio.nome,
                  style: const TextStyle(
                    color: AppColors.branco,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progresso,
                        backgroundColor: AppColors.roxoProfundo,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.amareloClaro,
                        ),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${desafio.progresso}/${desafio.meta}",
                      style: const TextStyle(
                        color: AppColors.cinzaSub,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "${desafio.xp}xp",
            style: const TextStyle(
              color: AppColors.amareloClaro,
              fontWeight: FontWeight.bold,
            ),
          ),
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
            child: Text(
              "Nenhuma atividade encontrada.",
              style: TextStyle(color: AppColors.cinzaSub),
            ),
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
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppColors.verdeLima,
                      size: 28,
                    ),
                    // A NAVEGAÇÃO AGORA ACONTECE AQUI
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RealizarAtividadeScreen(
                            atividadeId: atividade.id,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        _carregarDados();
                      }
                    },
                  ),
                  title: Text(
                    atividade.nome,
                    style: const TextStyle(color: AppColors.branco),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: AppColors.cinzaSub,
                    ),
                    onPressed: () async {
                      // Chama o diálogo de confirmação
                      final bool? confirmDelete =
                          await _showRemoveConfirmationDialog(atividade);

                      // Se o usuário confirmou e o widget ainda está na tela
                      if (confirmDelete == true && mounted) {
                        final success = await _apiService.deleteAtividade(
                          atividade.id,
                        );

                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '"${atividade.nome}" removida com sucesso.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _carregarDados(); // Atualiza a lista de atividades
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Erro ao remover a atividade. Tente novamente.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
