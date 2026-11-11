import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/browser/browser_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/vigi_palette.dart';
import '../../../../core/theme/vigi_tokens.dart';
import '../../../../core/utils/vigi_text.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/vigi_dialogs.dart';
import '../../../../core/widgets/vigi_mascot.dart';
import '../../../../core/widgets/vigi_text_field.dart';
import '../../../panic/domain/entities/panic_alert_entity.dart';
import '../../domain/entities/wellbeing_status.dart';
import '../cubit/family_dashboard_cubit.dart';

/// Horário de um evento: só a hora se foi hoje, senão com o dia.
String _when(DateTime t, DateTime now) {
  final l = t.toLocal();
  final n = now.toLocal();
  final sameDay = l.year == n.year && l.month == n.month && l.day == n.day;
  if (sameDay) return VigiText.clock(l);
  return '${l.day.toString().padLeft(2, '0')}/'
      '${l.month.toString().padLeft(2, '0')} às ${VigiText.clock(l)}';
}

String _eventLabel(String type) => switch (type) {
  'checkin' => 'Confirmou que está bem',
  'routine_start' => 'Começou a vigília',
  'panic' => 'Pediu ajuda',
  'alert_triggered' => 'Não respondeu ao check-in',
  'alert_resolved' => 'Cancelou o pedido de ajuda',
  _ => 'Atividade registrada',
};

/// Painel do familiar (Vigi Família). É desenhado para quem acompanha, não
/// para a pessoa acompanhada: o topo diz em uma frase como ela está; abaixo,
/// uma linha do tempo do dia. O familiar não vê a localização fora de um
/// alerta.
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
    BrowserNotifier.show('Vigi: pedido de ajuda', text);
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

  Future<void> _showAddSheet() async {
    final cubit = context.read<FamilyDashboardCubit>();
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const _AddPersonSheet(),
    );
    if (code != null && code.trim().isNotEmpty) {
      unawaited(cubit.requestLink(code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: VigiSpace.screen,
        title: const Text('Vigi Família'),
      ),
      body: BlocConsumer<FamilyDashboardCubit, FamilyDashboardState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            showVigiMessage(context, state.errorMessage!);
          } else if (state.infoMessage != null) {
            showVigiMessage(context, state.infoMessage!);
          }
        },
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final now = state.now ?? DateTime.now();

          return BlocListener<FamilyDashboardCubit, FamilyDashboardState>(
            listenWhen: (p, c) => p.alertSignal != c.alertSignal,
            listener: (context, state) => _ring(
              state.alertText ?? 'Alguém que você acompanha pediu ajuda',
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      VigiSpace.screen,
                      VigiSpace.x2,
                      VigiSpace.screen,
                      VigiSpace.x6,
                    ),
                    children: [
                      if (_ringing) ...[
                        _AlarmBanner(
                          text:
                              state.alertText ??
                              'Alguém que você acompanha pediu ajuda',
                          onSilence: _silence,
                        ),
                        const SizedBox(height: VigiSpace.x4),
                      ],
                      for (final person in state.people) ...[
                        _PersonCard(person: person, now: now),
                        const SizedBox(height: VigiSpace.block),
                      ],
                      for (final pending in state.pendingRequests) ...[
                        AppCard(
                          child: Text(
                            'Aguardando '
                            '${VigiText.firstName(pending.monitoredUserName).isEmpty ? 'a pessoa' : VigiText.firstName(pending.monitoredUserName)} '
                            'aceitar. Peça para tocar em "Permitir" no Vigi '
                            'do celular.',
                            style: AppTypography.bodyLarge.copyWith(
                              color: palette.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: VigiSpace.x4),
                      ],
                      if (state.people.isEmpty && state.pendingRequests.isEmpty)
                        const _EmptyState(),
                      const SizedBox(height: VigiSpace.x4),
                      AppPrimaryButton(
                        text: 'Acompanhar uma pessoa',
                        variant:
                            state.people.isEmpty &&
                                state.pendingRequests.isEmpty
                            ? AppButtonVariant.primary
                            : AppButtonVariant.outline,
                        onPressed: _showAddSheet,
                      ),
                      const SizedBox(height: VigiSpace.block),
                      Text(
                        'Cuidado, não vigilância: o Vigi não rastreia '
                        'ninguém. A localização só é compartilhada quando a '
                        'pessoa pede ajuda ou não responde a um check-in.',
                        style: AppTypography.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                      if (widget.onSignOut != null) ...[
                        const SizedBox(height: VigiSpace.x6),
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
                    ],
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

/// Folha "Acompanhar uma pessoa": o familiar digita o código de convite.
class _AddPersonSheet extends StatefulWidget {
  const _AddPersonSheet();

  @override
  State<_AddPersonSheet> createState() => _AddPersonSheetState();
}

class _AddPersonSheetState extends State<_AddPersonSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Acompanhar uma pessoa',
                style: AppTypography.h2.copyWith(color: palette.text),
              ),
            ),
            const SizedBox(height: VigiSpace.x2),
            Text(
              'Peça para a pessoa abrir o Vigi, tocar em Pessoas e depois em '
              '"Convidar a família". O código de 6 letras aparece lá.',
              style: AppTypography.bodyMedium.copyWith(
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: VigiSpace.x6),
            VigiTextField(
              label: 'Código de convite',
              hint: 'K7P-2QX',
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 7,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              style: AppTypography.h2.copyWith(
                color: palette.text,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: VigiSpace.x6),
            AppPrimaryButton(text: 'Enviar pedido', onPressed: _submit),
            const SizedBox(height: VigiSizes.touchGap),
            AppPrimaryButton(
              text: 'Cancelar',
              variant: AppButtonVariant.outline,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faixa que acompanha o alarme sonoro de um pedido de ajuda novo.
class _AlarmBanner extends StatelessWidget {
  const _AlarmBanner({required this.text, required this.onSilence});

  final String text;
  final VoidCallback onSilence;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(VigiSpace.x4),
        decoration: BoxDecoration(
          color: VigiColors.sinal600,
          borderRadius: BorderRadius.circular(VigiRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              text,
              style: AppTypography.h3.copyWith(color: VigiColors.branco),
            ),
            const SizedBox(height: VigiSpace.x3),
            AppPrimaryButton(
              text: 'Estou ciente, silenciar o alarme',
              variant: AppButtonVariant.onSignal,
              onPressed: onSilence,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;

    Widget step(String n, String text) => Padding(
      padding: const EdgeInsets.only(bottom: VigiSpace.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.chip,
              shape: BoxShape.circle,
            ),
            child: Text(
              n,
              textScaler: TextScaler.noScaling,
              style: AppTypography.label.copyWith(color: palette.text),
            ),
          ),
          const SizedBox(width: VigiSpace.x3),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyLarge.copyWith(color: palette.text),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: VigiSymbol(size: 96),
        ),
        const SizedBox(height: VigiSpace.x3),
        Text(
          'Você ainda não acompanha ninguém',
          style: AppTypography.h2.copyWith(color: palette.text),
        ),
        const SizedBox(height: VigiSpace.x4),
        step('1', 'No celular da pessoa, abra o Vigi e toque em Pessoas.'),
        step('2', 'Toque em "Convidar a família" e anote o código.'),
        step('3', 'Digite o código aqui. A pessoa toca em "Permitir".'),
      ],
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

  bool _isToday(DateTime? t) {
    if (t == null) return false;
    final l = t.toLocal();
    final n = now.toLocal();
    return l.year == n.year && l.month == n.month && l.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    final status = person.status;
    final alert = status.alertEvent;
    final first = VigiText.firstName(person.name);
    final lastSignal = status.lastSignal;
    final deadline = status.nextDeadline;

    // O topo diz em uma frase como a pessoa está.
    final (
      VigiState state,
      String title,
      String detail,
    ) = switch (status.level) {
      WellbeingLevel.ok => (
        VigiState.vigiando,
        '$first está bem.',
        [
          if (lastSignal != null) 'Confirmou às ${_when(lastSignal, now)}.',
          if (deadline != null) 'Próximo às ${_when(deadline, now)}.',
        ].join(' '),
      ),
      WellbeingLevel.late => (
        VigiState.suaVez,
        '$first ainda não respondeu.',
        'O check-in era às ${_when(deadline!, now)}. O Vigi está '
            'chamando no celular; sem resposta, os contatos serão '
            'avisados.',
      ),
      WellbeingLevel.emergency => (
        VigiState.alerta,
        status.isPanic
            ? '$first pediu ajuda às ${_when(alert!.createdAt!, now)}.'
            : '$first não respondeu ao check-in.',
        'Os contatos foram avisados por SMS. Tente ligar agora.',
      ),
      WellbeingLevel.paused => (
        VigiState.descansando,
        'A vigília de $first está pausada.',
        lastSignal == null
            ? 'O Vigi não está vigiando agora.'
            : 'O Vigi não está vigiando agora. Último sinal às '
                  '${_when(lastSignal, now)}.',
      ),
    };

    final (Color background, Color foreground) = switch (status.level) {
      WellbeingLevel.ok => (VigiColors.petroleo800, VigiColors.linho100),
      WellbeingLevel.late => (VigiColors.ambar100, VigiColors.petroleo800),
      WellbeingLevel.emergency => (VigiColors.sinal600, VigiColors.branco),
      WellbeingLevel.paused => (palette.surface, palette.text),
    };

    final phone = person.link.monitoredUserPhone?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;
    final hasLocation = alert?.latitude != null && alert?.longitude != null;
    final today = person.recentEvents
        .where((e) => _isToday(e.createdAt))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            person.name,
            style: AppTypography.h2.copyWith(color: palette.text),
          ),
        ),
        if (person.modeName != null && status.level != WellbeingLevel.paused)
          Text(
            'Modo ${person.modeName}',
            style: AppTypography.bodyMedium.copyWith(color: palette.textMuted),
          ),
        const SizedBox(height: VigiSpace.x3),
        Semantics(
          liveRegion: status.level == WellbeingLevel.emergency,
          child: Container(
            padding: const EdgeInsets.all(VigiSpace.x4),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(VigiRadius.md),
              border: status.level == WellbeingLevel.paused
                  ? Border.all(color: palette.border)
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (status.level == WellbeingLevel.ok)
                  const VigiSymbol(size: 56, onPetroleo: true)
                else
                  VigiMascot(
                    state: state,
                    size: 56,
                    animate: false,
                    onSignal: status.level == WellbeingLevel.emergency,
                  ),
                const SizedBox(width: VigiSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.h3.copyWith(color: foreground),
                      ),
                      if (detail.isNotEmpty) ...[
                        const SizedBox(height: VigiSpace.x1),
                        Text(
                          detail,
                          style: AppTypography.bodyMedium.copyWith(
                            color: foreground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasLocation) ...[
          const SizedBox(height: VigiSizes.touchGap),
          AppPrimaryButton(
            text: 'Ver onde $first está',
            icon: Icons.location_on_rounded,
            onPressed: () => _open(
              'https://maps.google.com/?q=${alert!.latitude},${alert.longitude}',
            ),
          ),
        ],
        if (hasPhone) ...[
          const SizedBox(height: VigiSizes.touchGap),
          AppPrimaryButton(
            text: 'Ligar para $first',
            icon: Icons.call_rounded,
            variant: AppButtonVariant.outline,
            onPressed: () => _open('tel:$phone'),
          ),
        ],
        const SizedBox(height: VigiSpace.x6),
        Text('Hoje', style: AppTypography.h3.copyWith(color: palette.text)),
        const SizedBox(height: VigiSpace.x2),
        if (today.isEmpty)
          Text(
            'Nada registrado hoje ainda.',
            style: AppTypography.bodyMedium.copyWith(color: palette.textMuted),
          )
        else
          for (final e in today) _EventRow(e: e),
      ],
    );
  }
}

/// Uma linha da linha do tempo do dia: horário, marcador e o que aconteceu.
class _EventRow extends StatelessWidget {
  const _EventRow({required this.e});

  final PanicAlertEntity e;

  @override
  Widget build(BuildContext context) {
    final palette = context.vigi;
    final isAlert = e.eventType == 'panic' || e.eventType == 'alert_triggered';
    final isCheckin = e.eventType == 'checkin';
    // Nenhum estado é comunicado só por cor: o marcador muda de forma
    // (cheio, vazado) e o texto diz o que aconteceu.
    final dotColor = isAlert ? VigiColors.sinal500 : palette.text;

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: VigiSpace.x2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: Text(
                e.createdAt == null ? '' : VigiText.clockPadded(e.createdAt!),
                style: AppTypography.bodyMedium.copyWith(
                  color: palette.textMuted,
                  fontFeatures: AppTypography.tabular,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, right: VigiSpace.x3),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCheckin || isAlert ? dotColor : Colors.transparent,
                  border: Border.all(color: dotColor, width: 2),
                ),
              ),
            ),
            Expanded(
              child: Text(
                _eventLabel(e.eventType),
                style: AppTypography.bodyMedium.copyWith(
                  color: palette.text,
                  fontWeight: isAlert ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
