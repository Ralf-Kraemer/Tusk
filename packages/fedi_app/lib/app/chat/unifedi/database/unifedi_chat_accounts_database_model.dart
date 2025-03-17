import 'package:drift/drift.dart';

// todo: add foreign keys
@DataClassName('DbChatAccount')
class DbChatAccounts extends Table {
  // integer ids works better in SQLite
  IntColumn? get id => integer().nullable().autoIncrement()();

  TextColumn? get chatRemoteId => text()();
  TextColumn? get accountRemoteId => text()();
}
