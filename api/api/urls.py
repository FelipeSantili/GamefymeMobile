from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/usuarios/', include('usuarios.urls')),
    path('api/atividades/', include('atividades.urls')),
    path('api/desafios/', include('desafios.urls')),
    path('api/conquistas/', include('conquistas.urls')),
    path('api/notificacoes/', include('notificacoes.urls')),
]