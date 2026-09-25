import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/vigi_mascot.dart';
import '../bloc/panic_bloc.dart';
import '../bloc/panic_event.dart';
import '../bloc/panic_state.dart';
import '../widgets/panic_button.dart';

/// Botão de pânico (segurar 3 s) e status do alerta.
class PanicPage extends StatelessWidget {
  const PanicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.linho,
      appBar: AppBar(
        title: const Text('Botão de Emergência'),
      ),
      body: BlocConsumer<PanicBloc, PanicState>(
        listener: (context, state) {
          if (state is PanicFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.panico,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PanicActive) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: VigiMascot(
                        state: VigiState.alerta,
                        size: 140,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'ALERTA DE PÂNICO ATIVO',
                      textAlign: TextAlign.center,
                      style: AppTypography.h2.copyWith(
                        color: AppColors.panico,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _deliveryMessage(state),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.cinzaTexto,
                      ),
                    ),
                    const SizedBox(height: 32),
                    AppCard(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppColors.panico,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.alert.latitude != null
                                ? 'Lat: ${state.alert.latitude!.toStringAsFixed(4)}, Lng: ${state.alert.longitude!.toStringAsFixed(4)}'
                                : 'Localização indisponível (GPS desligado)',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    AppPrimaryButton(
                      text: 'Estou Seguro — Cancelar Alerta',
                      onPressed: () {
                        context.read<PanicBloc>().add(const PanicResolved());
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Precisa de ajuda imediata?',
                    textAlign: TextAlign.center,
                    style: AppTypography.h2.copyWith(color: AppColors.petroleo),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pressione e segure o botão por 3 segundos para alertar todos os seus contatos cadastrados.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.cinzaTexto,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Center(
                    child: PanicButton(
                      size: 220,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Toques rápidos não disparam o alarme por engano.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.cinzaTexto,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _deliveryMessage(PanicActive state) {
    final found = state.contactsFound;
    final sent = state.smsSent;
    if (found == null) {
      return 'Alerta registrado. Seus familiares vinculados podem acompanhar pelo app.';
    }
    if (found == 0) {
      return 'Nenhum contato de emergência cadastrado! Cadastre contatos para que sejam avisados.';
    }
    if (sent != null && sent > 0) {
      return 'SMS com sua localização enviado para $sent de $found contato(s) de emergência.';
    }
    return 'Não foi possível enviar o SMS automaticamente. Confirme o envio no app de mensagens.';
  }
}
