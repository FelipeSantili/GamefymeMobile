// Modelo para os dados do usuário principal
class Usuario {
  final int id;
  final String nome;
  final String imagemPerfil;
  final int nivel;
  final int exp;
  final int expTotalNivel;
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
    var streakList =
        (json['streak_data'] as List<dynamic>?)
            ?.map((e) => StreakDia.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return Usuario(
      id: json['idusuario'] ?? 0,
      nome: json['nmusuario'] ?? 'Usuário',
      imagemPerfil: json['imagem_perfil'] ?? 'avatar1.png',
      nivel: json['nivelusuario'] ?? 1,
      exp: json['expusuario'] ?? 0,
      expTotalNivel: json['exp_total_nivel'] ?? 1000,
      streakAtual: json['streak_atual'] ?? 0,
      streakData: streakList,
    );
  }
}

// Modelo para os dias da semana no card de streak
class StreakDia {
  final String diaSemana;
  final String imagem;

  StreakDia({required this.diaSemana, required this.imagem});

  factory StreakDia.fromJson(Map<String, dynamic> json) {
    return StreakDia(
      diaSemana: json['dia_semana'] ?? 'N/A',
      imagem: json['imagem'] ?? 'fogo-inativo.png',
    );
  }
}

// Modelo para a lista de atividades na tela principal
// Modelo para a lista de atividades na tela principal
class Atividade {
  final int id;
  final String nome;
  final String descricao;
  final String dificuldade;
  final String recorrencia;
  final int tpEstimado; // em minutos
  final int xp;
  final int nivelUsuario; // Adicionado para o ícone de perfil

  Atividade({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.dificuldade,
    required this.recorrencia,
    required this.tpEstimado,
    required this.xp,
    required this.nivelUsuario,
  });

  factory Atividade.fromJson(Map<String, dynamic> json) {
    return Atividade(
      id: json['idatividade'] ?? 0,
      nome: json['nmatividade'] ?? 'Atividade sem nome',
      descricao: json['dsatividade'] ?? '',
      dificuldade: json['dificuldade'] ?? 'medio',
      recorrencia: json['recorrencia'] ?? 'unica',
      tpEstimado: json['tpestimado'] ?? 0,
      xp: json['expatividade'] ?? 0,
      nivelUsuario: json['nivelusuario'] ?? 1,
    );
  }
}

// Modelo para os desafios pendentes
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
      progresso: json['progresso_atual'] ?? 0,
      meta: json['parametro'] ?? 1,
      xp: json['expdesafio'] ?? 0,
    );
  }
}

// Modelo para as conquistas
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

  factory Conquista.fromJson(
    Map<String, dynamic> json, {
    bool desbloqueada = false,
  }) {
    final conquistaData = json.containsKey('conquista')
        ? json['conquista']
        : json;

    return Conquista(
      id: conquistaData['idconquista'] ?? 0,
      nome: conquistaData['nmconquista'] ?? '',
      imagem: conquistaData['nmimagem'] ?? 'recorrencia.png',
      desbloqueada: desbloqueada,
    );
  }
}

// Modelo para as notificações
class Notificacao {
  final int id;
  final String mensagem;
  final String tipo;
  final bool lida;

  Notificacao({
    required this.id,
    required this.mensagem,
    required this.tipo,
    required this.lida,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    return Notificacao(
      id: json['idnotificacao'] ?? 0,
      mensagem: json['dsmensagem'] ?? 'Mensagem indisponível',
      tipo: json['fltipo'] ?? 'info',
      lida: json['flstatus'] ?? false,
    );
  }
}
