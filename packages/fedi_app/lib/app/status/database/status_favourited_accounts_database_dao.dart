import 'package:fedi_app/app/database/app_database.dart';
import 'package:fedi_app/app/database/dao/database_dao.dart';
import 'package:fedi_app/app/status/database'
    '/status_favourited_accounts_database_model.dart';
import 'package:drift/drift.dart';

part 'status_favourited_accounts_database_dao.g.dart';

@DriftAccessor(
  tables: [
    DbStatusFavouritedAccounts,
  ],
)
class StatusFavouritedAccountsDao extends DatabaseDao<
    DbStatusFavouritedAccount,
    int,
    $DbStatusFavouritedAccountsTable,
    $DbStatusFavouritedAccountsTable> with _$StatusFavouritedAccountsDaoMixin {
  final AppDatabase db;

  // Called by the AppDatabase class
  StatusFavouritedAccountsDao(this.db) : super(db);

  @override
  $DbStatusFavouritedAccountsTable get table => dbStatusFavouritedAccounts;

  Future<int> deleteByStatusRemoteId(String statusRemoteId) => customUpdate(
        'DELETE FROM $tableName '
        'WHERE ${_createStatusRemoteIdEqualExpression(statusRemoteId).content}',
        updates: {table},
        updateKind: UpdateKind.delete,
      );

  Future<void> deleteByStatusRemoteIdBatch(
    String statusRemoteId, {
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      batchTransaction.deleteWhere(
        table,
        (tbl) => _createStatusRemoteIdEqualExpression(statusRemoteId),
      );
    } else {
      // ignore: avoid-ignoring-return-values
      await deleteByStatusRemoteId(statusRemoteId);
    }
  }

  CustomExpression<bool> _createStatusRemoteIdEqualExpression(
    String statusRemoteId,
  ) =>
      createMainTableEqualWhereExpression(
        fieldName: table.statusRemoteId.$name,
        value: statusRemoteId,
      );
}
