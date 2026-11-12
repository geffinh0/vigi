import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/vigi_palette.dart';
import '../../core/theme/vigi_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_primary_button.dart';
import '../../features/contacts/presentation/pages/contacts_page.dart';
import '../../features/family/presentation/bloc/family_bloc.dart';
import '../../features/family/presentation/bloc/family_event.dart';
import '../../features/family/presentation/bloc/family_state.dart';

/// Aba "Pessoas": quem será avisado (contatos) e quem acompanha pelo app
/// (família). No fim, a saída da conta.
class PeopleTab extends StatefulWidget {
  const PeopleTab({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  @override
  void initState() {
    super.initState();
    final family = context.read<FamilyBloc>();
    if (family.state is FamilyInitial) {
      family.add(const LoadFamilyLinksRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        VigiSpace.screen,
        VigiSpace.x4,
        VigiSpace.screen,
        VigiSpace.x6,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            'Pessoas',
            style: AppTypography.h2.copyWith(color: palette.text),
          ),
        ),
        const SizedBox(height: VigiSpace.x6),
        Text(
          'Pessoas de vigília',
          style: AppTypography.h3.copyWith(color: palette.text),
        ),
        const SizedBox(height: VigiSpace.x1),
        Text(
          'Recebem um SMS com a sua localização quando você pede ajuda ou '
          'não responde a um check-in.',
          style: AppTypography.bodyMedium.copyWith(color: palette.textMuted),
        ),
        const SizedBox(height: VigiSpace.x4),
        const ContactsSection(),
        const SizedBox(height: VigiSpace.block),
        Text(
          'Família pelo app',
          style: AppTypography.h3.copyWith(color: palette.text),
        ),
        const SizedBox(height: VigiSpace.x1),
        Text(
          'Quem usa o Vigi Família vê se você está bem. A sua localização só '
          'é enviada em um pedido de ajuda.',
          style: AppTypography.bodyMedium.copyWith(color: palette.textMuted),
        ),
        const SizedBox(height: VigiSpace.x4),
        BlocBuilder<FamilyBloc, FamilyState>(
          buildWhen: (previous, current) => current is FamilyLoaded,
          builder: (context, state) {
            final pending = state is FamilyLoaded
                ? state.pendingRequests.length
                : 0;
            final followers = state is FamilyLoaded
                ? state.followers.length
                : 0;
            if (pending == 0) {
              return AppPrimaryButton(
                text: followers == 0
                    ? 'Convidar a família'
                    : 'Ver quem acompanha você',
                variant: AppButtonVariant.outline,
                onPressed: () => context.push('/family'),
              );
            }
            // É a vez da pessoa: alguém espera a autorização dela.
            return AppCard(
              backgroundColor: VigiColors.ambar100,
              borderColor: VigiColors.ambar100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    pending == 1
                        ? 'Uma pessoa quer acompanhar você.'
                        : '$pending pessoas querem acompanhar você.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: VigiColors.petroleo800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: VigiSpace.x3),
                  AppPrimaryButton(
                    text: 'Ver o pedido',
                    variant: AppButtonVariant.amber,
                    onPressed: () => context.push('/family'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: VigiSpace.block),
        Text(
          'Este aparelho',
          style: AppTypography.h3.copyWith(color: palette.text),
        ),
        const SizedBox(height: VigiSpace.x1),
        Text(
          'O que o Vigi pode usar do celular para chamar você e pedir ajuda.',
          style: AppTypography.bodyMedium.copyWith(color: palette.textMuted),
        ),
        const SizedBox(height: VigiSpace.x4),
        AppPrimaryButton(
          text: 'Ver permissões',
          variant: AppButtonVariant.outline,
          onPressed: () => context.push('/permissions'),
        ),
        const SizedBox(height: VigiSpace.x12),
        Center(
          child: TextButton(
            onPressed: widget.onSignOut,
            child: Text(
              'Sair da conta',
              style: AppTypography.label.copyWith(
                color: palette.textMuted,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
