from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
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
    
    return max(50, min(experiencia, 500))


class AtividadeViewSet(viewsets.ModelViewSet):
    serializer_class = AtividadeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Atividade.objects.filter(idusuario=user)

    def perform_create(self, serializer):
        # define o usuário logado como o dono da atividade
        serializer.save(idusuario=self.request.user)

    # A rota será /api/atividades/{pk}/realizar/
    @action(detail=True, methods=['post'])
    def realizar(self, request, pk=None):
        """
        Marca uma atividade como realizada.
        """
        try:
            atividade = self.get_object()
            # Adicione sua lógica para concluir a atividade aqui
            # Ex: atividade.situacao = 'Concluída'
            #     atividade.save()
            #     request.user.expusuario += atividade.expatividade
            #     request.user.save()
            
            # Por enquanto, vamos apenas retornar sucesso
            return Response({'status': 'atividade realizada'}, status=status.HTTP_200_OK)
        except Atividade.DoesNotExist:
            return Response({'erro': 'Atividade não encontrada'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({'erro': str(e)}, status=status.HTTP_400_BAD_REQUEST)
