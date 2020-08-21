
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/user.dart';
import 'services/auth.dart';
import 'services/db.dart';

final authProvider = ChangeNotifierProvider((_) => AuthProvider());

final userModel = ScopedProvider<UserModel>((ref) {
  throw UnimplementedError();
});

final firestoreService = ScopedProvider<FirestoreService>((ref) {
  throw UnimplementedError();
});
