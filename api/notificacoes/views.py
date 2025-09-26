from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Notificacao
from .serializers import NotificacaoSerializer

class NotificacaoViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet para listar e gerenciar notificações.
    """
    serializer_class = NotificacaoSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Retorna apenas as notificações do usuário logado."""
        return Notificacao.objects.filter(idusuario=self.request.user)

    @action(detail=False, methods=['post'], url_path='marcar-todas-como-lidas')
    def marcar_todas_como_lidas(self, request):
        """Marca todas as notificações não lidas do usuário como lidas."""
        Notificacao.objects.filter(idusuario=request.user, flstatus=False).update(flstatus=True)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=['post'], url_path='marcar-como-lida')
    def marcar_como_lida(self, request, pk=None):
        """Marca uma notificação específica como lida."""
        notificacao = self.get_object()
        notificacao.flstatus = True
        notificacao.save()
        return Response(status=status.HTTP_204_NO_CONTENT)