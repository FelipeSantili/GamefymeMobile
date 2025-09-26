import 'package:flutter/material.dart';
import 'package:gamefymobile/cadastro_atividade_screen.dart';
import 'dart:math';

import 'config/app_colors.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'models/models.dart';
import 'main.dart';
import 'realizar_atividade_screen.dart';
import 'widgets/user_level_avatar.dart'; // Importa o novo widget

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
      title: _buildNotificationButton(naoLidas),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserInfoCard(_usuario!),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildAchievementsCard(_conquistas),
                        const SizedBox(height: 16),
                        _buildStreakCard(_usuario!.streakData),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildChallengesAndActivitiesSection(filteredActivities),
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
        const PopupMenuDivider(height: 1, color: AppColors.cinzaSub),
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
              color: AppColors.branco,
              fontFamily: 'Jersey 10',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(Usuario user) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: GestureDetector(
        onTap: _showAvatarModal,
        child: CircleAvatar(
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
      ),
    );
  }

  Widget _buildAchievementsCard(List<Conquista> conquistas) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: conquistas
            .map(
              (c) => Image.asset(
                "assets/conquistas/${c.imagem}",
                width: 24,
                height: 24,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildStreakCard(List<StreakDia> streakData) {
    return Container(
      height: 103,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dias contínuos de atividades",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: streakData
                .map(
                  (dia) => Column(
                    children: [
                      Text(
                        dia.diaSemana,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.cinzaSub,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Image.asset("assets/images/${dia.imagem}", width: 20),
                    ],
                  ),
                )
                .toList(),
          ),
          const Spacer(),
          LinearProgressIndicator(
            value:
                streakData.where((d) => d.imagem != 'fogo-inativo.png').length /
                    7,
            backgroundColor: AppColors.roxoProfundo,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.roxoClaro,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesAndActivitiesSection(List<Atividade> atividades) {
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
          const Text(
            "Desafios pendentes",
            style: TextStyle(
              color: AppColors.branco,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._desafios.map((d) => _buildDesafioCard(d)).toList(),
          const SizedBox(height: 16),
          _buildAtividadesSection(atividades),
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
    return Expanded(
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchText = value),
            style: const TextStyle(color: AppColors.branco),
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
          if (atividades.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "Nenhuma atividade encontrada.",
                style: TextStyle(color: AppColors.cinzaSub),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
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
                            final success = await _apiService
                                .cancelAtividade(atividade.id);
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