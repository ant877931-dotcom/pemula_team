import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseClient get client => Supabase.instance.client;
}
