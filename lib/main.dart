import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/constants/env.dart';
import 'core/router/url_strategy_stub.dart'
    if (dart.library.html) 'core/router/url_strategy_web.dart' as url_strategy;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use hash URL strategy on web so Chrome doesn't 404 on refresh or direct links
  url_strategy.useHashUrlStrategy();
  
  // Validate environment configuration
  if (!Env.validate()) {
    throw Exception('Missing required environment variables. Please check your configuration.');
  }
  
  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  } catch (e) {
    throw Exception('Failed to initialize Supabase: $e');
  }

  runApp(const ProviderScope(child: AuraApp()));
}
