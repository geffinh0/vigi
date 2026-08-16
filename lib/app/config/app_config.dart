abstract class AppConfig {
  static const String appName = 'Guardião';
  static const String appVersion = '2.0.0';

  // Configurações do Supabase (Ajuste com suas credenciais do projeto)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fojhaubpaglqbpubnpgo.supabase.co',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZvamhhdWJwYWdscWJwdWJucGdvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY4NDI1NzMsImV4cCI6MjEwMjQxODU3M30.7RSrUOgJHmxTd5AnU8mDgkmTOPu2aLzDtI8ikSMZ0nA',
  );

  // Padrões do Dead Man's Switch (Check-in)
  static const Duration defaultCheckInInterval = Duration(hours: 12);
  static const Duration defaultGracePeriod = Duration(minutes: 15);
}
