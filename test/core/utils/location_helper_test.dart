import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guardiao/core/utils/location_helper.dart';

/// Geolocalizador de mentira: registra se alguém pediu a permissão.
class FakeGeolocator extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.whileInUse;
  bool serviceEnabled = true;
  bool permissionRequested = false;
  Position? last;

  /// `null` = a busca nunca termina (GPS sem sinal).
  Future<Position> Function()? current;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequested = true;
    return permission;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) =>
      current?.call() ?? Completer<Position>().future;

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => last;
}

Position position(double latitude, double longitude) => Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: DateTime(2026, 9, 30, 15),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  late FakeGeolocator geolocator;
  late GeolocatorPlatform original;

  setUp(() {
    original = GeolocatorPlatform.instance;
    geolocator = FakeGeolocator();
    GeolocatorPlatform.instance = geolocator;
  });

  tearDown(() => GeolocatorPlatform.instance = original);

  group('LocationHelper.currentPositionOrNull', () {
    test('com permissão, devolve a posição atual', () async {
      geolocator.current = () async => position(-23.5, -46.6);
      final result = await LocationHelper.currentPositionOrNull();
      expect(result?.latitude, -23.5);
      expect(result?.longitude, -46.6);
    });

    for (final denied in [
      LocationPermission.denied,
      LocationPermission.deniedForever,
    ]) {
      test('sem permissão ($denied), segue sem localização e NÃO abre '
          'o diálogo do sistema', () async {
        geolocator
          ..permission = denied
          ..current = (() async => position(1, 1))
          ..last = position(2, 2);

        expect(await LocationHelper.currentPositionOrNull(), isNull);
        // Um diálogo esperando resposta seguraria o aviso aos contatos de
        // quem, justamente, não está respondendo.
        expect(geolocator.permissionRequested, isFalse);
      });
    }

    test('com o GPS desligado, usa a última posição conhecida', () async {
      geolocator
        ..serviceEnabled = false
        ..last = position(-22.9, -43.2);
      final result = await LocationHelper.currentPositionOrNull();
      expect(result?.latitude, -22.9);
    });

    test('se a busca falhar, usa a última posição conhecida', () async {
      geolocator
        ..current = (() => Future<Position>.error(TimeoutException('gps')))
        ..last = position(-22.9, -43.2);
      final result = await LocationHelper.currentPositionOrNull();
      expect(result?.latitude, -22.9);
    });

    testWidgets('GPS que nunca responde não segura o pedido de ajuda', (
      tester,
    ) async {
      geolocator.current = null;
      Position? result = position(9, 9);
      var done = false;
      unawaited(
        LocationHelper.currentPositionOrNull().then((value) {
          result = value;
          done = true;
        }),
      );

      await tester.pump(LocationHelper.limit - const Duration(seconds: 1));
      expect(done, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(done, isTrue);
      expect(result, isNull);
    });

    test('erro do plugin nunca vira exceção', () async {
      geolocator
        ..current = (() => throw StateError('plugin ausente'))
        ..last = null;
      expect(await LocationHelper.currentPositionOrNull(), isNull);
    });
  });

  group('LocationHelper.ensurePermission', () {
    test('só pede quando ainda não foi respondida', () async {
      geolocator.permission = LocationPermission.denied;
      await LocationHelper.ensurePermission();
      expect(geolocator.permissionRequested, isTrue);
    });

    test('não insiste em quem já negou em definitivo', () async {
      geolocator.permission = LocationPermission.deniedForever;
      await LocationHelper.ensurePermission();
      expect(geolocator.permissionRequested, isFalse);
    });
  });
}
