import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'selecao_caminhao.dart';
import 'gerencial.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ControleTransportesApp());
}

class ControleTransportesApp extends StatelessWidget {
  const ControleTransportesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Controle de Transportes',

      // ==========================================================
      // LOCALIZAÇÃO
      // ==========================================================

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('pt', 'BR'),
      ],

      locale: const Locale('pt', 'BR'),

      // ==========================================================
      // TEMA
      // ==========================================================

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        scaffoldBackgroundColor:
        const Color(0xFFF4F6F8),
        inputDecorationTheme:
        const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),

      home: const LoginPage(),
    );
  }
}

// ============================================================
// LOGIN
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController =
  TextEditingController();

  final senhaController =
  TextEditingController();

  bool mostrarSenha = false;
  bool carregando = false;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  // ==========================================================
  // ENTRAR
  // ==========================================================

  Future<void> entrar() async {
    final email =
    emailController.text.trim();

    final senha =
        senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Informe o e-mail e a senha.',
          ),
        ),
      );

      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      // ========================================================
      // AUTENTICAÇÃO FIREBASE
      // ========================================================

      final credencial =
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final usuario =
          credencial.user;

      if (usuario == null) {
        throw Exception(
          'Usuário não encontrado.',
        );
      }

      // ========================================================
      // BUSCAR PERFIL NO FIRESTORE
      // ========================================================

      final documento =
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();

      if (!documento.exists) {
        await FirebaseAuth.instance
            .signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Usuário autenticado, mas seu cadastro não foi encontrado.',
            ),
          ),
        );

        return;
      }

      final dados =
      documento.data()!;

      // ========================================================
      // VERIFICAR SE ESTÁ ATIVO
      // ========================================================

      final ativo =
          dados['ativo'] == true;

      if (!ativo) {
        await FirebaseAuth.instance
            .signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Este usuário está desativado.',
            ),
          ),
        );

        return;
      }

      // ========================================================
      // PEGAR TIPO DO USUÁRIO
      // ========================================================

      final tipo =
      dados['tipo']
          ?.toString()
          .toLowerCase()
          .trim();

      final nome =
      dados['nome']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true
          ? dados['nome']
          .toString()
          .trim()
          : email;

      if (!mounted) return;

      // ========================================================
      // GERENTE
      // ========================================================

      if (tipo == 'gerente') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
            const GerencialPage(),
          ),
        );

        return;
      }

      // ========================================================
      // MOTORISTA
      // ========================================================

      if (tipo == 'motorista') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SelecaoCaminhaoPage(
                  nomeMotorista: nome,
                ),
          ),
        );

        return;
      }

      // ========================================================
      // TIPO INVÁLIDO
      // ========================================================

      await FirebaseAuth.instance
          .signOut();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'O tipo de usuário não foi configurado corretamente.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String mensagem;

      switch (e.code) {
        case 'invalid-credential':
          mensagem =
          'E-mail ou senha incorretos.';
          break;

        case 'invalid-email':
          mensagem =
          'Informe um e-mail válido.';
          break;

        case 'user-disabled':
          mensagem =
          'Este usuário foi desativado.';
          break;

        case 'too-many-requests':
          mensagem =
          'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
          break;

        default:
          mensagem =
          'Não foi possível entrar. Verifique o e-mail e a senha.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(mensagem),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao entrar: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(24),

          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 430,
            ),

            child: Card(
              elevation: 3,

              child: Padding(
                padding:
                const EdgeInsets.all(28),

                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,

                  children: [
                    const Icon(
                      Icons.local_shipping,
                      size: 72,
                      color: Colors.blue,
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    const Text(
                      'CONTROLE DE\nTRANSPORTES',
                      textAlign:
                      TextAlign.center,

                      style: TextStyle(
                        fontSize: 27,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'Acesso ao sistema',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    // ==================================================
                    // E-MAIL
                    // ==================================================

                    TextField(
                      controller:
                      emailController,

                      keyboardType:
                      TextInputType
                          .emailAddress,

                      textInputAction:
                      TextInputAction.next,

                      decoration:
                      const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon:
                        Icon(Icons.person),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // SENHA
                    // ==================================================

                    TextField(
                      controller:
                      senhaController,

                      obscureText:
                      !mostrarSenha,

                      onSubmitted: (_) {
                        if (!carregando) {
                          entrar();
                        }
                      },

                      decoration:
                      InputDecoration(
                        labelText: 'Senha',

                        prefixIcon:
                        const Icon(
                          Icons.lock,
                        ),

                        suffixIcon:
                        IconButton(
                          onPressed: () {
                            setState(() {
                              mostrarSenha =
                              !mostrarSenha;
                            });
                          },

                          icon: Icon(
                            mostrarSenha
                                ? Icons
                                .visibility_off
                                : Icons
                                .visibility,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    // ==================================================
                    // BOTÃO ENTRAR
                    // ==================================================

                    SizedBox(
                      width:
                      double.infinity,

                      height: 54,

                      child:
                      ElevatedButton.icon(
                        onPressed:
                        carregando
                            ? null
                            : entrar,

                        icon: carregando
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                          CircularProgressIndicator(
                            strokeWidth:
                            2,
                          ),
                        )
                            : const Icon(
                          Icons.login,
                        ),

                        label: Text(
                          carregando
                              ? 'ENTRANDO...'
                              : 'ENTRAR',

                          style:
                          const TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}