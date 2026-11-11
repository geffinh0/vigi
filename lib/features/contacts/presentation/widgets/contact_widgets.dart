import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/emergency_dispatcher.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vigi_palette.dart';
import '../../../../core/theme/vigi_tokens.dart';
import '../../../../core/utils/vigi_text.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/contact_avatar.dart';
import '../../../../core/widgets/vigi_dialogs.dart';
import '../../../../core/widgets/vigi_text_field.dart';
import '../../domain/entities/emergency_contact_entity.dart';
import '../bloc/contacts_bloc.dart';
import '../bloc/contacts_event.dart';

/// O telefone tem DDD e número suficientes para receber SMS.
bool isPhoneComplete(String phone) => normalizePhone(phone).length >= 12;

/// Erro de telefone que explica como corrigir.
String? validateContactPhone(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) {
    return 'Digite o telefone com DDD. Exemplo: (11) 98765-4321.';
  }
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10) {
    return 'Falta o DDD. Exemplo: (11) 98765-4321.';
  }
  return null;
}

/// Card de contato: avatar com iniciais, nome, relação e telefone, e o
/// status. Um contato sem telefone válido mostra aviso em Cinza texto, não
/// em vermelho.
class ContactCard extends StatelessWidget {
  const ContactCard({super.key, required this.contact, this.onTap});

  final EmergencyContactEntity contact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    final complete = isPhoneComplete(contact.phone);
    final relation = (contact.relationship ?? '').trim();
    final status = complete ? 'Recebe alertas' : 'Telefone incompleto';

    return Semantics(
      button: onTap != null,
      label:
          '${contact.name}${relation.isEmpty ? '' : ', $relation'}, '
          '${contact.phone}. $status.',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            ContactAvatar(name: contact.name),
            const SizedBox(width: VigiSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: AppTypography.h3.copyWith(color: palette.text),
                  ),
                  Text(
                    [if (relation.isNotEmpty) relation, contact.phone].join(
                      ' · ',
                    ),
                    style: AppTypography.bodyMedium.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: VigiSpace.x1),
                  Text(
                    status,
                    style: AppTypography.caption.copyWith(
                      color: complete ? palette.text : palette.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Folha de um contato, com a ação de remover separada e confirmada.
Future<void> showContactSheet(
  BuildContext context,
  EmergencyContactEntity contact,
) {
  final bloc = context.read<ContactsBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final palette = sheetContext.vigi;
      final first = VigiText.firstName(contact.name);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            VigiSpace.screen,
            0,
            VigiSpace.screen,
            VigiSpace.x6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ContactAvatar(name: contact.name),
                  const SizedBox(width: VigiSpace.x3),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        contact.name,
                        style: AppTypography.h2.copyWith(color: palette.text),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VigiSpace.x3),
              Text(
                isPhoneComplete(contact.phone)
                    ? '$first recebe um SMS em ${contact.phone} quando você '
                          'pede ajuda ou não responde a um check-in.'
                    : 'O telefone ${contact.phone} está incompleto, então '
                          '$first não recebe alertas. Remova e adicione de '
                          'novo com o DDD.',
                style: AppTypography.bodyLarge.copyWith(color: palette.text),
              ),
              const SizedBox(height: VigiSpace.x6),
              AppPrimaryButton(
                text: 'Fechar',
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
              const SizedBox(height: VigiSizes.touchGap),
              AppPrimaryButton(
                text: 'Remover $first',
                variant: AppButtonVariant.outline,
                onPressed: () async {
                  final ok = await showVigiConfirm(
                    sheetContext,
                    title: 'Remover $first?',
                    message:
                        '$first deixa de receber avisos quando você pedir '
                        'ajuda ou não responder a um check-in.',
                    confirmLabel: 'Remover $first',
                  );
                  if (!ok) return;
                  bloc.add(DeleteContactRequested(contact.id));
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Folha "Adicionar pessoa".
Future<void> showAddContactSheet(BuildContext context) {
  final bloc = context.read<ContactsBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _AddContactSheet(
      onSave: (name, phone, relationship) {
        bloc.add(
          AddContactRequested(
            name: name,
            phone: phone,
            relationship: relationship,
          ),
        );
        Navigator.of(sheetContext).pop();
      },
    ),
  );
}

class _AddContactSheet extends StatefulWidget {
  const _AddContactSheet({required this.onSave});

  final void Function(String name, String phone, String? relationship) onSave;

  @override
  State<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<_AddContactSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _relation = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relation.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final relation = _relation.text.trim();
    widget.onSave(
      _name.text.trim(),
      _phone.text.trim(),
      relation.isEmpty ? null : relation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          VigiSpace.screen,
          0,
          VigiSpace.screen,
          VigiSpace.x6 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Quem deve ser avisado?',
                  style: AppTypography.h2.copyWith(color: palette.text),
                ),
              ),
              const SizedBox(height: VigiSpace.x2),
              Text(
                'Essa pessoa recebe um SMS com a sua localização quando você '
                'pede ajuda ou não responde a um check-in.',
                style: AppTypography.bodyMedium.copyWith(
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: VigiSpace.x6),
              VigiTextField(
                label: 'Nome',
                hint: 'Exemplo: Maria',
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Digite o nome da pessoa.'
                    : null,
              ),
              const SizedBox(height: VigiSpace.x4),
              VigiTextField(
                label: 'Telefone com DDD',
                hint: '(11) 98765-4321',
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: validateContactPhone,
              ),
              const SizedBox(height: VigiSpace.x4),
              VigiTextField(
                label: 'Quem é para você (opcional)',
                hint: 'Exemplo: filha, vizinho, cuidadora',
                controller: _relation,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: VigiSpace.x6),
              AppPrimaryButton(text: 'Salvar', onPressed: _submit),
              const SizedBox(height: VigiSizes.touchGap),
              AppPrimaryButton(
                text: 'Cancelar',
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
