import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vigi_palette.dart';
import '../../../../core/theme/vigi_tokens.dart';
import '../../../../core/utils/vigi_text.dart';
import '../../../../core/widgets/alert_active_view.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/contact_avatar.dart';
import '../../../../core/widgets/vigi_dialogs.dart';
import '../../../contacts/domain/entities/emergency_contact_entity.dart';
import '../../../contacts/presentation/bloc/contacts_bloc.dart';
import '../../../contacts/presentation/bloc/contacts_event.dart';
import '../../../contacts/presentation/bloc/contacts_state.dart';
import '../bloc/panic_bloc.dart';
import '../bloc/panic_event.dart';
import '../bloc/panic_state.dart';
import '../widgets/panic_button.dart';

/// Tela "Pedir ajuda": o botão de pânico (segurar por 3 segundos) e a lista
/// de quem vai receber o pedido, para a pessoa saber o que está prestes a
/// acontecer. Depois do envio, vira a tela de alerta ativo.
class PanicPage extends StatefulWidget {
  const PanicPage({super.key});

  @override
  State<PanicPage> createState() => _PanicPageState();
}

class _PanicPageState extends State<PanicPage> {
  bool _releasedEarly = false;

  @override
  void initState() {
    super.initState();
    final contacts = context.read<ContactsBloc>();
    if (contacts.state is! ContactsLoaded) {
      contacts.add(const LoadContactsRequested());
    }
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PanicBloc, PanicState>(
      listener: (context, state) {
        if (state is PanicFailure) {
          showVigiMessage(context, state.message);
        } else if (state is PanicResolvedState) {
          showVigiMessage(
            context,
            state.contactsNotified
                ? 'Pedido cancelado. Avisamos seus contatos de que está tudo '
                      'bem.'
                : 'Pedido cancelado.',
          );
          _leave();
        }
      },
      builder: (context, state) {
        if (state is PanicActive) {
          // Sem "voltar": a pessoa precisa dizer que está segura.
          return PopScope(
            canPop: false,
            child: Scaffold(
              body: AlertActiveView(
                contactsFound: state.contactsFound,
                smsSent: state.smsSent ?? 0,
                at: state.sentAt ?? state.alert.createdAt ?? DateTime.now(),
                deliveries: state.deliveries,
                hasLocation:
                    state.alert.latitude != null &&
                    state.alert.longitude != null,
                address: state.address,
                onCancel: () =>
                    context.read<PanicBloc>().add(const PanicResolved()),
              ),
            ),
          );
        }

        final palette = context.vigi;
        final sending = state is PanicLoading;

        return Scaffold(
          appBar: AppBar(title: const Text('Pedir ajuda')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                VigiSpace.screen,
                0,
                VigiSpace.screen,
                VigiSpace.screen,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    sending
                        ? 'Enviando o seu pedido…'
                        : 'Segure o botão por 3 segundos.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: VigiSpace.block),
                  Center(
                    child: sending
                        ? const SizedBox.square(
                            dimension: VigiSizes.panic + 44,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : PanicButton(
                            onReleasedEarly: () =>
                                setState(() => _releasedEarly = true),
                            onPanicTriggered: () =>
                                setState(() => _releasedEarly = false),
                          ),
                  ),
                  const SizedBox(height: VigiSpace.x4),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _releasedEarly
                          ? PanicButton.releasedEarlyMessage
                          : 'Toques rápidos não pedem ajuda por engano.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: palette.textMuted,
                        fontWeight: _releasedEarly
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: VigiSpace.block),
                  BlocBuilder<ContactsBloc, ContactsState>(
                    builder: (context, contactsState) => _Recipients(
                      contacts: contactsState is ContactsLoaded
                          ? contactsState.contacts
                          : const [],
                      loaded: contactsState is ContactsLoaded,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Quem vai receber o pedido.
class _Recipients extends StatelessWidget {
  const _Recipients({required this.contacts, required this.loaded});

  final List<EmergencyContactEntity> contacts;
  final bool loaded;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;

    if (loaded && contacts.isEmpty) {
      return AppCard(
        child: Text(
          'Ninguém será avisado: você ainda não escolheu quem deve receber '
          'o pedido. Adicione uma pessoa em Pessoas.',
          style: AppTypography.bodyMedium.copyWith(color: palette.text),
        ),
      );
    }
    if (contacts.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vamos avisar',
            style: AppTypography.caption.copyWith(
              color: palette.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: VigiSpace.x2),
          for (final contact in contacts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VigiSpace.x1 + 2),
              child: Row(
                children: [
                  ContactAvatar(name: contact.name, size: 40),
                  const SizedBox(width: VigiSpace.x3),
                  Expanded(
                    child: Text(
                      [
                        VigiText.firstName(contact.name),
                        if ((contact.relationship ?? '').trim().isNotEmpty)
                          contact.relationship!.trim().toLowerCase(),
                      ].join(', '),
                      style: AppTypography.label.copyWith(color: palette.text),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: VigiSpace.x1),
          Text(
            'Com a sua localização.',
            style: AppTypography.bodyMedium.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}
