import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../bloc/contacts_bloc.dart';
import '../bloc/contacts_event.dart';
import '../bloc/contacts_state.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ContactsBloc>().add(const LoadContactsRequested());
  }

  void _showAddContactDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.linho,
          title: Text(
            'Novo Contato de Emergência',
            style: AppTypography.h3.copyWith(color: AppColors.petroleo),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      hintText: 'Ex: Maria (Filha)',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe o nome'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefone com DDD',
                      hintText: '(11) 98765-4321',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Informe o telefone';
                      }
                      final digits = v.replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 10) {
                        return 'Informe o DDD e número válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: relationController,
                    decoration: const InputDecoration(
                      labelText: 'Parentesco / Relação',
                      hintText: 'Ex: Filha, Vizinho, Cuidador',
                    ),
                  ),
                ],
              ),
            ),
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
                if (formKey.currentState?.validate() ?? false) {
                  context.read<ContactsBloc>().add(
                    AddContactRequested(
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      relationship: relationController.text.trim().isNotEmpty
                          ? relationController.text.trim()
                          : null,
                    ),
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Salvar Contato'),
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
        title: const Text('Contatos de Emergência'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ambar,
        foregroundColor: AppColors.petroleo,
        icon: const Icon(Icons.person_add),
        label: const Text(
          'Adicionar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: _showAddContactDialog,
      ),
      body: BlocConsumer<ContactsBloc, ContactsState>(
        listener: (context, state) {
          if (state is ContactsFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.panico,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ContactsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.petroleo),
            );
          }

          if (state is ContactsLoaded) {
            if (state.contacts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.contact_emergency_outlined,
                        size: 72,
                        color: AppColors.cinzaTexto,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum contato cadastrado',
                        style: AppTypography.h3.copyWith(
                          color: AppColors.petroleo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cadastre pelo menos um contato de confiança para permitir o acionamento do monitoramento.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.cinzaTexto,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppPrimaryButton(
                        text: 'Cadastrar Primeiro Contato',
                        icon: Icons.add,
                        onPressed: _showAddContactDialog,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.contacts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final contact = state.contacts[index];
                return AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.petroleo,
                      foregroundColor: AppColors.linho,
                      child: Text(
                        contact.name.isNotEmpty
                            ? contact.name.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      contact.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.petroleo,
                      ),
                    ),
                    subtitle: Text(
                      '${contact.phone}${contact.relationship != null ? ' • ${contact.relationship}' : ''}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.cinzaTexto,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.panico,
                      ),
                      onPressed: () {
                        context.read<ContactsBloc>().add(
                          DeleteContactRequested(contact.id),
                        );
                      },
                    ),
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
