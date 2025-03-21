import 'package:fedi_app/app/chat/conversation/database/conversation_chat_accounts_database_model.dart';
import 'package:fedi_app/app/database/app_database.dart';
import 'package:fedi_app/app/database/dao/database_dao.dart';
import 'package:drift/drift.dart';

part 'conversation_chat_accounts_database_dao.g.dart';

@DriftAccessor(
  tables: [
    DbConversationAccounts,
  ],
)
class ConversationAccountsDao extends DatabaseDao<
    DbConversationAccount,
    int,
    $DbConversationAccountsTable,
    $DbConversationAccountsTable> with _$ConversationAccountsDaoMixin {
  final AppDatabase db;

  // Called by the AppDatabase class
  ConversationAccountsDao(this.db) : super(db);

  @override
  $DbConversationAccountsTable get table => dbConversationAccounts;
}
