from rest_framework.permissions import AllowAny
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.db import IntegrityError, transaction
from django.contrib.auth.hashers import make_password
from .models import Usuario, TipoUsuario
from django.contrib.auth import authenticate
from rest_framework.authtoken.models import Token
from rest_framework_simplejwt.tokens import RefreshToken

# URL da API - /api/usuarios/cadastro/
class CadastroAPIView(APIView):
    permission_classes = [AllowAny] 
    def post(self, request):
        nome = request.data.get("nmusuario")
        email = request.data.get("emailusuario")
        senha = request.data.get("senha")
        confsenha = request.data.get("confsenha")

        if not all([nome, email, senha, confsenha]):
            return Response({"erro": "Preencha todos os campos."},
                            status=status.HTTP_400_BAD_REQUEST)

        if senha != confsenha:
            return Response({"erro": "Senhas não coincidem."},
                            status=status.HTTP_400_BAD_REQUEST)

        if Usuario.objects.filter(emailusuario=email).exists():
            return Response({"erro": "Já existe um usuário com esse e-mail cadastrado."},
                            status=status.HTTP_400_BAD_REQUEST)

        try:
            with transaction.atomic():
                usuario = Usuario.objects.create(
                    nmusuario=nome,
                    emailusuario=email,
                    password=make_password(senha),
                    flsituacao=True,
                    nivelusuario=1,
                    expusuario=0,
                    tipousuario=TipoUsuario.COMUM
                )

                refresh = RefreshToken.for_user(usuario)
                return Response({
                    "message": "Usuário cadastrado com sucesso!",
                    "user": {
                        "id": usuario.idusuario,
                        "nome": usuario.nmusuario,
                        "email": usuario.emailusuario,
                    },
                    "tokens": {
                        "refresh": str(refresh),
                        "access": str(refresh.access_token),
                    }
                }, status=status.HTTP_201_CREATED)

        except IntegrityError:
            return Response({"erro": "Erro de integridade ao salvar."},
                            status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({"erro": f"Erro inesperado: {str(e)}"},
                            status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
# URL da API - /api/usuarios/login/     
class LoginAPIView(APIView):
    def post(self, request):
        email = request.data.get("emailusuario")
        senha = request.data.get("senha")

        if not email or not senha:
            return Response(
                {"erro": "Email e senha são obrigatórios."},
                status=status.HTTP_400_BAD_REQUEST
            )

        usuario = authenticate(request, emailusuario=email, password=senha)

        if usuario is None:
            return Response(
                {"erro": "Credenciais inválidas."},
                status=status.HTTP_400_BAD_REQUEST
            )

        token, _ = Token.objects.get_or_create(user=usuario)

        return Response(
            {
                "id": usuario.idusuario,
                "nmusuario": usuario.nmusuario,
                "emailusuario": usuario.emailusuario,
                "token": token.key
            },
            status=status.HTTP_200_OK
        )