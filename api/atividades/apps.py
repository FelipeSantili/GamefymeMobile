from django.apps import AppConfig


class AtividadesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'atividades'

    def ready(self):
        # Esta linha importa e ativa os sinais quando o app estiver pronto.
        import atividades.signals
