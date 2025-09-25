from django.urls import path
from .views import ConquistaListView, UsuarioConquistaListView

urlpatterns = [
    # Rota para o app listar todas as conquistas existentes
    # Ex: GET /api/conquistas/
    path('', ConquistaListView.as_view(), name='conquista-list'),
    
    # Rota para o app listar as conquistas que o usuário já desbloqueou
    # Ex: GET /api/conquistas/usuario/
    path('usuario/', UsuarioConquistaListView.as_view(), name='usuario-conquista-list'),
]
