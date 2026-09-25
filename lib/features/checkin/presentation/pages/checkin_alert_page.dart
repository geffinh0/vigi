import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/vigi_mascot.dart';
import '../bloc/checkin_bloc.dart';
import '../bloc/checkin_event.dart';
import '../bloc/checkin_state.dart';

class CheckinAlertPage extends StatelessWidget {
  const CheckinAlertPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Força o usuário a tomar uma ação explícita
      child: Scaffold(
        backgroundColor: const Color(
          0xFF2C0B0E,
        ), // Vermelho escuro de alto contraste
        body: BlocListener<CheckinBloc, CheckinState>(
          listener: (context, state) {
            if (state is CheckinMonitoring || state is CheckinIdle) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            }
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Center(
                    child: VigiMascot(
                      state: VigiState.alerta,
                      size: 160,
                      animate: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ALERTA DE CHECK-IN!',
                    textAlign: TextAlign.center,
                    style: AppTypography.h1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  BlocBuilder<CheckinBloc, CheckinState>(
                    builder: (context, state) => Text(
                      _statusMessage(state),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const Spacer(),
                  AppPrimaryButton(
                    text: 'ESTOU BEM',
                    icon: Icons.check_circle,
                    onPressed: () {
                      context.read<CheckinBloc>().add(
                        const ConfirmCheckinRequested(),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  AppPrimaryButton(
                    text: 'DISPARAR PÂNICO',
                    variant: AppButtonVariant.danger,
                    icon: Icons.emergency,
                    onPressed: () => context.push('/panic'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _statusMessage(CheckinState state) {
    const base =
        'O tempo limite para confirmação de presença expirou. O alarme continuará soando até sua confirmação.';
    if (state is! CheckinAlertActive) return base;
    if (state.contactsAlerted) {
      final found = state.contactsFound ?? 0;
      final sent = state.smsSent ?? 0;
      if (found == 0) {
        return 'Nenhum contato de emergência cadastrado para ser avisado. Toque em "Estou bem" se estiver tudo certo.';
      }
      return sent > 0
          ? 'Seus contatos de emergência foram avisados por SMS com sua localização ($sent de $found). Toque em "Estou bem" se estiver tudo certo.'
          : 'Não foi possível enviar o SMS automaticamente. Toque em "Estou bem" se estiver tudo certo.';
    }
    if (state.escalatesAt != null) {
      return '$base Sem resposta, seus contatos de emergência serão avisados às '
          '${state.escalatesAt!.hour.toString().padLeft(2, '0')}:'
          '${state.escalatesAt!.minute.toString().padLeft(2, '0')}:'
          '${state.escalatesAt!.second.toString().padLeft(2, '0')}.';
    }
    return base;
  }
}
