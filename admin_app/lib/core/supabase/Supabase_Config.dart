import 'package:Supabase_flutter/Supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static SupabaseClient get client {
    return Supabase.instance.client;
  }

  static User? get currentUser {
    return client.auth.currentUser;
  }

  static String? get currentUserId {
    return currentUser?.id;
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }
  } 
