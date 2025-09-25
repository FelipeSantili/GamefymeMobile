from rest_framework import serializers
from .models import Desafio, UsuarioDesafio

class DesafioSerializer(serializers.ModelSerializer):
    is_ativo = serializers.BooleanField(read_only=True)

    class Meta:
        model = Desafio
        fields = ['iddesafio', 'nmdesafio', 'dsdesafio', 'tipo', 'dtinicio', 'dtfim', 'expdesafio', 'is_ativo']

class UsuarioDesafioSerializer(serializers.ModelSerializer):
    desafio = DesafioSerializer(source='iddesafio', read_only=True)

    class Meta:
        model = UsuarioDesafio
        fields = ['idusuariodesafio', 'flsituacao', 'dtpremiacao', 'desafio']