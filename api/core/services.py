from datetime import date, timedelta
from atividades.models import AtividadeConcluidas
import locale

def get_streak_data(usuario):
    """
    Gera os dados de streak dos últimos 7 dias para o usuário.
    """
    try:
        locale.setlocale(locale.LC_TIME, 'pt_BR.UTF-8')
    except locale.Error:
        locale.setlocale(locale.LC_TIME, '')

    today = date.today()
    streak_data = []

    # Busca datas de conclusão de atividades nos últimos 7 dias
    datas_concluidas = AtividadeConcluidas.objects.filter(
        idusuario=usuario,
        dtconclusao__date__gte=today - timedelta(days=6)
    ).values_list('dtconclusao__date', flat=True).distinct()

    set_datas_concluidas = set(datas_concluidas)

    # Itera sobre os últimos 7 dias
    for i in range(6, -1, -1):
        dia = today - timedelta(days=i)
        dia_semana = dia.strftime('%a').upper()[:3]

        imagem = 'fogo-inativo.png'
        if dia in set_datas_concluidas:
            imagem = 'fogo-ativo.png'

        streak_data.append({
            'dia_semana': dia_semana,
            'imagem': imagem
        })

    return streak_data