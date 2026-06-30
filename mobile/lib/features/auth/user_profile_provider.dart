import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/json_field.dart';
import 'auth_provider.dart';

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final auth = ref.watch(authStateProvider);
  if (auth.isLoading) return null;
  if (auth.valueOrNull != true) return null;

  final client = ref.watch(spClientProvider);
  final response = await client.exec('Auth.GetProfile', {});
  if (!response.success) return null;
  final rows = parseRowList(response.data);
  return rows.isEmpty ? null : rows.first;
});

final isStaffProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.maybeWhen(
    data: (p) => p?.stringField('Role') == 'Staff',
    orElse: () => false,
  );
});
