from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from datetime import datetime, timedelta

from .models import AtividadeConcluidas
from desafios.models import Desafio, UsuarioDesafio
from conquistas.models import Conquista, UsuarioConquista
from usuarios.models import Usuario
from notificacoes.services import criar_notificacao

def _verificar_e_premiar_desafios(usuario):
    """
    Verifica e premia o usuário por desafios concluídos.
    """
    agora = timezone.now()
    hoje = timezone.localdate()
    
    for desafio in Desafio.objects.all():
        if not desafio.is_ativo():
            continue

        # Verifica se o usuário já foi premiado neste ciclo
        premiacao_existente = UsuarioDesafio.objects.filter(idusuario=usuario, iddesafio=desafio)
        
        if desafio.tipo == 'diario':
            premiacao_existente = premiacao_existente.filter(dtpremiacao__date=hoje)
        elif desafio.tipo == 'semanal':
            inicio_semana = hoje - timedelta(days=hoje.weekday())
            fim_semana = inicio_semana + timedelta(days=6)
            premiacao_existente = premiacao_existente.filter(dtpremiacao__date__range=[inicio_semana, fim_semana])
        elif desafio.tipo == 'mensal':
            premiacao_existente = premiacao_existente.filter(dtpremiacao__year=hoje.year, dtpremiacao__month=hoje.month)
        
        if premiacao_existente.exists():
            continue

        # Lógica de conclusão do desafio (simplificada, adicione suas lógicas aqui)
        # Exemplo: contar atividades concluídas hoje
        if desafio.tipo_logica == 'atividades_concluidas' and desafio.tipo == 'diario':
            inicio_dia = timezone.make_aware(datetime.combine(hoje, datetime.min.time()))
            fim_dia = timezone.make_aware(datetime.combine(hoje, datetime.max.time()))
            count = AtividadeConcluidas.objects.filter(idusuario=usuario, dtconclusao__range=(inicio_dia, fim_dia)).count()
            
            if count >= (desafio.parametro or 1):
                UsuarioDesafio.objects.create(
                    idusuario=usuario, iddesafio=desafio, flsituacao=True, dtpremiacao=agora
                )
                usuario.expusuario += desafio.expdesafio
    usuario.save()


def _verificar_e_premiar_conquistas(usuario):
    """
    Verifica e premia o usuário por conquistas alcançadas.
    """
    # Exemplo de lógica: Primeira atividade concluída
    # Você pode expandir isso com todas as lógicas do seu `conquistas_service.py`
    try:
        conquista_primeira_atividade = Conquista.objects.get(idconquista=1) # Supondo que o ID 1 é a primeira atividade
        ja_possui = UsuarioConquista.objects.filter(idusuario=usuario, idconquista=conquista_primeira_atividade).exists()
        
        if not ja_possui:
            if AtividadeConcluidas.objects.filter(idusuario=usuario).count() >= 1:
                UsuarioConquista.objects.create(idusuario=usuario, idconquista=conquista_primeira_atividade)
                usuario.expusuario += conquista_primeira_atividade.expconquista
                usuario.save()

    except Conquista.DoesNotExist:
        pass # Conquista não encontrada, ignora a verificação

@receiver(post_save, sender=AtividadeConcluidas)
def verificar_recompensas_on_atividade_concluida(sender, instance, created, **kwargs):
    """
    Este é o "observador". Ele é chamado toda vez que uma nova AtividadeConcluidas é 
    criada.
    """
    if created:
        usuario = instance.idusuario
        atividade = instance.idatividade
        exp_ganha = atividade.expatividade
        
        # Lógica de Notificação que estava na sua view antiga
        nivel_anterior = usuario.nivelusuario
        
        # Notificação de atividade concluída
        criar_notificacao(
            usuario, 
            f'Parabéns! Você completou a atividade "{atividade.nmatividade}" e ganhou {exp_ganha} XP!', 
            'sucesso'
        )

        # Verifica se o usuário subiu de nível para enviar notificação
        # (A lógica de XP e nível já deve estar no seu signal ou em outro lugar que atualize o usuário)
        # Supondo que o usuário já foi atualizado antes deste ponto:
        if usuario.nivelusuario > nivel_anterior:
            criar_notificacao(
                usuario, 
                f'🎉 Incrível! Você alcançou o nível {usuario.nivelusuario}!', 
                'sucesso'
            )

        # Chama as outras verificações
        _verificar_e_premiar_desafios(usuario)
        _verificar_e_premiar_conquistas(usuario)