CREATE TYPE tipo_usuario_enum AS ENUM ('comum', 'administrador');
CREATE TYPE peso_enum AS ENUM ('muito_facil', 'facil', 'medio', 'dificil', 'muito_dificil');
CREATE TYPE situacao_atividade_enum AS ENUM ('ativa',  'realizada',  'cancelada');
CREATE TYPE recorrencia_enum AS ENUM ('unica', 'recorrente');
CREATE TYPE tipo_desafio_enum AS ENUM ('diario', 'semanal', 'mensal');
CREATE TYPE tipo_notificacao_enum AS ENUM ('info', 'sucesso', 'aviso', 'erro');

CREATE TABLE usuarios (
    idusuario SERIAL PRIMARY KEY,
    nmusuario VARCHAR(100) NOT NULL,
    emailusuario VARCHAR(100) NOT NULL UNIQUE,
    dtnascimento DATE NOT NULL,
    flsituacao BOOLEAN DEFAULT true,
    nivelusuario INTEGER DEFAULT 1,
    expusuario SMALLINT DEFAULT 0 CHECK (expusuario >= 0 AND expusuario <= 1000),
    tipousuario tipo_usuario_enum NOT NULL,
    imagem_perfil VARCHAR(100) DEFAULT 'avatar1.png',
    ultima_atividade TIMESTAMPTZ,
    date_joined TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN NOT NULL,
    is_staff BOOLEAN NOT NULL,
    is_superuser BOOLEAN NOT NULL,
    last_login TIMESTAMPTZ,
    password VARCHAR(128) NOT NULL
);


CREATE TABLE atividades (
    idatividade SERIAL PRIMARY KEY,
    idusuario INT NOT NULL REFERENCES usuarios(idusuario),
    nmatividade VARCHAR(100) NOT NULL,
    peso peso_enum NOT NULL,
    situacao situacao_atividade_enum NOT NULL,
    recorrencia recorrencia_enum NOT NULL,
    dtatividade TIMESTAMP WITH TIME ZONE NOT NULL,
    dtatividaderealizada TIMESTAMP WITH TIME ZONE ,
    tpestimado INT NOT NULL,
    dsatividade TEXT,
    expatividade SMALLINT DEFAULT 0,
    CONSTRAINT unq_usuario_atividade UNIQUE (idusuario, nmatividade)
);

CREATE TABLE desafios (
    iddesafio SERIAL PRIMARY KEY,
    nmdesafio VARCHAR(100) NOT NULL,
    dsdesafio TEXT,
    dtinicio TIMESTAMP WITH TIME ZONE ,
    dtfim TIMESTAMP WITH TIME ZONE,
    tipo tipo_desafio_enum NOT NULL,
    expdesafio SMALLINT DEFAULT 0,
    tipo_logica VARCHAR(50),
    parametro INTEGER
);


CREATE TABLE usuario_desafios (
    idusuariodesafio SERIAL PRIMARY KEY,
    idusuario INT NOT NULL REFERENCES usuarios(idusuario),
    iddesafio INT NOT NULL REFERENCES desafios(iddesafio),
    flsituacao BOOLEAN DEFAULT TRUE,
    dtpremiacao TIMESTAMP WITH TIME ZONE 
);

CREATE TABLE notificacoes (
    idnotificacao SERIAL PRIMARY KEY,
    idusuario INT NOT NULL REFERENCES usuarios(idusuario),
    dsmensagem TEXT NOT NULL,
    fltipo VARCHAR(50),
    dtcriacao TIMESTAMP WITH TIME ZONE,
    flstatus BOOLEAN DEFAULT FALSE
);

CREATE TABLE conquistas (
    idconquista SERIAL PRIMARY KEY,
    nmconquista VARCHAR(100) NOT NULL,
    dsconquista TEXT,
    nmimagem TEXT,
    expconquista SMALLINT DEFAULT 0
);

CREATE TABLE usuario_conquistas (
    idusuarioconquista SERIAL PRIMARY KEY,
    idusuario INT NOT NULL REFERENCES usuarios(idusuario),
    idconquista INT NOT NULL REFERENCES conquistas(idconquista),
    dtconcessao TIMESTAMP WITH TIME ZONE 
);

CREATE TABLE atividades_concluidas (
    idatividade_concluida SERIAL PRIMARY KEY,
    idatividade INT NOT NULL REFERENCES atividades(idatividade),
    idusuario INT NOT NULL REFERENCES usuarios(idusuario),
    dtconclusao TIMESTAMP WITH TIME ZONE NOT NULL
);

INSERT INTO desafios (nmdesafio, dsdesafio, dtinicio, dtfim, tipo, expdesafio, tipo_logica, parametro) VALUES
('Recorrência Semanal', 'Conclua atividades recorrentes por 7 dias.', '2025-05-30', '2025-12-31', 'semanal', 100, 'recorrentes_concluidas', 7),
('Semanal Produtivo', 'Conclua 10 atividades essa semana.', '2025-05-30', '2025-12-31', 'semanal', 100, 'atividades_concluidas', 10),
('Concluir 2 desafios', 'Concluir 2 desafios na semana', '2025-05-01', '2025-07-01', 'semanal', 150, 'desafios_concluidos', 2),
('Organização Diária', 'Cadastre suas atividades do dia.', '1900-01-01', '3000-12-31', 'diario', 50, 'atividades_criadas', 1),
('Desafio Difícil', 'Realize pelo menos 1 atividade difícil.', '1900-01-01', '3000-12-31', 'diario', 50, 'min_dificeis', 1),
('Dupla Produtiva', 'Realize 2 atividades médias ou fáceis.', '1900-01-01', '3000-12-31', 'diario', 50, 'min_atividades_por_peso', 2),
('Limpeza Fácil', 'Conclua todas as atividades muito fáceis do dia.', '1900-01-01', '3000-12-31', 'diario', 50, 'todas_muito_faceis', NULL),
('3 Atividades', 'Completar 3 atividades distintas difíceis', '2025-05-01', '2025-07-01', 'diario', 200, 'min_dificeis', 3),
('Meta Mensal', 'Conclua 30 atividades no mês.', '2025-05-30', '2025-12-31', 'mensal', 500, 'atividades_concluidas', 30),
('Streak Mensal', 'Mantenha streak por 30 dias.', '2025-05-30', '2025-12-31', 'mensal', 500, 'streak_diario', 30),
('Meta de Conclusão', 'Alcance 80% das metas do mês.', '2025-05-30', '2025-12-31', 'mensal', 300, 'percentual_concluido', 80);


INSERT INTO conquistas (nmconquista, dsconquista, nmimagem, expconquista) VALUES
('ATIVIDADE CUMPRIDA', 'Complete sua primeira atividade.', 'atividade_realizada.png', 50),
('PRODUTIVIDADE EM ALTA', 'Complete 10 atividades.', '10atividades.png', 100),
('RECORRÊNCIA - DE NOVO!', 'Complete uma atividade recorrente 5 vezes.', 'recorrencia.png', 100),
('USUÁRIO HARDCORE', 'Complete 5 atividades marcadas como muito difíceis.', 'hardcore.png', 150),
('DESAFIANTE AMADOR', 'Complete seu primeiro desafio.', 'missaocumprida.png', 50),
('CAMPEÃO SEMANAL', 'Complete todos os desafios semanais.', 'campeaosemanal.png', 100),
('MISSÃO CUMPRIDA', 'Complete um desafio mensal.', 'missaocumprida.png', 150),
('DESAFIANTE MESTRE', 'Complete 50 desafios.', 'master.png', 200),
('UM DIA APÓS O OUTRO', 'Mantenha uma sequência de 5 dias.', 'umdiaaposooutro.png', 100),
('RITUAL SEMANAL', 'Cadastre uma atividade por dia por 7 dias.', 'ritualsemana.png', 120),
('CONSISTÊNCIA INABALÁVEL', 'Mantenha uma sequência de 15 dias.', 'inabalavel.png', 200);




