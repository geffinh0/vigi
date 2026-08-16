import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../bloc/family_bloc.dart';
import '../bloc/family_event.dart';
import '../bloc/family_state.dart';

class FamilyPanelPage extends StatefulWidget {
  const FamilyPanelPage({super.key});

  @override
  State<FamilyPanelPage> createState() => _FamilyPanelPageState();
}

class _FamilyPanelPageState extends State<FamilyPanelPage> {
  @override
  void initState() {
    super.initState();
    context.read<FamilyBloc>().add(const LoadFamilyLinksRequested());
  }

  void _showInviteDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.linho,
          title: Text(
            'Vincular Familiar / Cuidador',
            style: AppTypography.h3.copyWith(color: AppColors.petroleo),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Informe o UUID da conta do familiar para permitir o acompanhamento em tempo real.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.cinzaTexto,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'UUID do Familiar',
                  hintText: 'Ex: e1b8a9...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.cinzaTexto),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ambar,
                foregroundColor: AppColors.petroleo,
              ),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  context.read<FamilyBloc>().add(
                    SendFamilyInviteRequested(controller.text.trim()),
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Enviar Convite'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.linho,
      appBar: AppBar(
        title: const Text('Painel Familiar e Vínculos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ambar,
        foregroundColor: AppColors.petroleo,
        icon: const Icon(Icons.group_add),
        label: const Text(
          'Novo Vínculo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: _showInviteDialog,
      ),
      body: BlocConsumer<FamilyBloc, FamilyState>(
        listener: (context, state) {
          if (state is FamilyFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.panico,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is FamilyLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.petroleo),
            );
          }

          if (state is FamilyLoaded) {
            if (state.links.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 72,
                        color: AppColors.cinzaTexto,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum vínculo familiar ativo',
                        style: AppTypography.h3.copyWith(
                          color: AppColors.petroleo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vincule sua conta a familiares ou cuidadores para que eles possam acompanhar seu bem-estar.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.cinzaTexto,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppPrimaryButton(
                        text: 'Conectar com um Familiar',
                        icon: Icons.add_link,
                        onPressed: _showInviteDialog,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.links.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final link = state.links[index];
                return AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: link.isAccepted
                          ? AppColors.petroleo
                          : AppColors.cinzaTexto,
                      foregroundColor: AppColors.linho,
                      child: Icon(
                        link.isAccepted
                            ? Icons.verified_user
                            : Icons.hourglass_top,
                      ),
                    ),
                    title: Text(
                      link.viewerUserName ??
                          link.monitoredUserName ??
                          'Vínculo Familiar',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Status: ${link.status.toUpperCase()}',
                      style: AppTypography.caption.copyWith(
                        color: link.isAccepted
                            ? AppColors.petroleo
                            : AppColors.ambar,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: link.isPending
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.ambar,
                              foregroundColor: AppColors.petroleo,
                              minimumSize: const Size(80, 36),
                            ),
                            onPressed: () {
                              context.read<FamilyBloc>().add(
                                AcceptFamilyInviteRequested(link.id),
                              );
                            },
                            child: const Text('Aceitar'),
                          )
                        : const Icon(Icons.check_circle, color: Colors.green),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
