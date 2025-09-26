from .models import Notificacao

def criar_notificacao(usuario, mensagem, tipo='info'):
    """Cria uma nova notificação para um usuário."""
    return Notificacao.objects.create(
        idusuario=usuario,
        dsmensagem=mensagem,
        fltipo=tipo
    )