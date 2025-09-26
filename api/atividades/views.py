from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Atividade
from .serializers import AtividadeSerializer

# Função para calcular a experiência baseada na dificuldade e tempo estimado
def calcular_experiencia(dificuldade: str, tempo_estimado: int) -> int:
    """
    Calcula a experiência ganha por uma atividade baseado na sua dificuldade e tempo.
    RN 04 - A experiência não poderá ultrapassar de 500 e tem um mínimo de 50.
    """
    exp_base = 50
    multiplicadores_dificuldade = {
        'muito_facil': 1.0,
        'facil': 2.0,
        'medio': 3.0,
        'dificil': 4.0,
        'muito_dificil': 5.0
    }
    multiplicador_dificuldade = multiplicadores_dificuldade.get(dificuldade, 1.0)

    if tempo_estimado <= 30:
        multiplicador_tempo = 1.0
    elif tempo_estimado <= 60:
        multiplicador_tempo = 1.5
    elif tempo_estimado <= 120:
        multiplicador_tempo = 2.0
    else:
        multiplicador_tempo = 2.5

    experiencia = round(exp_base * multiplicador_dificuldade * multiplicador_tempo)
    
    return max(50, min(experiencia, 500))


class AtividadeViewSet(viewsets.ModelViewSet):
    serializer_class = AtividadeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        # Retorna apenas as atividades que não estão canceladas
        return Atividade.objects.filter(idusuario=user).exclude(situacao='cancelada')

    def perform_create(self, serializer):
        # Pega os dados validados antes de salvar
        validated_data = serializer.validated_data
        dificuldade = validated_data.get('dificuldade')
        tempo_estimado = validated_data.get('tpestimado')

        # Calcula a experiência
        exp = calcular_experiencia(dificuldade, tempo_estimado)

        # Salva a atividade com o usuário logado e a experiência calculada
        serializer.save(idusuario=self.request.user, expatividade=exp)

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

    # Nova rota para cancelar a atividade
    @action(detail=True, methods=['post'])
    def cancelar(self, request, pk=None):
        """
        Marca uma atividade como cancelada.
        """
        try:
            atividade = self.get_object()
            atividade.situacao = 'cancelada'
            atividade.save()
            return Response({'status': 'atividade cancelada'}, status=status.HTTP_200_OK)
        except Atividade.DoesNotExist:
            return Response({'erro': 'Atividade não encontrada'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({'erro': str(e)}, status=status.HTTP_400_BAD_REQUEST)