from rest_framework import generics, permissions
from .models import Conquista, UsuarioConquista
from .serializers import ConquistaSerializer, UsuarioConquistaSerializer

class ConquistaListView(generics.ListAPIView):
    """
    Endpoint para listar todas as conquistas disponíveis no sistema.
    """
    queryset = Conquista.objects.all()
    serializer_class = ConquistaSerializer
    permission_classes = [permissions.IsAuthenticated]

class UsuarioConquistaListView(generics.ListAPIView):
    """
    Endpoint para listar o histórico de conquistas que o usuário logado já obteve.
    """
    serializer_class = UsuarioConquistaSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UsuarioConquista.objects.filter(idusuario=self.request.user).order_by('-dtconcessao')
