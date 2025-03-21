import 'package:fedi_app/app/database/app_database.dart';
import 'package:fedi_app/app/database/dao/populated_database_dao_mixin.dart';
import 'package:fedi_app/app/database/dao/repository/remote/populated_app_remote_database_dao_repository.dart';
import 'package:fedi_app/app/instance/announcement/database/instance_announcement_database_dao.dart';
import 'package:fedi_app/app/instance/announcement/instance_announcement_model.dart';
import 'package:fedi_app/app/instance/announcement/instance_announcement_model_adapter.dart';
import 'package:fedi_app/app/instance/announcement/repository/instance_announcement_repository.dart';
import 'package:fedi_app/app/instance/announcement/repository/instance_announcement_repository_model.dart';
import 'package:drift/drift.dart';
import 'package:unifedi_api/unifedi_api.dart';

class InstanceAnnouncementRepository
    extends PopulatedAppRemoteDatabaseDaoRepository<
        DbInstanceAnnouncement,
        DbInstanceAnnouncementPopulated,
        IInstanceAnnouncement,
        IUnifediApiAnnouncement,
        int,
        String,
        $DbInstanceAnnouncementsTable,
        $DbInstanceAnnouncementsTable,
        InstanceAnnouncementRepositoryFilters,
        InstanceAnnouncementOrderingTermData>
    implements IInstanceAnnouncementRepository {
  @override
  final InstanceAnnouncementDao dao;

  @override
  PopulatedDatabaseDaoMixin<
      DbInstanceAnnouncement,
      DbInstanceAnnouncementPopulated,
      int,
      $DbInstanceAnnouncementsTable,
      $DbInstanceAnnouncementsTable,
      InstanceAnnouncementRepositoryFilters,
      InstanceAnnouncementOrderingTermData> get populatedDao => dao;

  InstanceAnnouncementRepository({
    required AppDatabase appDatabase,
  }) : dao = appDatabase.instanceAnnouncementDao;

  @override
  DbInstanceAnnouncement mapAppItemToDbItem(IInstanceAnnouncement appItem) =>
      appItem.toDbInstanceAnnouncement();

  @override
  IUnifediApiAnnouncement mapAppItemToRemoteItem(
    IInstanceAnnouncement appItem,
  ) =>
      appItem.toUnifediInstanceAnnouncement();

  @override
  DbInstanceAnnouncementPopulated mapAppItemToDbPopulatedItem(
    IInstanceAnnouncement appItem,
  ) =>
      appItem.toDbInstanceAnnouncementPopulated();

  @override
  IInstanceAnnouncement mapDbPopulatedItemToAppItem(
    DbInstanceAnnouncementPopulated dbPopulatedItem,
  ) =>
      dbPopulatedItem.toDbInstanceAnnouncementPopulatedWrapper();

  @override
  IUnifediApiAnnouncement mapDbPopulatedItemToRemoteItem(
    DbInstanceAnnouncementPopulated dbPopulatedItem,
  ) =>
      dbPopulatedItem
          .toDbInstanceAnnouncementPopulatedWrapper()
          .toUnifediInstanceAnnouncement();

  @override
  IInstanceAnnouncement mapRemoteItemToAppItem(
    IUnifediApiAnnouncement remoteItem,
  ) =>
      remoteItem.toDbInstanceAnnouncementPopulatedWrapper();

  @override
  InstanceAnnouncementRepositoryFilters get emptyFilters =>
      InstanceAnnouncementRepositoryFilters.empty;

  @override
  List<InstanceAnnouncementOrderingTermData> get defaultOrderingTerms =>
      InstanceAnnouncementOrderingTermData.defaultTerms;

  @override
  Future<void> insertInDbTypeBatch(
    Insertable<DbInstanceAnnouncement> dbItem, {
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
    IUnifediApiAnnouncement remoteItem, {
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
    IUnifediApiAnnouncement remoteItem, {
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
    required IInstanceAnnouncement appItem,
    required IUnifediApiAnnouncement remoteItem,
    required Batch? batchTransaction,
  }) =>
      updateByDbIdInDbType(
        dbId: appItem.localId!,
        dbItem: remoteItem.toDbInstanceAnnouncement(),
        batchTransaction: batchTransaction,
      );

  @override
  Future<void> updateByDbIdInDbType({
    required int dbId,
    required DbInstanceAnnouncement dbItem,
    required Batch? batchTransaction,
  }) =>
      dao.upsertBatch(
        entity: dbItem.copyWith(id: dbId),
        batchTransaction: batchTransaction,
      );

  @override
  Future<int> calculateCount({
    required InstanceAnnouncementRepositoryFilters? filters,
  }) async {
    // todo: rework with COUNT * only
    var query = dao.startSelectQuery();
    dao.addFiltersToQuery(query: query, filters: filters);

    // required because some filters added during join
    var joinedQuery =
        populatedDao.convertSimpleSelectStatementToJoinedSelectStatement(
      query: query,
      filters: filters,
    );

    var items = await joinedQuery.get();

    return items.length;
  }

  @override
  Stream<int> watchCalculateCount({
    required InstanceAnnouncementRepositoryFilters? filters,
  }) {
    // todo: rework with COUNT * only
    var query = dao.startSelectQuery();
    dao.addFiltersToQuery(query: query, filters: filters);

    // required because some filters added during join
    var joinedQuery =
        populatedDao.convertSimpleSelectStatementToJoinedSelectStatement(
      query: query,
      filters: filters,
    );

    var stream = joinedQuery.watch();

    return stream.map((items) => items.length);
  }
}

extension DbInstanceAnnouncementPopulatedListExtension
    on List<DbInstanceAnnouncementPopulated> {
  List<DbInstanceAnnouncementPopulatedWrapper>
      toDbInstanceAnnouncementPopulatedWrapperList() => map(
            (value) => value.toDbInstanceAnnouncementPopulatedWrapper(),
          ).toList();
}

extension DbInstanceAnnouncementPopulatedExtension
    on DbInstanceAnnouncementPopulated {
  DbInstanceAnnouncementPopulatedWrapper
      toDbInstanceAnnouncementPopulatedWrapper() =>
          DbInstanceAnnouncementPopulatedWrapper(
            dbInstanceAnnouncementPopulated: this,
          );
}

extension DbInstanceAnnouncementPopulatedWrapperExtension
    on DbInstanceAnnouncementPopulatedWrapper {
  DbInstanceAnnouncement toDbInstanceAnnouncement() =>
      dbInstanceAnnouncementPopulated.dbInstanceAnnouncement;
}
