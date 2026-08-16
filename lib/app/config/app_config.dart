abstract class AppConfig {
  static const String appName = 'Guardião';
  static const String appVersion = '2.0.0';

  // Configurações do Supabase (Ajuste com suas credenciais do projeto)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://pdtrgorwgxqsbhyzddsy.supabase.co',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'YOUR_SUPABASE_PUBLISHABLE_KEY',
  );

  // Padrões do Dead Man's Switch (Check-in)
  static const Duration defaultCheckInInterval = Duration(hours: 12);
  static const Duration defaultGracePeriod = Duration(minutes: 15);
}
