import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/browser/browser_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../panic/domain/entities/panic_alert_entity.dart';
import '../../domain/entities/wellbeing_status.dart';
import '../cubit/family_dashboard_cubit.dart';

const _verde = Color(0xFF2E7D5B);

String _hhmm(DateTime t, DateTime now) {
  final l = t.toLocal();
  final n = now.toLocal();
  final hm =
      '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  final sameDay = l.year == n.year && l.month == n.month && l.day == n.day;
  return sameDay
      ? hm
      : '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')} $hm';
}

String _relative(DateTime t, DateTime now) {
  final d = now.difference(t);
  if (d.inMinutes < 1) return 'agora mesmo';
  if (d.inMinutes < 60) return 'há ${d.inMinutes} min';
  if (d.inHours < 24) return 'há ${d.inHours} h';
  return 'há ${d.inDays} dia(s)';
}

String _eventLabel(String type) => switch (type) {
  'checkin' => 'Confirmou que está bem',
  'routine_start' => 'Iniciou o monitoramento',
  'panic' => 'Acionou o botão de pânico',
  'alert_triggered' => 'Não respondeu ao check-in',
  'alert_resolved' => 'Cancelou o alerta (está segura)',
  _ => type,
};

/// Painel do familiar (VIGI Família): mostra apenas se a pessoa está bem,
/// o último sinal e o próximo check-in. A localização só aparece em
/// emergências. Usado no PWA web e também no app Android.
class FamilyDashboardPage extends StatefulWidget {
  const FamilyDashboardPage({super.key, this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  State<FamilyDashboardPage> createState() => _FamilyDashboardPageState();
}

class _FamilyDashboardPageState extends State<FamilyDashboardPage> {
  final AudioPlayer _player = AudioPlayer();
  bool _ringing = false;

  @override
  void initState() {
    super.initState();
    unawaited(BrowserNotifier.requestPermission());
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _ring(String text) async {
    BrowserNotifier.show('VIGI: EMERGÊNCIA', text);
    setState(() => _ringing = true);
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('audio/alarm.wav'));
    } catch (_) {}
  }

  Future<void> _silence() async {
    setState(() => _ringing = false);
    try {
      await _player.stop();
    } catch (_) {}
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    final cubit = context.read<FamilyDashboardCubit>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.linho,
        title: Text(
          'Acompanhar uma pessoa',
          style: AppTypography.h3.copyWith(color: AppColors.petroleo),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No celular da pessoa, abra o VIGI e toque em "Família". '
              'Digite aqui o código que aparece lá.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.cinzaTexto,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 7,
              style: AppTypography.h2.copyWith(letterSpacing: 4),
              decoration: const InputDecoration(
                labelText: 'Código VIGI',
                hintText: 'K7P-2QX',
                counterText: '',
              ),
              onSubmitted: (_) {
                Navigator.of(dialogContext).pop();
                unawaited(cubit.requestLink(controller.text));
              },
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
              Navigator.of(dialogContext).pop();
              unawaited(cubit.requestLink(controller.text));
            },
            child: const Text('Enviar pedido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.linho,
      appBar: AppBar(
        title: const Text('VIGI Família'),
        actions: [
          IconButton(
            tooltip: 'Acompanhar uma pessoa',
            icon: const Icon(Icons.person_add_alt_1, color: AppColors.petroleo),
            onPressed: _showAddDialog,
          ),
          if (widget.onSignOut != null)
            IconButton(
              tooltip: 'Sair',
              icon: const Icon(Icons.logout, color: AppColors.cinzaTexto),
              onPressed: widget.onSignOut,
            ),
        ],
      ),
      body: BlocConsumer<FamilyDashboardCubit, FamilyDashboardState>(
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.errorMessage != null) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.panico,
              ),
            );
          } else if (state.infoMessage != null) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.infoMessage!),
                backgroundColor: AppColors.petroleo,
                duration: const Duration(seconds: 6),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.petroleo),
            );
          }
          final now = state.now ?? DateTime.now();

          return BlocListener<FamilyDashboardCubit, FamilyDashboardState>(
            listenWhen: (p, c) => p.alertSignal != c.alertSignal,
            listener: (context, state) =>
                _ring(state.alertText ?? 'Emergência detectada'),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_ringing) ...[
                      _AlarmBanner(
                        text: state.alertText ?? 'Emergência detectada',
                        onSilence: _silence,
                      ),
                      const SizedBox(height: 16),
                    ],
                    for (final person in state.people) ...[
                      _PersonCard(person: person, now: now),
                      const SizedBox(height: 16),
                    ],
                    for (final pending in state.pendingRequests) ...[
                      AppCard(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.hourglass_top,
                              color: AppColors.ambar,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Aguardando '
                                '${pending.monitoredUserName ?? 'a pessoa'} '
                                'tocar em "Permitir" no celular dela.',
                                style: AppTypography.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (state.people.isEmpty && state.pendingRequests.isEmpty)
                      _EmptyState(onAdd: _showAddDialog),
                    const SizedBox(height: 8),
                    Text(
                      'Privacidade: o VIGI não rastreia a localização. Ela só '
                      'é compartilhada quando a pessoa aciona o pânico ou não '
                      'responde a um check-in.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.cinzaTexto,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AlarmBanner extends StatelessWidget {
  const _AlarmBanner({required this.text, required this.onSilence});

  final String text;
  final VoidCallback onSilence;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.panico,
      borderColor: AppColors.panico,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: AppTypography.h3.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
            ),
            icon: const Icon(Icons.volume_off),
            label: const Text('Estou ciente — silenciar alarme'),
            onPressed: onSilence,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    Widget step(String n, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.petroleo,
            child: Text(
              n,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.family_restroom,
            size: 64,
            color: AppColors.petroleo,
          ),
          const SizedBox(height: 12),
          Text(
            'Você ainda não acompanha ninguém',
            textAlign: TextAlign.center,
            style: AppTypography.h3.copyWith(color: AppColors.petroleo),
          ),
          const SizedBox(height: 16),
          step('1', 'No celular da pessoa, abra o VIGI e toque em "Família".'),
          step('2', 'Digite aqui o código VIGI que aparece na tela dela.'),
          step('3', 'Ela toca em "Permitir". Pronto!'),
          const SizedBox(height: 8),
          AppPrimaryButton(
            text: 'Acompanhar uma pessoa',
            icon: Icons.person_add_alt_1,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person, required this.now});

  final MonitoredPersonView person;
  final DateTime now;

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final status = person.status;
    final alert = status.alertEvent;

    final (
      Color color,
      IconData icon,
      String title,
      String detail,
    ) = switch (status.level) {
      WellbeingLevel.ok => (
        _verde,
        Icons.check_circle,
        'Está tudo bem',
        status.nextDeadline != null
            ? 'Próximo check-in até ${_hhmm(status.nextDeadline!, now)}'
            : 'Monitoramento ativo',
      ),
      WellbeingLevel.late => (
        AppColors.ambar,
        Icons.schedule,
        'Check-in atrasado',
        'Deveria ter confirmado até '
            '${_hhmm(status.nextDeadline!, now)}. O alarme está tocando '
            'no celular; se não houver resposta, os contatos serão avisados.',
      ),
      WellbeingLevel.emergency => (
        AppColors.panico,
        status.isPanic ? Icons.emergency : Icons.warning_amber_rounded,
        status.isPanic
            ? 'PÂNICO acionado às ${_hhmm(alert!.createdAt!, now)}'
            : 'Não respondeu ao check-in '
                  '(${_hhmm(alert!.createdAt!, now)})',
        'Os contatos de emergência foram avisados por SMS. '
            'Tente falar com a pessoa agora.',
      ),
      WellbeingLevel.paused => (
        AppColors.cinzaTexto,
        Icons.pause_circle_filled,
        'Monitoramento pausado',
        'A proteção está desligada no celular da pessoa.',
      ),
    };

    final phone = person.link.monitoredUserPhone?.trim();
    final hasLocation = alert?.latitude != null && alert?.longitude != null;

    return AppCard(
      borderColor: status.level == WellbeingLevel.emergency ? color : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.petroleo,
                foregroundColor: AppColors.linho,
                child: Text(person.name.characters.first.toUpperCase()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: AppTypography.h3.copyWith(
                        color: AppColors.petroleo,
                      ),
                    ),
                    if (person.modeName != null &&
                        status.level != WellbeingLevel.paused)
                      Text(
                        'Modo: ${person.modeName}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.cinzaTexto,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.h3.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(detail, style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            status.lastSignal == null
                ? 'Ainda sem sinais registrados'
                : 'Último sinal: ${_relative(status.lastSignal!, now)} '
                      '(${_hhmm(status.lastSignal!, now)})',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.cinzaTexto,
            ),
          ),
          if (hasLocation || (phone != null && phone.isNotEmpty)) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (hasLocation)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.panico,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.location_on),
                    label: const Text('Ver localização do alerta'),
                    onPressed: () => _open(
                      'https://maps.google.com/?q=${alert!.latitude},${alert.longitude}',
                    ),
                  ),
                if (phone != null && phone.isNotEmpty)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.petroleo,
                    ),
                    icon: const Icon(Icons.call),
                    label: const Text('Ligar'),
                    onPressed: () => _open('tel:$phone'),
                  ),
              ],
            ),
          ],
          if (person.recentEvents.isNotEmpty)
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Atividade recente',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: [
                  for (final e in person.recentEvents)
                    _EventRow(e: e, now: now),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.e, required this.now});

  final PanicAlertEntity e;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final isAlert = e.eventType == 'panic' || e.eventType == 'alert_triggered';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isAlert ? Icons.warning_amber_rounded : Icons.check,
        color: isAlert ? AppColors.panico : _verde,
      ),
      title: Text(_eventLabel(e.eventType)),
      trailing: e.createdAt == null
          ? null
          : Text(
              _hhmm(e.createdAt!, now),
              style: AppTypography.caption.copyWith(
                color: AppColors.cinzaTexto,
              ),
            ),
    );
  }
}
