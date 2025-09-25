from rest_framework import serializers
from .models import Atividade

# Serializer para o modelo Atividade
class AtividadeSerializer(serializers.ModelSerializer):
    idusuario = serializers.ReadOnlyField(source='idusuario.idusuario')
    expatividade = serializers.ReadOnlyField()

    class Meta:
        model = Atividade
        fields = '__all__'
