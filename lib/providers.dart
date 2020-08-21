
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/camp.dart';
import 'models/user.dart';
import 'services/auth.dart';
import 'services/db.dart';

final authProvider = ChangeNotifierProvider((_) => AuthProvider());

final userProvider = ScopedProvider<UserModel>((ref) {
  throw UnimplementedError();
});

final firestoreService = ScopedProvider<FirestoreService>((ref) {
  throw UnimplementedError();
});

final campProvider = ScopedProvider<Camp>((ref) {
  throw UnimplementedError();
});

final favoritedProvider = ScopedProvider<bool>((ref) {
  throw UnimplementedError();
});