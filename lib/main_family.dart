import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/config/app_config.dart';
import 'family_web/family_web_app.dart';

/// Ponto de entrada do VIGI Família: painel web (PWA) para o familiar
/// acompanhar, sem invadir a privacidade, quem o autorizou.
///
/// flutter build web -t lib/main_family.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    // ignore: deprecated_member_use -- compatibilidade com supabase_flutter v2
    anonKey: AppConfig.supabasePublishableKey,
  );
  runApp(FamilyWebApp(client: Supabase.instance.client));
}
