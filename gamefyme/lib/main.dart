import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// imports do seu projeto
import 'home_screen.dart';
import 'services/auth_service.dart';
import 'config/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "GamefyME",
      theme: ThemeData(
        // Tema global escuro para o app (usado na HomeScreen, etc.)
        scaffoldBackgroundColor: AppColors.fundoEscuro,
        primaryColor: AppColors.roxoHeader,
        textTheme: GoogleFonts.jersey10TextTheme(Theme.of(context).textTheme).apply(
          bodyColor: AppColors.branco,
          displayColor: AppColors.branco,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.fundoCard, // Estilo de input escuro por padrão
          labelStyle: const TextStyle(color: AppColors.cinzaSub),
          hintStyle: const TextStyle(color: AppColors.cinzaSub),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const WelcomePage(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
    );
  }
}

// ====== PÁGINA DE BOAS-VINDAS ======
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4E008A), // Cor antiga
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "GamefyME",
              style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 30),
            Image.asset("assets/images/logo.png", width: 190, errorBuilder: (c, e, s) => const SizedBox()),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A0DAD), // Cor antiga
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).push(_createSlideRoute(const LoginPage())),
                  child: const Text("Login", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A0DAD), // Cor antiga
                    padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).push(_createSlideRoute(const RegisterPage())),
                  child: const Text("Registrar", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// Helper para criar a animação de transição de tela
Route _createSlideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.ease;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

// ====== TELA DE LOGIN ======
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validEmail(String email) {
    final regex = RegExp(r"^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$");
    return regex.hasMatch(email);
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final senha = _passwordController.text;

    if (email.isEmpty || !_validEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Informe um email válido.")));
      return;
    }
    if (senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha a senha.")));
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.login(email, senha);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Erro ao autenticar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4E008A), // Cor antiga
      appBar: AppBar(
        backgroundColor: const Color(0xFF4E008A), // Cor antiga
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', height: 150, errorBuilder: (c, e, s) => const SizedBox()),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, // Card branco
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      controller: _emailController,
                      label: "Email",
                      hint: "Digite seu email",
                      keyboardType: TextInputType.emailAddress
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _passwordController,
                      label: "Senha",
                      hint: "Digite sua senha",
                      obscure: _obscurePassword,
                      suffix: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black, // Botão preto
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Login", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () { /* TODO: Implementar lógica de esqueceu a senha */ },
                      child: const Text(
                        "Esqueceu a senha?",
                        style: TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold), // Cor antiga
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper para os campos de texto com o tema claro
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.black), // Texto digitado em preto
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            fillColor: Colors.grey[200], // Fundo cinza claro
            suffixIcon: suffix,
             border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}


// ====== TELA DE REGISTRO ======
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  bool _validEmail(String email) {
    final regex = RegExp(r"^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$");
    return regex.hasMatch(email);
  }

  Future<void> _handleRegister() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final confSenha = _confirmarSenhaController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty || confSenha.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor, preencha todos os campos.")));
        return;
    }
    if (!_validEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Informe um email válido.")));
      return;
    }
    if (senha.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("A senha deve ter pelo menos 4 caracteres.")));
      return;
    }
    if (senha != confSenha) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("As senhas não coincidem.")));
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.register(
      nome: nome,
      email: email,
      senha: senha,
      confSenha: confSenha,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Registrado com sucesso')));
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Erro ao registrar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4E008A), // Cor antiga
      appBar: AppBar(
        backgroundColor: const Color(0xFF4E008A), // Cor antiga
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(label: "Nome de usuário", hint: "Nome de usuário", controller: _nomeController),
              const SizedBox(height: 15),
              _buildTextField(label: "Email", hint: "exemplo@email.com", controller: _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 15),
              _buildTextField(
                label: "Senha",
                hint: "Digite sua senha",
                controller: _senhaController,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: "Confirmar Senha",
                hint: "Repita sua senha",
                controller: _confirmarSenhaController,
                obscure: _obscureConfirmPassword,
                suffix: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Botão preto
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Registrar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper para os campos de texto com o tema claro
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.black), // Texto digitado em preto
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            fillColor: Colors.grey[200], // Fundo cinza claro
            filled: true,
            suffixIcon: suffix,
             border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

