from datetime import date, timedelta
from atividades.models import AtividadeConcluidas
import locale

def get_streak_data(usuario):
    """
    Gera os dados de streak da semana atual, de Domingo a Sábado.
    """
    try:
        locale.setlocale(locale.LC_TIME, 'pt_BR.UTF-8')
    except locale.Error:
        locale.setlocale(locale.LC_TIME, '')

    today = date.today()
    start_of_week = today - timedelta(days=(today.weekday() + 1) % 7)
    
    streak_data = []

    datas_concluidas = AtividadeConcluidas.objects.filter(
        idusuario=usuario,
        dtconclusao__date__gte=start_of_week,
        dtconclusao__date__lte=start_of_week + timedelta(days=6)
    ).values_list('dtconclusao__date', flat=True).distinct()

    set_datas_concluidas = set(datas_concluidas)

    for i in range(7):
        dia = start_of_week + timedelta(days=i)
        
        if dia.weekday() == 5: # 5 é Sábado
            dia_semana = 'SÁB'
        else:
            dia_semana = dia.strftime('%a').upper()[:3]
            
        imagem = 'fogo-inativo.png'
        if dia in set_datas_concluidas:
            imagem = 'fogo-ativo.png'

        streak_data.append({
            'dia_semana': dia_semana,
            'imagem': imagem
        })
        
    return streak_data