import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Set when the API rejects both the access token and its refresh token.
final sessionExpiredProvider = StateProvider<bool>((ref) => false);
