from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AtividadeViewSet

router = DefaultRouter()
router.register(r'', AtividadeViewSet, basename='atividade')

urlpatterns = [
    path('', include(router.urls)),
]