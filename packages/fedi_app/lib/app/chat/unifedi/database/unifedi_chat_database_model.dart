import 'package:drift/drift.dart';

// todo: add foreign keys
@DataClassName('DbChat')
class DbChats extends Table {
  // integer ids works better in SQLite
  IntColumn? get id => integer().nullable().autoIncrement()();

  TextColumn? get remoteId => text().customConstraint('UNIQUE NOT NULL')();
  IntColumn? get unread => integer()();
  DateTimeColumn? get updatedAt => dateTime().nullable()();
  TextColumn? get accountRemoteId => text()();
}
