import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected bottom navigation index in [HomeShell].
final homeShellTabProvider = StateProvider<int>((ref) => 0);

/// Products tab index in staff and member layouts.
const kHomeShellProductsTabIndex = 0;

/// Cart tab index when the user is logged in (staff and member layouts).
const kHomeShellCartTabIndex = 2;
