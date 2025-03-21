import 'package:fedi_app/app/moor/moor_converters.dart';
import 'package:drift/drift.dart';

@DataClassName('DbInstanceAnnouncement')
class DbInstanceAnnouncements extends Table {
  // integer ids works much better in SQLite
  IntColumn? get id => integer().nullable().autoIncrement()();

  TextColumn? get remoteId => text().customConstraint('UNIQUE NOT NULL')();

  BoolColumn get allDay => boolean()();

  DateTimeColumn? get publishedAt => dateTime()();

  DateTimeColumn? get updatedAt => dateTime()();

  BoolColumn get read => boolean()();

  TextColumn get content => text()();

  TextColumn? get reactions => text()
      .map(const UnifediApiEmojiReactionListDatabaseConverter())
      .nullable()();

  TextColumn? get mentions =>
      text().map(const UnifediApiMentionListDatabaseConverter()).nullable()();

  TextColumn? get tags =>
      text().map(const UnifediApiTagListDatabaseConverter()).nullable()();

  TextColumn? get statuses =>
      text().map(const UnifediApiStatusListDatabaseConverter()).nullable()();

  DateTimeColumn? get scheduledAt => dateTime().nullable()();

  DateTimeColumn? get startsAt => dateTime().nullable()();

  DateTimeColumn? get endsAt => dateTime().nullable()();
}
