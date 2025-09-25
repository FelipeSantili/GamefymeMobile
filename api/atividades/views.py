from rest_framework import viewsets, permissions
from .models import Atividade
from .serializers import AtividadeSerializer

# Função para calcular a experiência baseada no peso e tempo estimado
def calcular_experiencia(peso: str, tempo_estimado: int) -> int:
    """
    Calcula a experiência ganha por uma atividade baseado no seu peso e tempo.
    RN 04 - A experiência não poderá ultrapassar de 500 e tem um mínimo de 50.
    """
    exp_base = 50
    multiplicadores_peso = {
        'muito_facil': 1.0,
        'facil': 2.0,
        'medio': 3.0,
        'dificil': 4.0,
        'muito_dificil': 5.0
    }
    multiplicador_peso = multiplicadores_peso.get(peso, 1.0)

    if tempo_estimado <= 30:
        multiplicador_tempo = 1.0
    elif tempo_estimado <= 60:
        multiplicador_tempo = 1.5
    elif tempo_estimado <= 120:
        multiplicador_tempo = 2.0
    else:
        multiplicador_tempo = 2.5

    experiencia = round(exp_base * multiplicador_peso * multiplicador_tempo)
    
    # Garante que o valor final esteja entre 50 e 500
    return max(50, min(experiencia, 500))

# ViewSet para a API de Atividades
class AtividadeViewSet(viewsets.ModelViewSet):
    serializer_class = AtividadeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Atividade.objects.filter(idusuario=self.request.user)

    def perform_create(self, serializer):
        """
        Calcula a experiência antes de salvar a nova atividade.
        """
        peso = serializer.validated_data.get('peso')
        tempo_estimado = serializer.validated_data.get('tpestimado')
        
        exp_calculada = calcular_experiencia(peso, tempo_estimado)
        
        serializer.save(idusuario=self.request.user, expatividade=exp_calculada)
