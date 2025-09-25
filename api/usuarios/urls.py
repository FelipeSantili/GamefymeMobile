from django.urls import path
from .views import CadastroAPIView, LoginAPIView, UsuarioDetailView
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

urlpatterns = [
    path('cadastro/', CadastroAPIView.as_view(), name='cadastro'),
    path('login/', LoginAPIView.as_view(), name='login'),
    
    # ADICIONE ESTA ROTA
    path('me/', UsuarioDetailView.as_view(), name='usuario-detail'),
]