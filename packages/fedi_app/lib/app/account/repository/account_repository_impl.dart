import 'package:fedi_app/app/account/account_model.dart';
import 'package:fedi_app/app/account/account_model_adapter.dart';
import 'package:fedi_app/app/account/database/account_database_dao.dart';
import 'package:fedi_app/app/account/database/account_followers_database_dao.dart';
import 'package:fedi_app/app/account/database/account_followings_database_dao.dart';
import 'package:fedi_app/app/account/repository/account_repository.dart';
import 'package:fedi_app/app/account/repository/account_repository_model.dart';
import 'package:fedi_app/app/chat/conversation/conversation_chat_model.dart';
import 'package:fedi_app/app/chat/conversation/database/conversation_chat_accounts_database_dao.dart';
import 'package:fedi_app/app/chat/unifedi/database/unifedi_chat_accounts_database_dao.dart';
import 'package:fedi_app/app/chat/unifedi/unifedi_chat_model.dart';
import 'package:fedi_app/app/database/app_database.dart';
import 'package:fedi_app/app/database/dao/populated_database_dao_mixin.dart';
import 'package:fedi_app/app/database/dao/repository/remote/populated_app_remote_database_dao_repository.dart';
import 'package:fedi_app/app/status/database/status_favourited_accounts_database_dao.dart';
import 'package:fedi_app/app/status/database/status_reblogged_accounts_database_dao.dart';
import 'package:drift/drift.dart';
import 'package:unifedi_api/unifedi_api.dart';

class AccountRepository extends PopulatedAppRemoteDatabaseDaoRepository<
    DbAccount,
    DbAccountPopulated,
    IAccount,
    IUnifediApiAccount,
    int,
    String,
    $DbAccountsTable,
    $DbAccountsTable,
    AccountRepositoryFilters,
    AccountRepositoryOrderingTermData> implements IAccountRepository {
  @override
  final AccountDao dao;
  final AccountFollowingsDao accountFollowingsDao;
  final AccountFollowersDao accountFollowersDao;
  final StatusFavouritedAccountsDao statusFavouritedAccountsDao;
  final StatusRebloggedAccountsDao statusRebloggedAccountsDao;
  final ConversationAccountsDao conversationAccountsDao;
  final ChatAccountsDao chatAccountsDao;

  @override
  PopulatedDatabaseDaoMixin<
      DbAccount,
      DbAccountPopulated,
      int,
      $DbAccountsTable,
      $DbAccountsTable,
      AccountRepositoryFilters,
      AccountRepositoryOrderingTermData> get populatedDao => dao;

  AccountRepository({
    required AppDatabase appDatabase,
  })  : dao = appDatabase.accountDao,
        accountFollowingsDao = appDatabase.accountFollowingsDao,
        accountFollowersDao = appDatabase.accountFollowersDao,
        statusFavouritedAccountsDao = appDatabase.statusFavouritedAccountsDao,
        statusRebloggedAccountsDao = appDatabase.statusRebloggedAccountsDao,
        conversationAccountsDao = appDatabase.conversationAccountsDao,
        chatAccountsDao = appDatabase.chatAccountsDao;

  Future<void> upsertRemoteAccount(
    IUnifediApiAccount unifediApiAccount, {
    required String? conversationRemoteId,
    required String? chatRemoteId,
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      // ignore: unawaited_futures
      _upsertRemoteAccountMetadata(
        unifediApiAccount,
        conversationRemoteId: conversationRemoteId,
        chatRemoteId: chatRemoteId,
        batchTransaction: batchTransaction,
      );

      // ignore: unawaited_futures
      upsertInDbTypeBatch(
        unifediApiAccount.toDbAccount(),
        batchTransaction: batchTransaction,
      );
    } else {
      await batch((batch) {
        upsertRemoteAccount(
          unifediApiAccount,
          conversationRemoteId: conversationRemoteId,
          chatRemoteId: chatRemoteId,
          batchTransaction: batch,
        );
      });
    }
  }

  Future<void> _upsertRemoteAccountMetadata(
    IUnifediApiAccount unifediApiAccount, {
    required String? conversationRemoteId,
    required String? chatRemoteId,
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      var accountRemoteId = unifediApiAccount.id;
      if (conversationRemoteId != null) {
        // ignore: unawaited_futures
        conversationAccountsDao.insertBatch(
          entity: DbConversationAccount(
            id: null,
            conversationRemoteId: conversationRemoteId,
            accountRemoteId: accountRemoteId,
          ),
          mode: InsertMode.insertOrReplace,
          batchTransaction: batchTransaction,
        );
      }
      if (chatRemoteId != null) {
        // ignore: unawaited_futures
        chatAccountsDao.insertBatch(
          entity: DbChatAccount(
            id: null,
            chatRemoteId: chatRemoteId,
            accountRemoteId: accountRemoteId,
          ),
          mode: InsertMode.insertOrReplace,
          batchTransaction: batchTransaction,
        );
      }
    } else {
      return batch((batch) {
        _upsertRemoteAccountMetadata(
          unifediApiAccount,
          conversationRemoteId: conversationRemoteId,
          chatRemoteId: chatRemoteId,
          batchTransaction: batch,
        );
      });
    }
  }

  @override
  Future<void> addAccountFollowings({
    required String accountRemoteId,
    required List<UnifediApiAccount> followings,
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      // ignore: unawaited_futures
      upsertAllInRemoteType(
        followings,
        batchTransaction: batchTransaction,
      );
      // await accountFollowingsDao.deleteByAccountRemoteId(accountRemoteId);
      // ignore: unawaited_futures
      accountFollowingsDao.insertAll(
        entities: followings
            .map(
              (followingAccount) => DbAccountFollowing(
                id: null,
                accountRemoteId: accountRemoteId,
                followingAccountRemoteId: followingAccount.id,
              ),
            )
            .toList(),
        mode: InsertMode.insertOrReplace,
        batchTransaction: batchTransaction,
      );
    } else {
      await dao.batch(
        (batch) => addAccountFollowings(
          accountRemoteId: accountRemoteId,
          followings: followings,
          batchTransaction: batch,
        ),
      );
    }
  }

  @override
  Future<void> addAccountFollowers({
    required String accountRemoteId,
    required List<IUnifediApiAccount> followers,
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      // ignore: unawaited_futures
      upsertAllInRemoteType(
        followers,
        batchTransaction: batchTransaction,
      );
      // await accountFollowersDao.deleteByAccountRemoteId(accountRemoteId);
      // ignore: unawaited_futures
      accountFollowersDao.insertAll(
        entities: followers
            .map(
              (followerAccount) => DbAccountFollower(
                id: null,
                accountRemoteId: accountRemoteId,
                followerAccountRemoteId: followerAccount.id,
              ),
            )
            .toList(),
        mode: InsertMode.insertOrReplace,
        batchTransaction: batchTransaction,
      );
    } else {
      await dao.batch(
        (batch) => addAccountFollowers(
          accountRemoteId: accountRemoteId,
          followers: followers,
          batchTransaction: batch,
        ),
      );
    }
  }

  @override
  Future<void> updateStatusFavouritedBy({
    required String statusRemoteId,
    required List<IUnifediApiAccount> favouritedByAccounts,
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      // ignore: unawaited_futures
      upsertAllInRemoteType(
        favouritedByAccounts,
        batchTransaction: batchTransaction,
      );
      // ignore: unawaited_futures, avoid-ignoring-return-values
      statusFavouritedAccountsDao.deleteByStatusRemoteId(statusRemoteId);
      // ignore: unawaited_futures, cascade_invocations
      statusFavouritedAccountsDao.insertAll(
        entities: favouritedByAccounts
            .map(
              (favouritedByAccount) => DbStatusFavouritedAccount(
                id: null,
                accountRemoteId: favouritedByAccount.id,
                statusRemoteId: statusRemoteId,
              ),
            )
            .toList(),
        mode: InsertMode.insertOrReplace,
        batchTransaction: batchTransaction,
      );
    } else {
      await dao.batch(
        (batch) => updateStatusFavouritedBy(
          statusRemoteId: statusRemoteId,
          favouritedByAccounts: favouritedByAccounts,
          batchTransaction: batch,
        ),
      );
    }
  }

  @override
  Future<void> updateStatusRebloggedBy({
    required String statusRemoteId,
    required List<IUnifediApiAccount> rebloggedByAccounts,
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      // ignore: unawaited_futures
      upsertAllInRemoteType(
        rebloggedByAccounts,
        batchTransaction: batchTransaction,
      );
      // ignore: unawaited_futures
      statusRebloggedAccountsDao.deleteByStatusRemoteIdBatch(
        statusRemoteId,
        batchTransaction: batchTransaction,
      );
      // ignore: unawaited_futures, cascade_invocations
      statusRebloggedAccountsDao.insertAll(
        entities: rebloggedByAccounts
            .map(
              (favouritedByAccount) => DbStatusRebloggedAccount(
                id: null,
                accountRemoteId: favouritedByAccount.id,
                statusRemoteId: statusRemoteId,
              ),
            )
            .toList(),
        mode: InsertMode.insertOrReplace,
        batchTransaction: batchTransaction,
      );
    } else {
      return batch(
        (batch) => updateStatusRebloggedBy(
          statusRemoteId: statusRemoteId,
          rebloggedByAccounts: rebloggedByAccounts,
          batchTransaction: batch,
        ),
      );
    }
  }

  @override
  Future<List<IAccount>> getConversationAccounts({
    required IConversationChat conversation,
  }) =>
      findAllInAppType(
        filters: AccountRepositoryFilters.createForOnlyInConversation(
          conversation: conversation,
        ),
        pagination: null,
        orderingTerms: null,
      );

  @override
  Stream<List<IAccount>> watchConversationAccounts({
    required IConversationChat conversation,
  }) =>
      watchFindAllInAppType(
        filters: AccountRepositoryFilters.createForOnlyInConversation(
          conversation: conversation,
        ),
        pagination: null,
        orderingTerms: null,
      );

  @override
  Future<List<IAccount>> getChatAccounts({required IUnifediChat chat}) =>
      findAllInAppType(
        filters: AccountRepositoryFilters.createForOnlyInChat(
          chat: chat,
        ),
        pagination: null,
        orderingTerms: null,
      );

  @override
  Stream<List<IAccount>> watchChatAccounts({required IUnifediChat chat}) =>
      watchFindAllInAppType(
        filters: AccountRepositoryFilters.createForOnlyInChat(
          chat: chat,
        ),
        pagination: null,
        orderingTerms: null,
      );

  @override
  Future<void> removeAccountFollowing({
    required String accountRemoteId,
    required String followingAccountId,
    required Batch? batchTransaction,
  }) =>
      accountFollowingsDao
          .deleteByAccountRemoteIdAndFollowingAccountRemoteIdBatch(
        followingAccountRemoteId: followingAccountId,
        accountRemoteId: accountRemoteId,
        batchTransaction: batchTransaction,
      );

  @override
  Future<void> removeAccountFollower({
    required String accountRemoteId,
    required String followerAccountId,
    required Batch? batchTransaction,
  }) =>
      accountFollowersDao
          .deleteByAccountRemoteIdAndFollowerAccountRemoteIdBatch(
        followerAccountRemoteId: followerAccountId,
        accountRemoteId: accountRemoteId,
        batchTransaction: batchTransaction,
      );

  @override
  DbAccount mapAppItemToDbItem(IAccount appItem) => appItem.toDbAccount();

  @override
  IUnifediApiAccount mapAppItemToRemoteItem(IAccount appItem) =>
      appItem.toUnifediApiAccount();

  @override
  DbAccount mapRemoteItemToDbItem(IUnifediApiAccount remoteItem) =>
      remoteItem.toDbAccount();

  @override
  IAccount mapRemoteItemToAppItem(IUnifediApiAccount remoteItem) =>
      remoteItem.toDbAccountWrapper();

  @override
  DbAccountPopulated mapAppItemToDbPopulatedItem(IAccount appItem) =>
      appItem.toDbAccountPopulated();

  @override
  IAccount mapDbPopulatedItemToAppItem(DbAccountPopulated dbPopulatedItem) =>
      DbAccountPopulatedWrapper(dbAccountPopulated: dbPopulatedItem);

  @override
  IUnifediApiAccount mapDbPopulatedItemToRemoteItem(
    DbAccountPopulated dbPopulatedItem,
  ) =>
      mapDbPopulatedItemToAppItem(dbPopulatedItem).toUnifediApiAccount();

  @override
  AccountRepositoryFilters get emptyFilters => AccountRepositoryFilters.empty;

  @override
  List<AccountRepositoryOrderingTermData> get defaultOrderingTerms =>
      AccountRepositoryOrderingTermData.defaultTerms;

  @override
  Future<void> insertInDbTypeBatch(
    Insertable<DbAccount> dbItem, {
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
    IUnifediApiAccount remoteItem, {
    required InsertMode? mode,
  }) async {
    await _upsertRemoteAccountMetadata(
      remoteItem,
      conversationRemoteId: null,
      chatRemoteId: null,
      batchTransaction: null,
    );

    var id = await insertInDbType(
      remoteItem.toDbAccount(),
      mode: mode,
    );

    return id;
  }

  @override
  Future<void> insertInRemoteTypeBatch(
    IUnifediApiAccount remoteItem, {
    required InsertMode? mode,
    required Batch? batchTransaction,
  }) =>
      upsertRemoteAccount(
        remoteItem,
        conversationRemoteId: null,
        chatRemoteId: null,
        batchTransaction: batchTransaction,
      );

  @override
  Future<void> updateAppTypeByRemoteType({
    required IAccount appItem,
    required IUnifediApiAccount remoteItem,
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      if (appItem.localId != null) {
        // ignore: unawaited_futures
        updateByDbIdInDbType(
          dbId: appItem.localId!,
          dbItem: remoteItem.toDbAccount(),
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
    required DbAccount dbItem,
    required Batch? batchTransaction,
  }) =>
      insertInDbTypeBatch(
        dbItem.copyWith(id: dbId),
        mode: InsertMode.insertOrReplace,
        batchTransaction: batchTransaction,
      );

  @override
  Future<void> upsertChatRemoteAccount(
    IUnifediApiAccount remoteAccount, {
    required String chatRemoteId,
    required Batch? batchTransaction,
  }) =>
      upsertRemoteAccount(
        remoteAccount,
        conversationRemoteId: null,
        chatRemoteId: chatRemoteId,
        batchTransaction: batchTransaction,
      );

  @override
  Future<void> upsertChatRemoteAccounts(
    List<IUnifediApiAccount> remoteAccounts, {
    required String chatRemoteId,
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      for (final remoteAccount in remoteAccounts) {
        // ignore: unawaited_futures
        upsertChatRemoteAccount(
          remoteAccount,
          chatRemoteId: chatRemoteId,
          batchTransaction: batchTransaction,
        );
      }
    } else {
      await batch((batch) {
        upsertChatRemoteAccounts(
          remoteAccounts,
          chatRemoteId: chatRemoteId,
          batchTransaction: batch,
        );
      });
    }
  }

  @override
  Future<void> upsertConversationRemoteAccount(
    IUnifediApiAccount remoteAccount, {
    required String conversationRemoteId,
    required Batch? batchTransaction,
  }) =>
      upsertRemoteAccount(
        remoteAccount,
        conversationRemoteId: conversationRemoteId,
        chatRemoteId: null,
        batchTransaction: batchTransaction,
      );

  @override
  Future<void> upsertConversationRemoteAccounts(
    List<IUnifediApiAccount> remoteAccounts, {
    required String conversationRemoteId,
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      for (final remoteAccount in remoteAccounts) {
        // ignore: unawaited_futures
        upsertConversationRemoteAccount(
          remoteAccount,
          conversationRemoteId: conversationRemoteId,
          batchTransaction: batchTransaction,
        );
      }
    } else {
      await batch(
        (batch) {
          upsertConversationRemoteAccounts(
            remoteAccounts,
            conversationRemoteId: conversationRemoteId,
            batchTransaction: batch,
          );
        },
      );
    }
  }
}

extension DbAccountListExtension on List<DbAccount> {
  List<DbAccountPopulatedWrapper> toDbAccountPopulatedWrapperList() => map(
        (item) => item.toDbAccountWrapper(),
      ).toList();
}

extension DbAccountWrapperExtension on DbAccountPopulatedWrapper {
  DbAccount toDbAccount() => dbAccount;
}
