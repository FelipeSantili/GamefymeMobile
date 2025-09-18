from django.urls import path
from .views import CadastroAPIView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView


app_name = "usuarios"

urlpatterns = [
    path("cadastro/", CadastroAPIView.as_view(), name="cadastro"),
    path("login/", TokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("refresh/", TokenRefreshView.as_view(), name="token_refresh"),
]