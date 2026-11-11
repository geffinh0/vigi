import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vigi_palette.dart';
import '../../../../core/theme/vigi_tokens.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/vigi_dialogs.dart';
import '../../../../core/widgets/vigi_logo.dart';
import '../../../../core/widgets/vigi_mascot.dart';
import '../../../../core/widgets/vigi_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// E-mail com formato plausível.
String? validateEmail(String? value) {
  final email = (value ?? '').trim();
  if (email.isEmpty) return 'Digite o seu e-mail.';
  if (!email.contains('@') || !email.contains('.')) {
    return 'Confira o e-mail. Exemplo: maria@email.com';
  }
  return null;
}

/// Tela de login (usada pelo app da pessoa acompanhada e pelo Vigi Família).
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.familyEdition = false,
    this.subtitle = 'Alguém de olho por você, sem ser intrusivo.',
  });

  /// Mostra a assinatura "Família" (painel web do familiar).
  final bool familyEdition;
  final String subtitle;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignIn() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthSignInRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) showVigiMessage(context, state.message);
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(VigiSpace.screen),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: VigiSymbol(size: 96),
                          ),
                          const SizedBox(height: VigiSpace.x2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const VigiLogo(height: 56),
                              if (widget.familyEdition) ...[
                                const SizedBox(width: VigiSpace.x3),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    'Família',
                                    style: AppTypography.h2.copyWith(
                                      color: palette.text,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: VigiSpace.x3),
                          Text(
                            widget.subtitle,
                            style: AppTypography.bodyLarge.copyWith(
                              color: palette.text,
                            ),
                          ),
                          const SizedBox(height: VigiSpace.block),
                          Semantics(
                            header: true,
                            child: Text(
                              'Entrar na sua conta',
                              style: AppTypography.h2.copyWith(
                                color: palette.text,
                              ),
                            ),
                          ),
                          const SizedBox(height: VigiSpace.x4),
                          VigiTextField(
                            label: 'E-mail',
                            hint: 'maria@email.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            validator: validateEmail,
                          ),
                          const SizedBox(height: VigiSpace.x4),
                          VigiTextField(
                            label: 'Senha',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _onSignIn(),
                            suffixIcon: _PasswordToggle(
                              obscured: _obscurePassword,
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (value) => (value ?? '').isEmpty
                                ? 'Digite a sua senha.'
                                : null,
                          ),
                          const SizedBox(height: VigiSpace.x6),
                          AppPrimaryButton(
                            text: 'Entrar',
                            isLoading: isLoading,
                            onPressed: _onSignIn,
                          ),
                          const SizedBox(height: VigiSizes.touchGap),
                          AppPrimaryButton(
                            text: 'Criar conta',
                            variant: AppButtonVariant.outline,
                            onPressed: isLoading
                                ? null
                                : () => context.push('/register'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Mostrar ou ocultar a senha: ícone universal, com rótulo para o leitor
/// de tela.
class _PasswordToggle extends StatelessWidget {
  const _PasswordToggle({required this.obscured, required this.onPressed});

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscured ? 'Mostrar a senha' : 'Ocultar a senha',
      icon: Icon(
        obscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
      ),
      onPressed: onPressed,
    );
  }
}

/// Botão de mostrar a senha, compartilhado com a tela de cadastro.
Widget passwordToggle({
  required bool obscured,
  required VoidCallback onPressed,
}) => _PasswordToggle(obscured: obscured, onPressed: onPressed);
