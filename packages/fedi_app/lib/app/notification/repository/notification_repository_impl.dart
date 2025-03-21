import 'package:fedi_app/app/account/account_model.dart';
import 'package:fedi_app/app/account/repository/account_repository.dart';
import 'package:fedi_app/app/chat/unifedi/message/repository/unifedi_chat_message_repository.dart';
import 'package:fedi_app/app/database/app_database.dart';
import 'package:fedi_app/app/database/dao/populated_database_dao_mixin.dart';
import 'package:fedi_app/app/database/dao/repository/remote/populated_app_remote_database_dao_repository.dart';
import 'package:fedi_app/app/notification/database/notification_database_dao.dart';
import 'package:fedi_app/app/notification/notification_model.dart';
import 'package:fedi_app/app/notification/notification_model_adapter.dart';
import 'package:fedi_app/app/notification/repository/notification_repository.dart';
import 'package:fedi_app/app/notification/repository/notification_repository_model.dart';
import 'package:fedi_app/app/status/repository/status_repository.dart';
import 'package:drift/drift.dart';
import 'package:unifedi_api/unifedi_api.dart';

class NotificationRepository extends PopulatedAppRemoteDatabaseDaoRepository<
    DbNotification,
    DbNotificationPopulated,
    INotification,
    IUnifediApiNotification,
    int,
    String,
    $DbNotificationsTable,
    $DbNotificationsTable,
    NotificationRepositoryFilters,
    NotificationRepositoryOrderingTermData> implements INotificationRepository {
  @override
  final NotificationDao dao;
  final IAccountRepository accountRepository;
  final IStatusRepository statusRepository;
  final IUnifediChatMessageRepository chatMessageRepository;

  @override
  PopulatedDatabaseDaoMixin<
      DbNotification,
      DbNotificationPopulated,
      int,
      $DbNotificationsTable,
      $DbNotificationsTable,
      NotificationRepositoryFilters,
      NotificationRepositoryOrderingTermData> get populatedDao => dao;

  NotificationRepository({
    required AppDatabase appDatabase,
    required this.accountRepository,
    required this.statusRepository,
    required this.chatMessageRepository,
  }) : dao = appDatabase.notificationDao;

  @override
  Future<void> markAsRead({
    required INotification notification,
  }) =>
      dao.markAsRead(
        remoteId: notification.remoteId,
      );

  @override
  Future<void> dismiss({
    required INotification notification,
  }) =>
      dao.markAsDismissed(
        remoteId: notification.remoteId,
      );

  @override
  Future<void> dismissAll() => dao.markAllAsDismissed();

  @override
  Future<void> markAllAsRead() => dao.markAllAsRead();

  @override
  Future<void> dismissFollowRequestNotificationsFromAccount({
    required IAccount account,
    required Batch? batchTransaction,
  }) =>
      dao.markAsDismissedWhere(
        accountRemoteId: account.remoteId,
        type: UnifediApiNotificationType.followRequestValue,
      );

  @override
  DbNotification mapAppItemToDbItem(INotification appItem) =>
      appItem.toDbNotification();

  @override
  IUnifediApiNotification mapAppItemToRemoteItem(INotification appItem) =>
      appItem.toUnifediApiNotification();

  @override
  DbNotificationPopulated mapAppItemToDbPopulatedItem(INotification appItem) =>
      appItem.toDbNotificationPopulated();

  @override
  INotification mapDbPopulatedItemToAppItem(
    DbNotificationPopulated dbPopulatedItem,
  ) =>
      dbPopulatedItem.toDbNotificationPopulatedWrapper();

  @override
  IUnifediApiNotification mapDbPopulatedItemToRemoteItem(
    DbNotificationPopulated dbPopulatedItem,
  ) =>
      dbPopulatedItem
          .toDbNotificationPopulatedWrapper()
          .toUnifediApiNotification();

  @override
  INotification mapRemoteItemToAppItem(IUnifediApiNotification remoteItem) =>
      remoteItem.toDbNotificationPopulatedWrapper(unread: null);

  @override
  NotificationRepositoryFilters get emptyFilters =>
      NotificationRepositoryFilters.empty;

  @override
  List<NotificationRepositoryOrderingTermData> get defaultOrderingTerms =>
      NotificationRepositoryOrderingTermData.defaultTerms;

  @override
  Future<INotification?> getNewestOrderByRemoteId() => dao
      .getNewestPopulatedOrderByRemoteId(offset: null)
      .then(mapDbPopulatedItemToAppItemNullable);

  @override
  Future<INotification?> getOldestOrderByRemoteId() => dao
      .getOldestPopulatedOrderByRemoteId(offset: null)
      .then(mapDbPopulatedItemToAppItemNullable);

  @override
  Future<void> insertInDbTypeBatch(
    Insertable<DbNotification> dbItem, {
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
    IUnifediApiNotification remoteItem, {
    required InsertMode? mode,
  }) async {
    await _upsertNotificationMetadata(
      remoteItem,
      batchTransaction: null,
    );

    return dao.upsert(
      entity: remoteItem.toDbNotification(unread: null),
    );
  }

  Future<void> _upsertNotificationMetadata(
    IUnifediApiNotification remoteItem, {
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      var remoteStatus = remoteItem.status;
      if (remoteStatus != null) {
        // ignore: unawaited_futures
        statusRepository.upsertInRemoteTypeBatch(
          remoteStatus,
          batchTransaction: batchTransaction,
        );
      }

      var remoteAccount = remoteItem.account;

      // account may be already added during status update
      if (remoteAccount != null) {
        // ignore: unawaited_futures
        accountRepository.upsertInRemoteTypeBatch(
          remoteAccount,
          batchTransaction: batchTransaction,
        );
      }
      var targetRemoteAccount = remoteItem.target;

      if (targetRemoteAccount != null) {
        // ignore: unawaited_futures
        accountRepository.upsertInRemoteTypeBatch(
          targetRemoteAccount,
          batchTransaction: batchTransaction,
        );
      }

      var remoteChatMessage = remoteItem.chatMessage;
      if (remoteChatMessage != null) {
        // ignore: unawaited_futures
        chatMessageRepository.upsertInRemoteTypeBatch(
          remoteChatMessage,
          batchTransaction: batchTransaction,
        );
      }
    } else {
      await batch(
        (batch) {
          _upsertNotificationMetadata(
            remoteItem,
            batchTransaction: batch,
          );
        },
      );
    }
  }

  @override
  Future<void> insertInRemoteTypeBatch(
    IUnifediApiNotification remoteItem, {
    required InsertMode? mode,
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      // todo: support mode
      // ignore: unawaited_futures
      _upsertNotificationMetadata(
        remoteItem,
        batchTransaction: batchTransaction,
      );

      // ignore: unawaited_futures
      dao.upsertBatch(
        entity: remoteItem.toDbNotification(unread: null),
        batchTransaction: batchTransaction,
      );
    } else {
      await batch((batch) {
        insertInRemoteTypeBatch(
          remoteItem,
          mode: mode,
          batchTransaction: batch,
        );
      });
    }
  }

  @override
  Future<void> updateAppTypeByRemoteType({
    required INotification appItem,
    required IUnifediApiNotification remoteItem,
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      // ignore: unawaited_futures
      _upsertNotificationMetadata(
        remoteItem,
        batchTransaction: batchTransaction,
      );

      if (appItem.localId != null) {
        // ignore: unawaited_futures
        updateByDbIdInDbType(
          dbId: appItem.localId!,
          dbItem: remoteItem.toDbNotification(unread: null),
          batchTransaction: batchTransaction,
        );
      } else {
        // ignore: unawaited_futures
        upsertInRemoteTypeBatch(
          remoteItem,
          batchTransaction: batchTransaction,
        );
      }
    } else {
      await batch((batch) {
        updateAppTypeByRemoteType(
          appItem: appItem,
          remoteItem: remoteItem,
          batchTransaction: batch,
        );
      });
    }
  }

  @override
  Future<void> updateByDbIdInDbType({
    required int dbId,
    required DbNotification dbItem,
    required Batch? batchTransaction,
  }) =>
      dao.upsertBatch(
        entity: dbItem.copyWith(id: dbId),
        batchTransaction: batchTransaction,
      );

  @override
  Future<void> updateNotificationByRemoteType({
    required INotification appItem,
    required IUnifediApiNotification remoteItem,
    required bool? unread,
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      // ignore: unawaited_futures
      _upsertNotificationMetadata(
        remoteItem,
        batchTransaction: batchTransaction,
      );

      if (appItem.localId != null) {
        // ignore: unawaited_futures
        updateByDbIdInDbType(
          dbId: appItem.localId!,
          dbItem: remoteItem.toDbNotification(unread: unread),
          batchTransaction: batchTransaction,
        );
      } else {
        // ignore: unawaited_futures
        upsertInRemoteTypeBatch(
          remoteItem,
          batchTransaction: batchTransaction,
        );
      }
    } else {
      await batch((batch) {
        updateAppTypeByRemoteType(
          appItem: appItem,
          remoteItem: remoteItem,
          batchTransaction: batch,
        );
      });
    }
  }

  @override
  Future<void> upsertRemoteNotification(
    IUnifediApiNotification remoteItem, {
    required bool unread,
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      // todo: support mode
      // ignore: unawaited_futures
      _upsertNotificationMetadata(
        remoteItem,
        batchTransaction: batchTransaction,
      );

      var dbNotification = remoteItem.toDbNotification(unread: unread);
      // ignore: unawaited_futures
      dao.upsertBatch(
        entity: dbNotification,
        batchTransaction: batchTransaction,
      );
    } else {
      await batch(
        (batch) {
          upsertRemoteNotification(
            remoteItem,
            unread: unread,
            batchTransaction: batch,
          );
        },
      );
    }
  }

  @override
  Future<void> upsertRemoteNotifications(
    List<IUnifediApiNotification> unifediNotifications, {
    required bool unread,
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      for (final remoteNotification in unifediNotifications) {
        // ignore: unawaited_futures
        upsertRemoteNotification(
          remoteNotification,
          unread: unread,
          batchTransaction: batchTransaction,
        );
      }
    } else {
      await batch(
        (batch) {
          upsertRemoteNotifications(
            unifediNotifications,
            unread: unread,
            batchTransaction: batch,
          );
        },
      );
    }
  }

  @override
  Future<int> calculateCount({
    required NotificationRepositoryFilters? filters,
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
    required NotificationRepositoryFilters? filters,
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

extension DbNotificationPopulatedListExtension
    on List<DbNotificationPopulated> {
  List<DbNotificationPopulatedWrapper> toDbNotificationPopulatedWrapperList() =>
      map(
        (item) => item.toDbNotificationPopulatedWrapper(),
      ).toList();
}

extension DbNotificationPopulatedWrapperExtension
    on DbNotificationPopulatedWrapper {
  DbNotification toDbNotification() => dbNotificationPopulated.dbNotification;
}
