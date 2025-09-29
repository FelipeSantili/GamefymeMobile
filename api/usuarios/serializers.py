from rest_framework import serializers
from .models import Usuario
from core.services import get_streak_data 

class UsuarioSerializer(serializers.ModelSerializer):
    exp_total_nivel = serializers.SerializerMethodField()
    streak_data = serializers.SerializerMethodField()

    class Meta:
        model = Usuario
        fields = [
            'idusuario', 'nmusuario', 'emailusuario',
            'nivelusuario', 'expusuario', 'imagem_perfil',
            'exp_total_nivel', 'streak_data'
        ]

    def get_exp_total_nivel(self, obj):
        # Exemplo fixo (pode ser alterado para cálculo real futuramente)
        return 1000

    def get_streak_data(self, obj):
        return get_streak_data(obj)
