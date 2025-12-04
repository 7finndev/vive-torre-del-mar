import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:torre_del_mar_app/features/scan/data/repositories/sync_service.dart';
import 'package:torre_del_mar_app/features/home/presentation/providers/home_providers.dart';

part 'sync_provider.g.dart';

@riverpod
SyncService syncService(SyncServiceRef ref) {
  return SyncService(
    Supabase.instance.client,
    ref.watch(localDbProvider),
  );
}