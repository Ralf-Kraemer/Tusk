import 'package:fedi_app/app/chat/unifedi/database/unifedi_chat_accounts_database_model.dart';
import 'package:fedi_app/app/database/app_database.dart';
import 'package:fedi_app/app/database/dao/database_dao.dart';
import 'package:drift/drift.dart';

part 'unifedi_chat_accounts_database_dao.g.dart';

@DriftAccessor(
  tables: [
    DbChatAccounts,
  ],
)
class ChatAccountsDao extends DatabaseDao<DbChatAccount, int,
    $DbChatAccountsTable, $DbChatAccountsTable> with _$ChatAccountsDaoMixin {
  final AppDatabase db;

  // Called by the AppDatabase class
  ChatAccountsDao(this.db) : super(db);

  @override
  $DbChatAccountsTable get table => dbChatAccounts;

  Selectable<DbChatAccount> findByChatRemoteId(String chatRemoteId) =>
      customSelect(
        'SELECT * FROM db_chat_accounts WHERE chat_remote_id = :chatRemoteId;',
        variables: [Variable<String>(chatRemoteId)],
        readsFrom: {dbChatAccounts},
      ).map(dbChatAccounts.mapFromRow);

  Selectable<DbChatAccount> findByChatRemoteIdAndAccountRemoteId(
    String chatRemoteId,
    String accountRemoteId,
  ) =>
      customSelect(
        'SELECT * FROM db_chat_accounts WHERE chat_remote_id = :chatRemoteId AND account_remote_id = :accountRemoteId;',
        variables: [
          Variable<String>(chatRemoteId),
          Variable<String>(accountRemoteId),
        ],
        readsFrom: {dbChatAccounts},
      ).map(dbChatAccounts.mapFromRow);

  Selectable<DbChatAccount> findByAccountRemoteId(String accountRemoteId) =>
      customSelect(
        'SELECT * FROM db_chat_accounts WHERE account_remote_id = :accountRemoteId;',
        variables: [Variable<String>(accountRemoteId)],
        readsFrom: {
          dbChatAccounts,
        },
      ).map(
        dbChatAccounts.mapFromRow,
      );

  Future<int> deleteByChatRemoteId(String chatRemoteId) => customUpdate(
        'DELETE FROM $tableName '
        'WHERE ${_createChatRemoteIdEqualExpression(chatRemoteId)}',
        updates: {table},
        updateKind: UpdateKind.delete,
      );

  Future<void> deleteByChatRemoteIdBatch(
    String chatRemoteId, {
    required Batch? batchTransaction,
  }) async {
    if (batchTransaction != null) {
      batchTransaction.deleteWhere(
        table,
        (tbl) => _createChatRemoteIdEqualExpression(chatRemoteId),
      );
    } else {
      // ignore: avoid-ignoring-return-values
      await deleteByChatRemoteId(chatRemoteId);
    }
  }

  CustomExpression<bool> _createChatRemoteIdEqualExpression(
    String chatRemoteId,
  ) =>
      createMainTableEqualWhereExpression(
        fieldName: table.chatRemoteId.$name,
        value: chatRemoteId,
      );
}
