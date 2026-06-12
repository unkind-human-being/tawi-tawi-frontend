import 'package:isar/isar.dart';

part 'user_model.g.dart';

@collection
class UserModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String email;

  late String name;
  late String role;

  // --- FIXED: Changed from 'late String' to nullable 'String?' to prevent uninitialized crashes ---
  String? password;

  String? shopName;
  String? shopAddress;

  late bool isSynced;
}
