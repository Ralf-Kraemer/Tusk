import 'package:fedi_app/app/database/app_database.dart';
import 'package:fedi_app/app/database/dao/populated_database_dao_mixin.dart';
import 'package:fedi_app/app/database/dao/repository/remote/populated_app_remote_database_dao_repository.dart';
import 'package:fedi_app/app/status/scheduled/database/scheduled_status_database_dao.dart';
import 'package:fedi_app/app/status/scheduled/repository/scheduled_status_repository.dart';
import 'package:fedi_app/app/status/scheduled/repository/scheduled_status_repository_model.dart';
import 'package:fedi_app/app/status/scheduled/scheduled_status_model.dart';
import 'package:fedi_app/app/status/scheduled/scheduled_status_model_adapter.dart';
import 'package:drift/drift.dart';
import 'package:unifedi_api/unifedi_api.dart';

class ScheduledStatusRepository extends PopulatedAppRemoteDatabaseDaoRepository<
        DbScheduledStatus,
        DbScheduledStatusPopulated,
        IScheduledStatus,
        IUnifediApiScheduledStatus,
        int,
        String,
        $DbScheduledStatusesTable,
        $DbScheduledStatusesTable,
        ScheduledStatusRepositoryFilters,
        ScheduledStatusRepositoryOrderingTermData>
    implements IScheduledStatusRepository {
  @override
  final ScheduledStatusDao dao;

  @override
  PopulatedDatabaseDaoMixin<
      DbScheduledStatus,
      DbScheduledStatusPopulated,
      int,
      $DbScheduledStatusesTable,
      $DbScheduledStatusesTable,
      ScheduledStatusRepositoryFilters,
      ScheduledStatusRepositoryOrderingTermData> get populatedDao => dao;

  ScheduledStatusRepository({required AppDatabase appDatabase})
      : dao = appDatabase.scheduledStatusDao;

  @override
  Future<void> markAsCanceled({
    required IScheduledStatus scheduledStatus,
    required Batch? batchTransaction,
  }) async {
    await updateByDbIdInDbType(
      dbId: scheduledStatus.localId!,
      dbItem: DbScheduledStatus(
        canceled: true,
        params: scheduledStatus.params.toUnifediScheduledStatusParams(),
        mediaAttachments: scheduledStatus.mediaAttachments,
        id: scheduledStatus.localId,
        remoteId: scheduledStatus.remoteId!,
        scheduledAt: scheduledStatus.scheduledAt,
      ),
      batchTransaction: batchTransaction,
    );
  }

  @override
  DbScheduledStatus mapAppItemToDbItem(IScheduledStatus appItem) =>
      appItem.toDbScheduledStatus();

  @override
  IUnifediApiScheduledStatus mapAppItemToRemoteItem(IScheduledStatus appItem) =>
      appItem.toUnifediScheduledStatus();

  @override
  DbScheduledStatusPopulated mapAppItemToDbPopulatedItem(
    IScheduledStatus appItem,
  ) =>
      appItem.toDbScheduledStatusPopulated();

  @override
  IScheduledStatus mapDbPopulatedItemToAppItem(
    DbScheduledStatusPopulated dbPopulatedItem,
  ) =>
      dbPopulatedItem.toDbScheduledStatusPopulatedWrapper();

  @override
  IUnifediApiScheduledStatus mapDbPopulatedItemToRemoteItem(
    DbScheduledStatusPopulated dbPopulatedItem,
  ) =>
      dbPopulatedItem
          .toDbScheduledStatusPopulatedWrapper()
          .toUnifediScheduledStatus();

  @override
  ScheduledStatusRepositoryFilters get emptyFilters =>
      ScheduledStatusRepositoryFilters.empty;

  @override
  List<ScheduledStatusRepositoryOrderingTermData> get defaultOrderingTerms =>
      ScheduledStatusRepositoryOrderingTermData.defaultTerms;

  @override
  IScheduledStatus mapRemoteItemToAppItem(
    IUnifediApiScheduledStatus remoteItem,
  ) =>
      DbScheduledStatusPopulated(
        dbScheduledStatus: remoteItem.toDbScheduledStatus(
          canceled: false,
        ),
      ).toDbScheduledStatusPopulatedWrapper();

  @override
  Future<void> insertInDbTypeBatch(
    Insertable<DbScheduledStatus> dbItem, {
    required InsertMode? mode,
    required Batch? batchTransaction,
  }) =>
      dao.insertBatch(
        entity: dbItem,
        mode: mode,
        batchTransaction: batchTransaction,
      );

  @override
  Future<int> insertInRemoteType(
    IUnifediApiScheduledStatus remoteItem, {
    required InsertMode? mode,
  }) =>
      insertInDbType(
        mapRemoteItemToDbItem(
          remoteItem,
        ),
        mode: mode,
      );

  @override
  Future<void> insertInRemoteTypeBatch(
    IUnifediApiScheduledStatus remoteItem, {
    required InsertMode? mode,
    required Batch? batchTransaction,
  }) =>
      upsertInDbTypeBatch(
        mapRemoteItemToDbItem(
          remoteItem,
        ),
        batchTransaction: batchTransaction,
      );

  @override
  Future<void> updateAppTypeByRemoteType({
    required IScheduledStatus appItem,
    required IUnifediApiScheduledStatus remoteItem,
    required Batch? batchTransaction,
  }) =>
      updateByDbIdInDbType(
        dbId: appItem.localId!,
        dbItem: remoteItem.toDbScheduledStatus(canceled: false),
        batchTransaction: batchTransaction,
      );

  @override
  Future<void> updateByDbIdInDbType({
    required int dbId,
    required DbScheduledStatus dbItem,
    required Batch? batchTransaction,
  }) =>
      dao.upsertBatch(
        entity: dbItem.copyWith(id: dbId),
        batchTransaction: batchTransaction,
      );
}
