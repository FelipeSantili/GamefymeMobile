from rest_framework import generics, permissions
from .models import Desafio, UsuarioDesafio
from .serializers import DesafioSerializer, UsuarioDesafioSerializer

class DesafioListView(generics.ListAPIView):
    """
    Endpoint para listar todos os desafios ativos que um usuário pode ver.
    """
    serializer_class = DesafioSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Filtra para retornar apenas os desafios que estão ativos no momento
        return [desafio for desafio in Desafio.objects.all() if desafio.is_ativo()]


class UsuarioDesafioListView(generics.ListAPIView):
    """
    Endpoint para listar o histórico de desafios que o usuário logado já completou.
    """
    serializer_class = UsuarioDesafioSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UsuarioDesafio.objects.filter(idusuario=self.request.user).order_by('-dtpremiacao')