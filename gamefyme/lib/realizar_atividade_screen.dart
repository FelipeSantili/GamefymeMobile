import 'dart:async';
import 'package:flutter/material.dart';
import 'config/app_colors.dart';
import 'services/api_service.dart';
import 'models/models.dart';
import 'widgets/user_level_avatar.dart'; // Importa o novo widget

// Enum para gerenciar os estados da tela
enum ScreenState { loading, loaded, error }

class RealizarAtividadeScreen extends StatefulWidget {
  final int atividadeId;

  const RealizarAtividadeScreen({super.key, required this.atividadeId});

  @override
  State<RealizarAtividadeScreen> createState() =>
      _RealizarAtividadeScreenState();
}

class _RealizarAtividadeScreenState extends State<RealizarAtividadeScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  ScreenState _screenState = ScreenState.loading;
  Atividade? _atividade;
  Usuario? _usuario; // Adicionado para obter os dados do usuário

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
    super.dispose();
  }

  Future<void> _carregarDadosAtividade() async {
    if (!mounted) return;
    setState(() => _screenState = ScreenState.loading);

    try {
      final atividadeResult = await _apiService.fetchAtividade(widget.atividadeId);
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
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível realizar a atividade.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int get dificuldadeMoedas {
    switch (_atividade?.dificuldade) {
      case 'muito_facil': return 1;
      case 'facil': return 2;
      case 'medio': return 3;
      case 'dificil': return 4;
      case 'muito_dificil': return 5;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundoCard,
      appBar: AppBar(
        title: Text(
          _atividade?.nome.toUpperCase() ?? 'CARREGANDO...',
          style: const TextStyle(fontFamily: 'Jersey 10', fontSize: 24),
        ),
        backgroundColor: AppColors.roxoHeader,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
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
        return const Center(child: CircularProgressIndicator(color: AppColors.verdeLima));
      case ScreenState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Erro ao carregar a atividade.', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _carregarDadosAtividade,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        );
      case ScreenState.loaded:
        return Column(
          children: [
            _buildStreakCard(),
            Expanded(child: _buildTimerSection()),
            _buildFooter(),
          ],
        );
    }
  }

  Widget _buildStreakCard() {
    return Container(
      color: AppColors.fundoCard,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.roxoHeader,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Dias contínuos de atividades",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _usuario!.streakData.map((dia) => Column(
                children: [
                  Text(dia.diaSemana, style: const TextStyle(fontSize: 12, color: AppColors.cinzaSub)),
                  const SizedBox(height: 4),
                  Image.asset("assets/images/${dia.imagem}", width: 24),
                ],
              )).toList(),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _usuario!.streakData.where((d) => d.imagem != 'fogo-inativo.png').length / 7,
              backgroundColor: AppColors.roxoProfundo,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.roxoClaro),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(_duration.inMinutes.remainder(60));
    final seconds = twoDigits(_duration.inSeconds.remainder(60));
    final progress = _maxDuration.inSeconds > 0 ? _duration.inSeconds / _maxDuration.inSeconds : 0.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: AppColors.roxoProfundo,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.verdeLima),
                ),
                Center(
                  child: Text(
                    '$minutes:$seconds',
                    style: const TextStyle(
                      fontFamily: 'Jersey 10',
                      fontSize: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 60),
                onPressed: _isTimerRunning ? _stopTimer : _startTimer,
              ),
              const SizedBox(width: 40),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 60),
                onPressed: _resetTimer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      color: AppColors.roxoHeader,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Text(
            _atividade?.nome.toUpperCase() ?? 'CARREGANDO...',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.fundoCard, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: List.generate(dificuldadeMoedas, (index) => const Icon(Icons.monetization_on, color: AppColors.amareloClaro, size: 24)),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: AppColors.fundoCard, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  _atividade?.recorrencia.toUpperCase() ?? 'ÚNICA',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.fundoCard, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('CANCELAR', style: TextStyle(color: AppColors.cinzaSub)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _concluirAtividade,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.fundoCard, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('CONCLUIR', style: TextStyle(color: AppColors.branco)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}