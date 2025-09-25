from rest_framework import serializers
from .models import Conquista, UsuarioConquista

class ConquistaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Conquista
        fields = ['idconquista', 'nmconquista', 'dsconquista', 'nmimagem', 'expconquista']

class UsuarioConquistaSerializer(serializers.ModelSerializer):
    # Inclui os detalhes da conquista dentro da resposta
    conquista = ConquistaSerializer(source='idconquista', read_only=True)

    class Meta:
        model = UsuarioConquista
        fields = ['idusuarioconquista', 'dtconcessao', 'conquista']
