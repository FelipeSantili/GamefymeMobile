from rest_framework import serializers
from .models import Usuario

class UsuarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        # Adicione aqui todos os campos que seu front-end precisa
        fields = ['idusuario', 'nmusuario', 'emailusuario', 'nivelusuario', 'expusuario', 'imagem_perfil']
        # Se você tiver campos como 'streak_atual', adicione-os aqui também.