import 'dart:async';
import 'package:flutter/material.dart';
import 'config/app_colors.dart';
import 'services/api_service.dart';
import 'models/models.dart';
import 'widgets/user_level_avatar.dart';

// Enum para gerenciar os estados da tela
enum ScreenState { loading, loaded, error }

class RealizarAtividadeScreen extends StatefulWidget {
  final int atividadeId;

  const RealizarAtividadeScreen({super.key, required this.atividadeId});

  @override
  State<RealizarAtividadeScreen> createState() =>
      _RealizarAtividadeScreenState();
}

class _RealizarAtividadeScreenState extends State<RealizarAtividadeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController noteController = TextEditingController();

  ScreenState _screenState = ScreenState.loading;
  Atividade? _atividade;
  Usuario? _usuario;

  Timer? _timer;
  Duration _duration = Duration.zero;
  Duration _maxDuration = Duration.zero;
  bool get _isTimerRunning => _timer?.isActive ?? false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _carregarDadosAtividade();
  }

  @override
  void dispose() {
    _timer?.cancel();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosAtividade() async {
    if (!mounted) return;
    setState(() => _screenState = ScreenState.loading);

    try {
      final atividadeResult =
          await _apiService.fetchAtividade(widget.atividadeId);
      final usuarioResult = await _apiService.fetchUsuario();

      if (!mounted) return;

      setState(() {
        _atividade = atividadeResult;
        _usuario = usuarioResult;
        _maxDuration = Duration(minutes: _atividade!.tpEstimado);
        _duration = _maxDuration;
        _screenState = ScreenState.loaded;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados da atividade: $e');
      if (!mounted) return;
      setState(() => _screenState = ScreenState.error);
    }
  }

  void _startTimer() {
    if (_isTimerRunning || _isFinished) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_duration.inSeconds > 0) {
        setState(() => _duration = _duration - const Duration(seconds: 1));
      } else {
        _stopTimer(finished: true);
      }
    });
  }

  void _stopTimer({bool finished = false}) {
    if (finished) {
      setState(() {
        _isFinished = true;
      });
    }
    _timer?.cancel();
    setState(() {});
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _duration = _maxDuration;
      _isFinished = false;
    });
  }

  Future<void> _concluirAtividade() async {
    final success = await _apiService.realizarAtividade(_atividade!.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${_atividade!.nome}" realizada (+${_atividade!.xp} XP)!',
            style: const TextStyle(fontFamily: 'Jersey 10', fontSize: 16),
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível realizar a atividade.',
              style: TextStyle(fontFamily: 'Jersey 10', fontSize: 16)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int get dificuldadeMoedas {
    switch (_atividade?.dificuldade) {
      case 'muito_facil':
        return 1;
      case 'facil':
        return 2;
      case 'medio':
        return 3;
      case 'dificil':
        return 4;
      case 'muito_dificil':
        return 5;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundoEscuro,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.roxoHeader,
        elevation: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        actions: [
          if (_usuario != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: UserLevelAvatar(user: _usuario!, radius: 24),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_screenState) {
      case ScreenState.loading:
        return const Center(
            child: CircularProgressIndicator(color: AppColors.verdeLima));
      case ScreenState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Erro ao carregar a atividade.',
                  style:
                      TextStyle(color: Colors.white, fontFamily: 'Jersey 10')),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _carregarDadosAtividade,
                child: const Text('Tentar Novamente',
                    style: TextStyle(fontFamily: 'Jersey 10')),
              ),
            ],
          ),
        );
      case ScreenState.loaded:
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildActivityStreakSection(context),
                const SizedBox(height: 16),
                _buildTimerSection(context),
                const SizedBox(height: 16),
                _buildTaskSection(context),
                const SizedBox(height: 16),
                _buildButtonsSection(context),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildActivityStreakSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text(
            'Dias continuos de atividades',
            style: TextStyle(
              fontFamily: 'Jersey 10',
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.roxoProfundo,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _usuario!.streakData
                      .map((day) => Text(day.diaSemana,
                          style: const TextStyle(
                              fontFamily: 'Jersey 10',
                              color: AppColors.cinzaSub,
                              fontSize: 14)))
                      .toList(),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _usuario!.streakData
                      .map((day) => Image.asset("assets/images/${day.imagem}",
                          width: 30, height: 30))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: LinearProgressIndicator(
              value: _usuario!.streakData
                      .where((d) => d.imagem != 'fogo-inativo.png')
                      .length /
                  7,
              backgroundColor: AppColors.roxoProfundo,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.roxoClaro),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(_duration.inMinutes.remainder(60));
    final seconds = twoDigits(_duration.inSeconds.remainder(60));
    final progress = _maxDuration.inSeconds > 0
        ? _duration.inSeconds / _maxDuration.inSeconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1 - progress,
                  strokeWidth: 8,
                  backgroundColor: AppColors.roxoProfundo,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.verdeLima),
                ),
                Center(
                  child: Text(
                    '$minutes:$seconds',
                    style: const TextStyle(
                      fontFamily: 'Jersey 10',
                      fontSize: 72,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
                onPressed: _startTimer,
              ),
              IconButton(
                icon: const Icon(Icons.pause, color: Colors.white, size: 48),
                onPressed: _stopTimer,
              ),
              IconButton(
                icon:
                    const Icon(Icons.stop, color: Colors.white, size: 48),
                onPressed: _resetTimer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fundoCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _atividade?.nome ?? '',
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontFamily: 'Jersey 10', fontSize: 32, color: Colors.white),
      ),
    );
  }

  Widget _buildButtonsSection(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 100,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.fundoCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    dificuldadeMoedas,
                    (index) => const Icon(Icons.local_fire_department,
                        color: AppColors.amareloClaro, size: 24)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.fundoCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _atividade?.recorrencia.toUpperCase() ?? 'ÚNICA',
                style: const TextStyle(
                    fontFamily: 'Jersey 10', fontSize: 24, color: Colors.white),
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.fundoCard,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text('CANCELAR',
                    style: TextStyle(
                        color: AppColors.cinzaSub,
                        fontSize: 28,
                        fontFamily: 'Jersey 10')),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _concluirAtividade,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.fundoCard,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text('CONCLUIR',
                    style: TextStyle(
                        color: AppColors.branco,
                        fontSize: 28,
                        fontFamily: 'Jersey 10')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

