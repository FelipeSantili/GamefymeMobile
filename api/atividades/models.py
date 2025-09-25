from django.db import models
from usuarios.models import Usuario

class Atividade(models.Model):
    class Peso(models.TextChoices):
        MUITO_FACIL = 'muito_facil', 'Muito fácil'
        FACIL = 'facil', 'Fácil'
        MEDIO = 'medio', 'Médio'
        DIFICIL = 'dificil', 'Difícil'
        MUITO_DIFICIL = 'muito_dificil', 'Muito difícil'

    class Situacao(models.TextChoices):
        ATIVA = 'ativa', 'Ativa'
        REALIZADA = 'realizada', 'Realizada'
        CANCELADA = 'cancelada', 'Cancelada'

    class Recorrencia(models.TextChoices):
        UNICA = 'unica', 'Única'
        RECORRENTE = 'recorrente', 'Recorrente'

    idatividade = models.AutoField(primary_key=True)
    idusuario = models.ForeignKey(Usuario, on_delete=models.CASCADE, db_column='idusuario')
    nmatividade = models.CharField(max_length=100)
    dsatividade = models.TextField(blank=True)
    peso = models.CharField(max_length=20, choices=Peso.choices)
    situacao = models.CharField(max_length=20, choices=Situacao.choices, default=Situacao.ATIVA)
    recorrencia = models.CharField(max_length=20, choices=Recorrencia.choices)
    dtatividade = models.DateTimeField()
    dtatividaderealizada = models.DateTimeField(null=True, blank=True)
    tpestimado = models.IntegerField()
    expatividade = models.SmallIntegerField(default=0)
    
class AtividadeConcluidas(models.Model):
    idatividade_concluida = models.AutoField(primary_key=True)
    idusuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        db_column='idusuario'
    )
    idatividade = models.ForeignKey(
        Atividade,
        on_delete=models.CASCADE,
        db_column='idatividade'
    )
    dtconclusao = models.DateTimeField()

    class Meta:
        db_table = 'atividades_concluidas'

    def __str__(self):
        return f'Usuário {self.idusuario_id} - Atividade {self.idatividade_id}'

    class Meta:
        db_table = 'atividades'

    def __str__(self):
        return self.nmatividade