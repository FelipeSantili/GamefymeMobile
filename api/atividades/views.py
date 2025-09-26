from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db import transaction

from .models import Atividade, AtividadeConcluidas
from .serializers import AtividadeSerializer

class AtividadeViewSet(viewsets.ModelViewSet):
    serializer_class = AtividadeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        # Retorna apenas as atividades que não estão canceladas
        return Atividade.objects.filter(idusuario=user).exclude(situacao='cancelada')

    def perform_create(self, serializer):
        # Lógica adaptada da view criar_atividade do sistema antigo
        validated_data = serializer.validated_data
        dificuldade = validated_data.get('dificuldade')
        tempo_estimado = validated_data.get('tpestimado')

        exp = calcular_experiencia(dificuldade, tempo_estimado)

        serializer.save(
            idusuario=self.request.user,
            expatividade=exp,
            situacao='ativa'
        )

    @action(detail=True, methods=['post'])
    def realizar(self, request, pk=None):
        """
        Endpoint para marcar uma atividade como realizada, replicando a lógica do sistema antigo.
        """
        atividade = self.get_object()
        usuario = request.user

        if atividade.situacao == 'cancelada' or \
           (atividade.situacao == 'realizada' and atividade.recorrencia == 'unica'):
            return Response(
                {'erro': 'Esta atividade não pode mais ser realizada.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            with transaction.atomic():
                # Lógica de cálculo de EXP e Nível
                exp_ganha = atividade.expatividade
                nova_exp = usuario.expusuario + exp_ganha
                novo_nivel = usuario.nivelusuario
                while nova_exp >= 1000:
                    novo_nivel += 1
                    nova_exp -= 1000
                
                # Atualiza o usuário
                usuario.expusuario = nova_exp
                usuario.nivelusuario = novo_nivel
                usuario.ultima_atividade = timezone.now().date()
                usuario.save()

                # Atualiza o status da atividade
                if atividade.recorrencia == 'unica':
                    atividade.situacao = 'realizada'
                
                atividade.dtatividaderealizada = timezone.now()
                atividade.save()

                # Cria o registro de conclusão para disparar o signal
                AtividadeConcluidas.objects.create(
                    idusuario=usuario,
                    idatividade=atividade,
                    dtconclusao=timezone.now()
                )

                return Response({
                    'status': 'atividade realizada',
                    'exp_ganha': exp_ganha
                }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({'erro': str(e)}, status=status.HTTP_400_BAD_REQUEST)

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
        
# A função de calcular experiência foi mantida, pois é idêntica em ambos os sistemas.
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