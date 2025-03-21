import 'package:fedi_app/app/database/app_database.dart';
import 'package:fedi_app/app/database/dao/database_dao.dart';
import 'package:fedi_app/app/status/database/home_timeline_statuses_database_model.dart';
import 'package:drift/drift.dart';

part 'home_timeline_statuses_database_dao.g.dart';

@DriftAccessor(
  tables: [
    DbHomeTimelineStatuses,
  ],
)
class HomeTimelineStatusesDao extends DatabaseDao<
    DbHomeTimelineStatus,
    int,
    $DbHomeTimelineStatusesTable,
    $DbHomeTimelineStatusesTable> with _$HomeTimelineStatusesDaoMixin {
  final AppDatabase db;

// Called by the AppDatabase class
  HomeTimelineStatusesDao(this.db) : super(db);

  @override
  $DbHomeTimelineStatusesTable get table => dbHomeTimelineStatuses;

  Future<int> deleteByAccountRemoteId(String accountRemoteId) => customUpdate(
        'DELETE FROM $tableName '
        'WHERE ${_createAccountRemoteIdEqualExpression(accountRemoteId)}',
        updates: {table},
        updateKind: UpdateKind.delete,
      );

  Future<void> deleteByAccountRemoteIdBatch(
    String accountRemoteId, {
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      batchTransaction.deleteWhere(
        table,
        (tbl) => _createAccountRemoteIdEqualExpression(accountRemoteId),
      );
    } else {
      // ignore: avoid-ignoring-return-values
      await deleteByAccountRemoteId(accountRemoteId);
    }
  }

  CustomExpression<bool> _createAccountRemoteIdEqualExpression(
    String accountRemoteId,
  ) =>
      createMainTableEqualWhereExpression(
        fieldName: table.accountRemoteId.$name,
        value: accountRemoteId,
      );
}
