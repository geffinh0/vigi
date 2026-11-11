import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vigi_palette.dart';
import '../../../../core/theme/vigi_tokens.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/vigi_dialogs.dart';
import '../../domain/entities/emergency_contact_entity.dart';
import '../bloc/contacts_bloc.dart';
import '../bloc/contacts_event.dart';
import '../bloc/contacts_state.dart';
import '../widgets/contact_widgets.dart';

/// Lista de quem será avisado, com o botão "Adicionar pessoa". É usada
/// dentro da aba Pessoas e também como tela própria ([ContactsPage]).
class ContactsSection extends StatefulWidget {
  const ContactsSection({super.key});

  @override
  State<ContactsSection> createState() => _ContactsSectionState();
}

class _ContactsSectionState extends State<ContactsSection> {
  List<EmergencyContactEntity>? _contacts;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<ContactsBloc>();
    final state = bloc.state;
    if (state is ContactsLoaded) {
      _contacts = state.contacts;
    } else if (state is! ContactsLoading) {
      bloc.add(const LoadContactsRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;

    return BlocConsumer<ContactsBloc, ContactsState>(
      listener: (context, state) {
        if (state is ContactsFailure) {
          showVigiMessage(context, state.message);
        } else if (state is ContactsLoaded) {
          setState(() => _contacts = state.contacts);
        }
      },
      builder: (context, state) {
        final contacts = _contacts;

        if (contacts == null) {
          if (state is ContactsFailure) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Não conseguimos carregar suas pessoas. Confira a internet '
                  'e tente de novo.',
                  style: AppTypography.bodyLarge.copyWith(color: palette.text),
                ),
                const SizedBox(height: VigiSpace.x4),
                AppPrimaryButton(
                  text: 'Tentar de novo',
                  variant: AppButtonVariant.outline,
                  onPressed: () => context.read<ContactsBloc>().add(
                    const LoadContactsRequested(),
                  ),
                ),
              ],
            );
          }
          return const Padding(
            padding: EdgeInsets.all(VigiSpace.x8),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (contacts.isEmpty) ...[
              Text(
                'Quem deve ser avisado se você não responder?',
                style: AppTypography.h3.copyWith(color: palette.text),
              ),
              const SizedBox(height: VigiSpace.x2),
              Text(
                'O Vigi só começa a vigiar depois que você escolher pelo '
                'menos uma pessoa.',
                style: AppTypography.bodyLarge.copyWith(color: palette.text),
              ),
              const SizedBox(height: VigiSpace.x4),
            ] else
              for (final contact in contacts) ...[
                ContactCard(
                  contact: contact,
                  onTap: () => showContactSheet(context, contact),
                ),
                const SizedBox(height: VigiSizes.touchGap),
              ],
            AppPrimaryButton(
              text: 'Adicionar pessoa',
              icon: Icons.person_add_alt_1_rounded,
              variant: contacts.isEmpty
                  ? AppButtonVariant.primary
                  : AppButtonVariant.outline,
              onPressed: () => showAddContactSheet(context),
            ),
          ],
        );
      },
    );
  }
}

/// Tela própria das pessoas de vigília.
class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pessoas de vigília')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            VigiSpace.screen,
            VigiSpace.x2,
            VigiSpace.screen,
            VigiSpace.x6,
          ),
          child: ContactsSection(),
        ),
      ),
    );
  }
}
