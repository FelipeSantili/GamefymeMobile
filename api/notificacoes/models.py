from django.db import models
from usuarios.models import Usuario

class Notificacao(models.Model):
    class Tipo(models.TextChoices):
        INFO = 'info', 'Informação'
        SUCESSO = 'sucesso', 'Sucesso'
        AVISO = 'aviso', 'Aviso'
        ERRO = 'erro', 'Erro'

    idnotificacao = models.AutoField(primary_key=True)
    idusuario = models.ForeignKey(Usuario, on_delete=models.CASCADE, db_column='idusuario')
    dsmensagem = models.TextField()
    fltipo = models.CharField(max_length=50, choices=Tipo.choices, default=Tipo.INFO)
    dtcriacao = models.DateTimeField(auto_now_add=True)
    flstatus = models.BooleanField(default=False)  # False = não lida

    class Meta:
        db_table = 'notificacoes'
        ordering = ['-dtcriacao']

    def __str__(self):
        return f"Notificação para {self.idusuario.nmusuario}"