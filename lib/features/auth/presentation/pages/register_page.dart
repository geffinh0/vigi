import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vigi_palette.dart';
import '../../../../core/theme/vigi_tokens.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/vigi_dialogs.dart';
import '../../../../core/widgets/vigi_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'login_page.dart';

/// Tela de cadastro de conta.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignUp() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthSignUpRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) showVigiMessage(context, state.message);
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  VigiSpace.screen,
                  0,
                  VigiSpace.screen,
                  VigiSpace.screen,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              'Criar sua conta no Vigi',
                              style: AppTypography.h2.copyWith(
                                color: palette.text,
                              ),
                            ),
                          ),
                          const SizedBox(height: VigiSpace.x2),
                          Text(
                            'Leva um minuto. Depois você escolhe quem deve '
                            'ser avisado.',
                            style: AppTypography.bodyLarge.copyWith(
                              color: palette.text,
                            ),
                          ),
                          const SizedBox(height: VigiSpace.x6),
                          VigiTextField(
                            label: 'Nome',
                            hint: 'Como você gosta de ser chamado',
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? 'Digite o seu nome.'
                                : null,
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
                            label: 'Telefone com DDD (opcional)',
                            hint: '(11) 98765-4321',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                          ),
                          const SizedBox(height: VigiSpace.x4),
                          VigiTextField(
                            label: 'Senha',
                            helper: 'Pelo menos 6 caracteres',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            onFieldSubmitted: (_) => _onSignUp(),
                            suffixIcon: passwordToggle(
                              obscured: _obscurePassword,
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (value) => (value ?? '').length < 6
                                ? 'A senha precisa de pelo menos 6 caracteres.'
                                : null,
                          ),
                          const SizedBox(height: VigiSpace.x6),
                          AppPrimaryButton(
                            text: 'Criar conta',
                            isLoading: isLoading,
                            onPressed: _onSignUp,
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
