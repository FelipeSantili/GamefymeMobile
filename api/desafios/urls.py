from django.urls import path
from .views import DesafioListView, UsuarioDesafioListView

urlpatterns = [
    # Rota para o app listar todos os desafios disponíveis
    # Ex: GET /api/desafios/
    path('', DesafioListView.as_view(), name='desafio-list'),
    
    # Rota para o app listar os desafios que o usuário já completou (histórico)
    # Ex: GET /api/desafios/meus-desafios/
    path('meus-desafios/', UsuarioDesafioListView.as_view(), name='usuario-desafio-list'),
]