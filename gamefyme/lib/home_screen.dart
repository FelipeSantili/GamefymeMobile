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
      debugPrint(
          'Dados de Streak Recebidos: ${_usuario?.streakData.map((e) => e.imagem).toList()}');
    } catch (e) {
      debugPrint('Erro ao carregar dados da home: $e');
      if (!mounted) return;
      setState(() => _screenState = ScreenState.error);
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
      // colocamos os botões no title pra ficar alinhado à esquerda como antes
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
    return PopupMenuButton<int>(
      onSelected: (id) async {
        await _apiService.marcarNotificacaoComoLida(id);
        _carregarDados();
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

  Widget _buildChallengesAchievementsButton() {
  // filtra apenas desafios diários e ordena (ex: por id)
  final diarios = _desafios
      .where((d) => d.tipo.trim().toLowerCase() == 'diario')
      .toList()
    ..sort((a, b) => a.id.compareTo(b.id));

  return PopupMenuButton<int>(
    color: AppColors.fundoCard,
    icon: const Icon(Icons.emoji_events, color: AppColors.verdeLima, size: 30),
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
                    const Text("Nenhum desafio diário", style: TextStyle(color: AppColors.cinzaSub))
                  else
                    Column(
                      children: diarios.map((d) {
                        double progresso = d.progresso / max(1, d.meta);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.cinzaSub,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.nome, style: const TextStyle(color: AppColors.branco, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    LinearProgressIndicator(
                                      value: progresso,
                                      backgroundColor: AppColors.roxoProfundo,
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.amareloClaro),
                                      minHeight: 6,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text("${d.progresso}/${d.meta}", style: const TextStyle(color: AppColors.branco)),
                              const SizedBox(width: 8),
                              Text("${d.xp}xp", style: const TextStyle(color: AppColors.amareloClaro, fontWeight: FontWeight.bold)),
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
                    const Text("Nenhuma conquista", style: TextStyle(color: AppColors.cinzaSub))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _conquistas.take(20).map((c) {
                        return SizedBox(
                          width: 40,
                          height: 40,
                          child: Image.asset("assets/conquistas/${c.imagem}", fit: BoxFit.contain),
                        );
                      }).toList(),
                    ),
                  if (_conquistas.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('${_conquistas.length} conquistas', style: const TextStyle(color: AppColors.cinzaSub)),
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
        final filteredActivities = _atividades
            .where(
              (a) => a.nome.toLowerCase().contains(_searchText.toLowerCase()),
            )
            .toList();

        // altura fixa para os cards de perfil + streak para manter mesma altura
        const double cardHeight = 220;

        return SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // card de perfil com largura fixa
                  SizedBox(
                    width: 150,
                    height: cardHeight,
                    child: _buildUserInfoCard(_usuario!),
                  ),
                  const SizedBox(width: 16),
                  // streak com maior largura (flex maior) e mesma altura
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: cardHeight,
                      child: _buildStreakCard(_usuario!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Removemos o card de conquistas e a seção de desafios do corpo principal.
              // Agora essas informações ficam no botão de Desafios & Conquistas no AppBar.

              _buildAtividadesSection(filteredActivities),
            ]),
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
      // largura controlada pelo SizedBox que envolve este widget na row
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

  Widget _buildAchievementsCard(List<Conquista> conquistas) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Conquistas",
              style: TextStyle(
                color: AppColors.branco,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            children: conquistas.take(10).map((c) {
              return SizedBox(
                width: 40,
                height: 40,
                child: Image.asset(
                  "assets/conquistas/${c.imagem}",
                  fit: BoxFit.contain,
                ),
              );
            }).toList(),
          ),
          if (conquistas.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${conquistas.length} conquistas',
              style: const TextStyle(color: AppColors.cinzaSub, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStreakCard(Usuario usuario) {
    final double progress = usuario.expTotalNivel > 0
        ? usuario.exp.toDouble() / usuario.expTotalNivel.toDouble()
        : 0;

    return Container(
      // altura controlada pelo SizedBox que envolve este widget na row
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
                return Column(
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
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Barra de XP
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

  Widget _buildDesafioCard(DesafioPendente desafio) {
    double progresso = desafio.progresso / max(1, desafio.meta);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cinzaSub,
        borderRadius: BorderRadius.circular(5),
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
                        color: AppColors.branco,
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
    return Container(
      height: 369,
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
            style: const TextStyle(
                color: AppColors.branco, fontFamily: 'Jersey 10'),
            decoration: InputDecoration(
              hintText: "Nome da atividade",
              hintStyle: const TextStyle(color: AppColors.cinzaSub),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.cinzaSub),
              filled: true,
              fillColor: const Color(0xFFD9D9D9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: atividades.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "Nenhuma atividade encontrada.",
                      style: TextStyle(color: AppColors.cinzaSub),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
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
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Não'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
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
                  ),
          ),
        ],
      ),
    );
  }
}
