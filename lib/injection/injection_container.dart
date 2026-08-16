import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/network/network_info.dart';
import '../core/network/sync_queue.dart';
import '../core/services/alarm_service.dart';
import '../core/services/notification_service.dart';
import '../core/utils/clock.dart';
import '../core/utils/ticker.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/sign_in_usecase.dart';
import '../features/auth/domain/usecases/sign_out_usecase.dart';
import '../features/auth/domain/usecases/sign_up_usecase.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/checkin/data/datasources/checkin_remote_datasource.dart';
import '../features/checkin/data/repositories/checkin_repository_impl.dart';
import '../features/checkin/domain/repositories/checkin_repository.dart';
import '../features/checkin/domain/usecases/confirm_checkin_usecase.dart';
import '../features/checkin/domain/usecases/create_custom_mode_usecase.dart';
import '../features/checkin/domain/usecases/get_available_modes_usecase.dart';
import '../features/checkin/domain/usecases/get_monitoring_status_usecase.dart';
import '../features/checkin/domain/usecases/save_monitoring_settings_usecase.dart';
import '../features/checkin/domain/usecases/start_monitoring_usecase.dart';
import '../features/checkin/domain/usecases/stop_monitoring_usecase.dart';
import '../features/checkin/presentation/bloc/checkin_bloc.dart';
import '../features/contacts/data/datasources/contacts_remote_datasource.dart';
import '../features/contacts/data/repositories/contacts_repository_impl.dart';
import '../features/contacts/domain/repositories/contacts_repository.dart';
import '../features/contacts/domain/usecases/add_contact_usecase.dart';
import '../features/contacts/domain/usecases/delete_contact_usecase.dart';
import '../features/contacts/domain/usecases/get_contacts_usecase.dart';
import '../features/contacts/presentation/bloc/contacts_bloc.dart';
import '../features/family/data/datasources/family_remote_datasource.dart';
import '../features/family/data/repositories/family_repository_impl.dart';
import '../features/family/domain/repositories/family_repository.dart';
import '../features/family/domain/usecases/accept_family_invite_usecase.dart';
import '../features/family/domain/usecases/get_family_links_usecase.dart';
import '../features/family/domain/usecases/send_family_invite_usecase.dart';
import '../features/family/presentation/bloc/family_bloc.dart';
import '../features/panic/data/datasources/panic_remote_datasource.dart';
import '../features/panic/data/repositories/panic_repository_impl.dart';
import '../features/panic/domain/repositories/panic_repository.dart';
import '../features/panic/domain/usecases/resolve_panic_usecase.dart';
import '../features/panic/domain/usecases/trigger_panic_usecase.dart';
import '../features/panic/presentation/bloc/panic_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // ── External ───────────────────────────────────────────────────
  if (!sl.isRegistered<SharedPreferences>()) {
    final prefs = await SharedPreferences.getInstance();
    sl.registerLazySingleton<SharedPreferences>(() => prefs);
  }
  if (!sl.isRegistered<Connectivity>()) {
    sl.registerLazySingleton<Connectivity>(Connectivity.new);
  }
  if (!sl.isRegistered<NetworkInfo>()) {
    sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  }

  // ── Core & Services ───────────────────────────────────────────
  if (!sl.isRegistered<Clock>()) {
    sl.registerLazySingleton<Clock>(SystemClock.new);
  }
  if (!sl.isRegistered<Ticker>()) {
    sl.registerLazySingleton<Ticker>(Ticker.new);
  }
  if (!sl.isRegistered<AlarmService>()) {
    sl.registerLazySingleton<AlarmService>(AlarmServiceImpl.new);
  }
  if (!sl.isRegistered<NotificationService>()) {
    sl.registerLazySingleton<NotificationService>(NotificationService.new);
  }

  // ── Supabase Client (se inicializado) ──────────────────────────
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {
    // Ignorado em ambientes de teste
  }

  if (client != null && !sl.isRegistered<SupabaseClient>()) {
    sl
      ..registerLazySingleton<SupabaseClient>(() => client!)
      ..registerLazySingleton<SyncQueue>(
        () => SyncQueue(
          prefs: sl(),
          networkInfo: sl(),
          supabaseClient: sl(),
        ),
      );
  }

  // ── Auth Feature ───────────────────────────────────────────────
  if (client != null) {
    sl
      ..registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(sl()),
      )
      ..registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(sl()),
      );
  }
  sl
    ..registerLazySingleton(() => SignInUseCase(sl()))
    ..registerLazySingleton(() => SignUpUseCase(sl()))
    ..registerLazySingleton(() => SignOutUseCase(sl()))
    ..registerFactory(
      () => AuthBloc(
        signInUseCase: sl(),
        signUpUseCase: sl(),
        signOutUseCase: sl(),
        authRepository: sl(),
      ),
    );

  // ── Contacts Feature ───────────────────────────────────────────
  if (client != null) {
    sl
      ..registerLazySingleton<ContactsRemoteDataSource>(
        () => ContactsRemoteDataSourceImpl(sl()),
      )
      ..registerLazySingleton<ContactsRepository>(
        () => ContactsRepositoryImpl(sl()),
      );
  }
  sl
    ..registerLazySingleton(() => GetContactsUseCase(sl()))
    ..registerLazySingleton(() => AddContactUseCase(sl()))
    ..registerLazySingleton(() => DeleteContactUseCase(sl()))
    ..registerFactory(
      () => ContactsBloc(
        getContactsUseCase: sl(),
        addContactUseCase: sl(),
        deleteContactUseCase: sl(),
      ),
    );

  // ── Checkin Feature ────────────────────────────────────────────
  if (client != null) {
    sl
      ..registerLazySingleton<CheckinRemoteDataSource>(
        () => CheckinRemoteDataSourceImpl(sl()),
      )
      ..registerLazySingleton<CheckinRepository>(
        () => CheckinRepositoryImpl(
          remoteDataSource: sl(),
          clock: sl(),
        ),
      );
  }
  sl
    ..registerLazySingleton(() => GetAvailableModesUseCase(sl()))
    ..registerLazySingleton(() => CreateCustomModeUseCase(sl()))
    ..registerLazySingleton(() => SaveMonitoringSettingsUseCase(sl()))
    ..registerLazySingleton(() => StartMonitoringUseCase(sl(), sl()))
    ..registerLazySingleton(() => ConfirmCheckinUseCase(sl()))
    ..registerLazySingleton(() => StopMonitoringUseCase(sl()))
    ..registerLazySingleton(() => GetMonitoringStatusUseCase(sl()))
    ..registerFactory(
      () => CheckinBloc(
        startMonitoringUseCase: sl(),
        confirmCheckinUseCase: sl(),
        stopMonitoringUseCase: sl(),
        getMonitoringStatusUseCase: sl(),
        getAvailableModesUseCase: sl(),
        createCustomModeUseCase: sl(),
        saveMonitoringSettingsUseCase: sl(),
        ticker: sl(),
        clock: sl(),
        alarmService: sl(),
        notificationService: sl(),
      ),
    );

  // ── Panic Feature ──────────────────────────────────────────────
  if (client != null) {
    sl
      ..registerLazySingleton<PanicRemoteDataSource>(
        () => PanicRemoteDataSourceImpl(sl()),
      )
      ..registerLazySingleton<PanicRepository>(
        () => PanicRepositoryImpl(sl()),
      );
  }
  sl
    ..registerLazySingleton(() => TriggerPanicUseCase(sl()))
    ..registerLazySingleton(() => ResolvePanicUseCase(sl()))
    ..registerFactory(
      () => PanicBloc(
        triggerPanicUseCase: sl(),
        resolvePanicUseCase: sl(),
      ),
    );

  // ── Family Feature ─────────────────────────────────────────────
  if (client != null) {
    sl
      ..registerLazySingleton<FamilyRemoteDataSource>(
        () => FamilyRemoteDataSourceImpl(sl()),
      )
      ..registerLazySingleton<FamilyRepository>(
        () => FamilyRepositoryImpl(sl()),
      );
  }
  sl
    ..registerLazySingleton(() => GetFamilyLinksUseCase(sl()))
    ..registerLazySingleton(() => SendFamilyInviteUseCase(sl()))
    ..registerLazySingleton(() => AcceptFamilyInviteUseCase(sl()))
    ..registerFactory(
      () => FamilyBloc(
        getFamilyLinksUseCase: sl(),
        sendFamilyInviteUseCase: sl(),
        acceptFamilyInviteUseCase: sl(),
      ),
    );
}
