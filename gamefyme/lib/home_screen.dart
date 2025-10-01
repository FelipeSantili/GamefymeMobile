import 'package:flutter/material.dart';
import 'package:gamefymobile/cadastro_atividade_screen.dart';
import 'dart:math';

import 'config/app_colors.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'models/models.dart';
import 'main.dart';
import 'realizar_atividade_screen.dart';
import 'widgets/user_level_avatar.dart';

enum ScreenState { loading, loaded, error }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  ScreenState _screenState = ScreenState.loading;
  Usuario? _usuario;
  List<Atividade> _atividades = [];
  List<Conquista> _conquistas = [];
  List<DesafioPendente> _desafios = [];
  List<Notificacao> _notificacoes = [];
  String _searchText = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      debugPrint(
          'Dados de Streak Recebidos: ${_usuario?.streakData.map((e) => e.imagem).toList()}');
    } catch (e) {
      debugPrint('Erro ao carregar dados da home: $e');
      if (!mounted) return;
      setState(() => _screenState = ScreenState.error);
    }
  }

  Future<void> _showNotificationDetails(Notificacao notificacao) async {
    // Marcar a notificação como lida na API
    await _apiService.marcarNotificacaoComoLida(notificacao.id);

    // Atualizar o estado local da notificação para que ela apareça como lida sem recarregar a tela
    setState(() {
      final index = _notificacoes.indexWhere((n) => n.id == notificacao.id);
      if (index != -1) {
        _notificacoes[index] = Notificacao(
          id: notificacao.id,
          mensagem: notificacao.mensagem,
          tipo: notificacao.tipo,
          lida: true, // Marcar como lida
        );
      }
    });

    // Mostrar o modal
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.fundoCard,
          title: const Text(
            'Notificação',
            style: TextStyle(color: AppColors.branco),
          ),
          content: Text(
            notificacao.mensagem,
            style: const TextStyle(color: AppColors.branco),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Fechar',
                style: TextStyle(color: AppColors.verdeLima),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
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
  }

  Future<void> _showAvatarModal() async {
    final newAvatar = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.fundoCard,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: List.generate(4, (index) {
              final avatarName = 'avatar${index + 1}.png';
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(avatarName),
                child: Image.asset('assets/avatares/$avatarName'),
              );
            }),
          ),
        );
      },
    );

    if (newAvatar != null && newAvatar != _usuario?.imagemPerfil) {
      final success = await _apiService.updateProfilePicture(newAvatar);
      if (success) {
        _carregarDados();
      }
    }
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
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          _buildNotificationButton(naoLidas),
          const SizedBox(width: 16),
          _buildChallengesAchievementsButton(),
        ],
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

  Widget _buildNotificationButton(int naoLidas) {
    return PopupMenuButton<Notificacao>(
      onSelected: (notificacao) {
        _showNotificationDetails(notificacao);
      },
      color: AppColors.fundoCard,
      icon: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.mail, color: AppColors.verdeLima, size: 30),
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
          return PopupMenuItem<Notificacao>(
            value: notificacao,
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

  Widget _buildChallengesAchievementsButton() {
    final diarios = _desafios
        .where((d) => d.tipo.trim().toLowerCase() == 'diario')
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return PopupMenuButton<int>(
      color: AppColors.fundoCard,
      icon:
          const Icon(Icons.emoji_events, color: AppColors.verdeLima, size: 30),
      offset: const Offset(0, 50),
      itemBuilder: (context) {
        return [
          PopupMenuItem<int>(
            enabled: false,
            child: Container(
              width: 320,
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Desafios diários",
                      style: TextStyle(
                          color: AppColors.branco,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    if (diarios.isEmpty)
                      const Text("Nenhum desafio diário",
                          style: TextStyle(color: AppColors.cinzaSub))
                    else
                      Column(
                        children: diarios.map((d) {
                          double progresso = d.progresso / max(1, d.meta);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.cinzaSub,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(d.nome,
                                          style: const TextStyle(
                                              color: AppColors.branco,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 6),
                                      LinearProgressIndicator(
                                        value: progresso,
                                        backgroundColor:
                                            AppColors.roxoProfundo,
                                        valueColor:
                                            const AlwaysStoppedAnimation<
                                                Color>(AppColors.amareloClaro),
                                        minHeight: 6,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text("${d.progresso}/${d.meta}",
                                    style: const TextStyle(
                                        color: AppColors.branco)),
                                const SizedBox(width: 8),
                                Text("${d.xp}xp",
                                    style: const TextStyle(
                                        color: AppColors.amareloClaro,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.roxoProfundo),
                    const SizedBox(height: 8),
                    const Text(
                      "Conquistas",
                      style: TextStyle(
                          color: AppColors.branco,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    if (_conquistas.isEmpty)
                      const Text("Nenhuma conquista",
                          style: TextStyle(color: AppColors.cinzaSub))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _conquistas.take(20).map((c) {
                          return SizedBox(
                            width: 40,
                            height: 40,
                            child: Image.asset("assets/conquistas/${c.imagem}",
                                fit: BoxFit.contain),
                          );
                        }).toList(),
                      ),
                    if (_conquistas.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('${_conquistas.length} conquistas',
                          style: const TextStyle(color: AppColors.cinzaSub)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ];
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.roxoClaro,
                  ),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        );
      case ScreenState.loaded:
        if (_usuario == null) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.verdeLima),
            ),
          );
        }
        // Use SliverToBoxAdapter to place a regular widget inside the CustomScrollView.
        return SliverToBoxAdapter(
          child: Container(
            // Calculate height to fill the screen minus app bar and status bar.
            height: MediaQuery.of(context).size.height -
                kToolbarHeight -
                MediaQuery.of(context).padding.top,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Top section with user cards (fixed height)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 220,
                      child: _buildUserInfoCard(_usuario!),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 220,
                        child: _buildStreakCard(_usuario!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Activities section expands to fill the remaining space
                Expanded(
                  child: _buildAtividadesSection(),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildUserMenuButton(Usuario user) {
    return PopupMenuButton<String>(
      onSelected: _handleMenuSelection,
      color: AppColors.fundoDropDown,
      offset: const Offset(0, 50),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildPopupMenuItem(text: 'Configuração', value: 'config'),
        _buildPopupMenuItem(text: 'Relatório', value: 'relatorio'),
        _buildPopupMenuItem(text: 'Desafios', value: 'desafios'),
        _buildPopupMenuItem(text: 'Conquistas', value: 'conquistas'),
        _buildPopupMenuItem(text: 'Atividades', value: 'atividades'),
        _buildPopupMenuItem(text: 'Sair', value: 'sair'),
      ],
      child: UserLevelAvatar(user: user, radius: 24),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({
    required String text,
    required String value,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.botaoDropDown,
          borderRadius: BorderRadius.circular(5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Jersey 10',
              color: AppColors.branco,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(Usuario user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: GestureDetector(
        onTap: _showAvatarModal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.branco,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(Usuario usuario) {
    final double progress = usuario.expTotalNivel > 0
        ? usuario.exp.toDouble() / usuario.expTotalNivel.toDouble()
        : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Dias contínuos de atividades",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.branco,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: usuario.streakData.map((dia) {
                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dia.diaSemana,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.branco,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Image.asset(
                        'assets/images/${dia.imagem}',
                        width: 28,
                        height: 28,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${usuario.exp} XP',
                    style: const TextStyle(
                        color: AppColors.branco, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Nível ${usuario.nivel}',
                    style: const TextStyle(
                        color: AppColors.branco, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${usuario.expTotalNivel} XP',
                    style: const TextStyle(
                        color: AppColors.branco, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.roxoProfundo,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.verdeLima),
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAtividadesSection() {
    final atividadesRecorrentes = _atividades
        .where((a) =>
            a.recorrencia != 'unica' &&
            a.situacao == 'ativa' &&
            a.nome.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();

    final atividadesUnicas = _atividades
        .where((a) =>
            a.recorrencia == 'unica' &&
            a.situacao == 'ativa' &&
            a.nome.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchText = value),
            style:
                const TextStyle(color: AppColors.branco, fontFamily: 'Jersey 10'),
            decoration: InputDecoration(
              hintText: "Nome da atividade",
              hintStyle: const TextStyle(color: AppColors.cinzaSub),
              prefixIcon: const Icon(Icons.search, color: AppColors.cinzaSub),
              filled: true,
              fillColor: const Color(0xFFD9D9D9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Recorrentes'),
              Tab(text: 'Únicas'),
            ],
            labelColor: AppColors.verdeLima,
            unselectedLabelColor: AppColors.cinzaSub,
            indicatorColor: AppColors.verdeLima,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAtividadesList(atividadesRecorrentes),
                _buildAtividadesList(atividadesUnicas),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtividadesList(List<Atividade> atividades) {
    if (atividades.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "Nenhuma atividade encontrada.",
            style: TextStyle(color: AppColors.cinzaSub),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: atividades.length,
      itemBuilder: (context, index) {
        final atividade = atividades[index];
        return Container(
          margin: const EdgeInsets.only(top: 8),
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
                final confirmDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Remover Atividade?'),
                    content: Text(
                      'Você tem certeza que deseja remover a atividade "${atividade.nome}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Não'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Sim'),
                      ),
                    ],
                  ),
                );

                if (confirmDelete == true) {
                  final success =
                      await _apiService.cancelAtividade(atividade.id);
                  if (success) {
                    _carregarDados();
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }
}