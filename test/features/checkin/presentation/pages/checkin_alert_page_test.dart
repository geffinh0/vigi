import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardiao/core/theme/app_theme.dart';
import 'package:guardiao/core/widgets/vigi_mascot.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_bloc.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_event.dart';
import 'package:guardiao/features/checkin/presentation/bloc/checkin_state.dart';
import 'package:guardiao/features/checkin/presentation/pages/checkin_alert_page.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckinBloc extends MockBloc<CheckinEvent, CheckinState>
    implements CheckinBloc {}

void main() {
  late MockCheckinBloc mockCheckinBloc;

  setUp(() {
    mockCheckinBloc = MockCheckinBloc();
  });

  testWidgets(
    'CheckinAlertPage renderiza Mascote Vigi em alerta e botão ESTOU BEM',
    (tester) async {
      when(() => mockCheckinBloc.state).thenReturn(
        CheckinAlertActive(expiredAt: DateTime.now()),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          home: BlocProvider<CheckinBloc>.value(
            value: mockCheckinBloc,
            child: const CheckinAlertPage(),
          ),
        ),
      );

      expect(find.text('ALERTA DE CHECK-IN!'), findsOneWidget);
      expect(find.byType(VigiMascot), findsOneWidget);
      expect(find.text('ESTOU BEM (DESATIVAR ALARME)'), findsOneWidget);
      expect(find.text('DISPARAR PÂNICO'), findsOneWidget);
    },
  );
}
