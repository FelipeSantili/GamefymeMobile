from rest_framework import serializers
from .models import Notificacao

class NotificacaoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notificacao
        fields = ['idnotificacao', 'dsmensagem', 'fltipo', 'dtcriacao', 'flstatus']