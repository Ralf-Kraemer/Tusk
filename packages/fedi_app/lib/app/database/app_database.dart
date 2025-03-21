import 'package:fedi_app/app/account/database/account_database_dao.dart';
import 'package:fedi_app/app/account/database/account_database_model.dart';
import 'package:fedi_app/app/account/database/account_followers_database_dao.dart';
import 'package:fedi_app/app/account/database/account_followers_database_model.dart';
import 'package:fedi_app/app/account/database/account_followings_database_dao.dart';
import 'package:fedi_app/app/account/database/account_followings_database_model.dart';
import 'package:fedi_app/app/chat/conversation/database/conversation_chat_accounts_database_dao.dart';
import 'package:fedi_app/app/chat/conversation/database/conversation_chat_accounts_database_model.dart';
import 'package:fedi_app/app/chat/conversation/database/conversation_chat_database_dao.dart';
import 'package:fedi_app/app/chat/conversation/database/conversation_chat_database_model.dart';
import 'package:fedi_app/app/chat/conversation/database/conversation_chat_statuses_database_dao.dart';
import 'package:fedi_app/app/chat/conversation/database/conversation_chat_statuses_database_model.dart';
import 'package:fedi_app/app/chat/unifedi/database/unifedi_chat_accounts_database_dao.dart';
import 'package:fedi_app/app/chat/unifedi/database/unifedi_chat_accounts_database_model.dart';
import 'package:fedi_app/app/chat/unifedi/database/unifedi_chat_database_dao.dart';
import 'package:fedi_app/app/chat/unifedi/database/unifedi_chat_database_model.dart';
import 'package:fedi_app/app/chat/unifedi/message/database/unifedi_chat_message_database_dao.dart';
import 'package:fedi_app/app/chat/unifedi/message/database/unifedi_chat_message_database_model.dart';
import 'package:fedi_app/app/filter/database/filter_database_dao.dart';
import 'package:fedi_app/app/filter/database/filter_database_model.dart';
import 'package:fedi_app/app/instance/announcement/database/instance_announcement_database_dao.dart';
import 'package:fedi_app/app/instance/announcement/database/instance_announcement_database_model.dart';
import 'package:fedi_app/app/moor/moor_converters.dart';
import 'package:fedi_app/app/notification/database/notification_database_dao.dart';
import 'package:fedi_app/app/notification/database/notification_database_model.dart';
import 'package:fedi_app/app/pending/pending_model.dart';
import 'package:fedi_app/app/status/database/home_timeline_statuses_database_dao.dart';
import 'package:fedi_app/app/status/database/home_timeline_statuses_database_model.dart';
import 'package:fedi_app/app/status/database/status_database_dao.dart';
import 'package:fedi_app/app/status/database/status_database_model.dart';
import 'package:fedi_app/app/status/database/status_favourited_accounts_database_dao.dart';
import 'package:fedi_app/app/status/database/status_favourited_accounts_database_model.dart';
import 'package:fedi_app/app/status/database/status_hashtags_database_dao.dart';
import 'package:fedi_app/app/status/database/status_hashtags_database_model.dart';
import 'package:fedi_app/app/status/database/status_lists_database_dao.dart';
import 'package:fedi_app/app/status/database/status_lists_database_model.dart';
import 'package:fedi_app/app/status/database/status_reblogged_accounts_database_dao.dart';
import 'package:fedi_app/app/status/database/status_reblogged_accounts_database_model.dart';
import 'package:fedi_app/app/status/draft/database/draft_status_database_dao.dart';
import 'package:fedi_app/app/status/draft/database/draft_status_database_model.dart';
import 'package:fedi_app/app/status/post/post_status_model.dart';
import 'package:fedi_app/app/status/scheduled/database/scheduled_status_database_dao.dart';
import 'package:fedi_app/app/status/scheduled/database/scheduled_status_database_model.dart';
import 'package:fedi_app/drift/drift_json_type_converter.dart';
import 'package:drift/drift.dart';
import 'package:unifedi_api/unifedi_api.dart';

part 'app_database.g.dart';

// ignore_for_file: no-magic-number
@UseMoor(
  tables: [
    // todo: remove hack
    // bug in moor - https://github.com/simolus3/moor/issues/447
    // we should exclude tables here because we use this tables in
    // app_database.moor
//    DbStatuses,
//    DbConversations,
//    DbNotifications,
//    DbAccounts,
//    DbConversationStatuses,
//    DbStatusHashtags,
//    DbStatusLists,
//    DbStatusFavouritedAccounts,
//    DbStatusRebloggedAccounts,
//    DbAccountFollowings,
//    DbAccountFollowers,
//    DbConversationAccounts,
//    DbScheduledStatuses,
//  DbChats,
//  DbChatAccounts,
//  DbChatMessages,
    DbHomeTimelineStatuses, DbDraftStatuses, //  DbAccountRelationships
    // DbInstanceAnnouncements,
  ],
  daos: [
    StatusDao,
    StatusHashtagsDao,
    StatusListsDao,
    AccountDao,
    AccountFollowingsDao,
    AccountFollowersDao,
    ConversationDao,
    ConversationAccountsDao,
    ConversationStatusesDao,
    StatusFavouritedAccountsDao,
    StatusRebloggedAccountsDao,
    NotificationDao,
    ScheduledStatusDao,
    ChatDao,
    ChatAccountsDao,
    ChatMessageDao,
    HomeTimelineStatusesDao,
    DraftStatusDao,
    FilterDao,
    InstanceAnnouncementDao,

//  AccountRelationshipsDao
  ],
  include: {'app_database.moor'},
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 17;

  int? migrationsFromExecuted;
  int? migrationsToExecuted;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          var currentVersion = from;
          migrationsFromExecuted = from;
          migrationsToExecuted = to;

          while (currentVersion < to) {
            switch (currentVersion) {
              case 1:
                await _migrate1to2(m);
                break;
              case 2:
                await _migrate2to3(m);
                break;
              case 3:
                await _migrate3to4(m);
                break;
              case 4:
                await _migrate4to5(m);
                break;
              case 5:
                await _migrate5to6(m);
                break;
              case 6:
                await _migrate6to7(m);
                break;
              case 7:
                await _migrate7to8(m);
                break;
              case 8:
                await _migrate8to9(m);
                break;
              case 9:
                await _migrate9to10(m);
                break;
              case 10:
                await _migrate10to11(m);
                break;
              case 11:
                await _migrate11to12(m);
                break;
              case 12:
                await _migrate12to13(m);
                break;
              case 13:
                await _migrate13to14(m);
                break;
              case 14:
                await _migrate14to15(m);
                break;
              case 15:
                await _migrate15to16(m);
                break;
              case 16:
                await _migrate16to17(m);
                break;
              default:
                throw ArgumentError('invalid currentVersion $currentVersion');
            }
            currentVersion++;
          }
        },
      );

  Future<void> _migrate16to17(Migrator m) async {
    await m.addColumn(dbAccounts, dbAccounts.suspended);
    await m.addColumn(dbAccounts, dbAccounts.isConfirmed);
    await m.addColumn(dbAccounts, dbAccounts.muteExpiresAt);
    await m.addColumn(dbAccounts, dbAccounts.fqn);
    await m.addColumn(dbAccounts, dbAccounts.favicon);
    await m.addColumn(dbAccounts, dbAccounts.apId);
    await m.addColumn(dbAccounts, dbAccounts.alsoKnownAs);
  }

  Future<void> _migrate15to16(Migrator m) async {
    await m.createTable(dbInstanceAnnouncements);
  }

  Future<void> _migrate14to15(Migrator m) async {
    await m.addColumn(dbNotifications, dbNotifications.chatMessage);
    await m.addColumn(dbNotifications, dbNotifications.target);
    await m.addColumn(dbNotifications, dbNotifications.report);
  }

  Future<void> _migrate13to14(Migrator m) async {
    await m.addColumn(dbStatuses, dbStatuses.hiddenLocallyOnDevice);
    await m.addColumn(dbStatuses, dbStatuses.wasSentWithIdempotencyKey);
    await m.addColumn(dbChatMessages, dbChatMessages.hiddenLocallyOnDevice);
    await m.addColumn(dbChatMessages, dbChatMessages.wasSentWithIdempotencyKey);
  }

  Future<void> _migrate12to13(Migrator m) async {
    await m.addColumn(dbChatMessages, dbChatMessages.deleted);
  }

  Future<void> _migrate11to12(Migrator m) async {
    await m.addColumn(dbStatuses, dbStatuses.oldPendingRemoteId);
    await m.addColumn(dbChatMessages, dbChatMessages.oldPendingRemoteId);
  }

  Future<void> _migrate10to11(Migrator m) async {
    await m.addColumn(dbStatuses, dbStatuses.pendingState);
    await m.addColumn(dbChatMessages, dbChatMessages.pendingState);
  }

  Future<void> _migrate9to10(Migrator m) async {
    await m.addColumn(dbAccounts, dbAccounts.acceptsChatMessages);
  }

  Future<void> _migrate8to9(Migrator m) async {
    // after schema rework we need re-create table
    await m.deleteTable(dbFilters.actualTableName);
    await m.createTable(dbFilters);
  }

  Future<void> _migrate7to8(Migrator m) async {
    await m.createTable(dbFilters);
  }

  Future<void> _migrate6to7(Migrator m) =>
      m.addColumn(dbConversations, dbConversations.updatedAt);

  Future<void> _migrate5to6(Migrator m) =>
      m.addColumn(dbNotifications, dbNotifications.dismissed);

  Future<void> _migrate4to5(Migrator m) =>
      m.addColumn(dbAccounts, dbAccounts.backgroundImage);

  Future<void> _migrate3to4(Migrator m) =>
      m.addColumn(dbStatuses, dbStatuses.deleted);

  Future<void> _migrate2to3(Migrator m) => m.createTable(dbDraftStatuses);

  Future<void> _migrate1to2(Migrator m) async =>
      m.addColumn(dbChatMessages, dbChatMessages.card);
}
