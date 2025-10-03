// Modelo para os dados do usuário principal
class Usuario {
  final int id;
  final String nome;
  final String email;
  final int nivel;
  final int exp;
  final int expTotalNivel;
  final String imagemPerfil;
  final List<StreakDia> streakData;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.nivel,
    required this.exp,
    required this.expTotalNivel,
    required this.imagemPerfil,
    required this.streakData,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['idusuario'] ?? 0,
      nome: json['nmusuario'] ?? '',
      email: json['emailusuario'] ?? '',
      nivel: json['nivelusuario'] ?? 1,
      exp: json['expusuario'] ?? 0,
      expTotalNivel: json['exp_total_nivel'] ?? 100,
      imagemPerfil: json['imagem_perfil'] ?? 'avatar1.png',
      streakData: (json['streak_data'] as List<dynamic>? ?? [])
          .map((e) => StreakDia.fromJson(e))
          .toList(),
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
      diaSemana: json['dia_semana'] ?? '',
      imagem: json['imagem'] ?? '',
    );
  }
}

// Modelo para a lista de atividades na tela principal
class Atividade {
  final int id;
  final String nome;
  final String descricao;
  final String dificuldade;
  final String situacao;
  final String recorrencia;
  final int tpEstimado; // em minutos
  final int xp;
  final int nivelUsuario;
  final String dtAtividade;

  Atividade({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.dificuldade,
    required this.situacao,
    required this.recorrencia,
    required this.tpEstimado,
    required this.xp,
    required this.nivelUsuario,
    required this.dtAtividade,
  });

  factory Atividade.fromJson(Map<String, dynamic> json) {
    return Atividade(
      id: json['idatividade'] ?? 0,
      nome: json['nmatividade'] ?? '',
      descricao: json['dsatividade'] ?? '',
      dificuldade: json['dificuldade'] ?? 'facil',
      situacao: json['situacao'] ?? 'ativa',
      recorrencia: json['recorrencia'] ?? 'unica',
      tpEstimado: json['tpestimado'] ?? 0,
      xp: json['expatividade'] ?? 0,
      nivelUsuario: json['nivelusuario'] ?? 1,
      dtAtividade: json['dtatividade'] ?? '',
    );
  }
}

class DesafioPendente {
  final int id;
  final String nome;
  final String descricao;
  final String tipo;
  final int xp;
  final int progresso;
  final int meta;

  DesafioPendente({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.tipo,
    required this.xp,
    required this.progresso,
    required this.meta,
  });

  factory DesafioPendente.fromJson(Map<String, dynamic> json) {
    return DesafioPendente(
      id: json['iddesafio'] ?? 0,
      nome: json['nmdesafio'] ?? 'Desafio sem nome',
      descricao: json['dsdesafio'] ?? '',
      tipo: json['tipo'] ?? 'geral',
      xp: json['expdesafio'] ?? 0,
      progresso: json['progresso'] ?? 0,
      meta: json['meta'] ?? 1,
    );
  }
}

class Conquista {
  final int id;
  final String nome;
  final String descricao;
  final String imagem;
  final int xp;
  final String dataDesbloqueio;
  final bool completada;

  Conquista({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.imagem,
    required this.xp,
    required this.dataDesbloqueio,
    required this.completada,
  });

  factory Conquista.fromJson(Map<String, dynamic> json) {
    final conquistaData = json['conquista'] ?? json;

    return Conquista(
      id: conquistaData['idconquista'] ?? 0,
      nome: conquistaData['nmconquista'] ?? 'Conquista sem nome',
      descricao: conquistaData['dsconquista'] ?? '',
      imagem: conquistaData['nmimagem'] ?? 'relogio.png',
      xp: conquistaData['expconquista'] ?? 0,
      dataDesbloqueio: json['dtconcessao'] ?? '',
      completada: conquistaData['completada'] ?? (json['dtconcessao'] != null),
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