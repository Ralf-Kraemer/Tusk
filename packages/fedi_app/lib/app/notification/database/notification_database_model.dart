import 'package:fedi_app/app/moor/moor_converters.dart';
import 'package:drift/drift.dart';

// todo: add foreign keys
@DataClassName('DbNotification')
class DbNotifications extends Table {
  // integer ids works much better in SQLite
  IntColumn get id => integer().nullable().autoIncrement()();

  TextColumn get remoteId => text().customConstraint('UNIQUE NOT NULL')();

  TextColumn get accountRemoteId => text().nullable()();

  TextColumn get statusRemoteId => text().nullable()();

  TextColumn get chatRemoteId => text().nullable()();

  TextColumn get chatMessageRemoteId => text().nullable()();

  TextColumn get emoji => text().nullable()();

  TextColumn get report =>
      text().nullable().map(const UnifediApiAccountReportDatabaseConverter())();

  TextColumn get chatMessage =>
      text().nullable().map(const UnifediApiChatMessageDatabaseConverter())();

  TextColumn get target =>
      text().nullable().map(const UnifediApiAccountDatabaseConverter())();

  BoolColumn get unread => boolean().nullable()();

  TextColumn get type => text()();

  DateTimeColumn get createdAt => dateTime()();

  BoolColumn get dismissed => boolean().nullable()();
}
