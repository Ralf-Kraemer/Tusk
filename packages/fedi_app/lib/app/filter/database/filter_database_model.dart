import 'package:fedi_app/drift/drift_json_type_converter.dart';
import 'package:drift/drift.dart';

@DataClassName('DbFilter')
class DbFilters extends Table {
  // integer ids works much better in SQLite
  IntColumn? get id => integer().nullable().autoIncrement()();

  TextColumn? get remoteId => text().customConstraint('UNIQUE NOT NULL')();

  TextColumn? get phrase => text()();

  TextColumn? get context => text().map(const StringListDatabaseConverter())();

  BoolColumn? get irreversible => boolean()();

  BoolColumn? get wholeWord => boolean()();

  DateTimeColumn? get expiresAt => dateTime().nullable()();
}
