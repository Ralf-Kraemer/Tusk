import 'dart:async';

import 'package:easy_dispose/easy_dispose.dart';
import 'package:fedi_app/app/account/account_model.dart';
import 'package:fedi_app/app/account/my/my_account_bloc.dart';
import 'package:fedi_app/app/account/repository/account_repository.dart';
import 'package:fedi_app/app/account/repository/account_repository_model.dart';
import 'package:fedi_app/app/chat/chat_bloc_impl.dart';
import 'package:fedi_app/app/chat/conversation/conversation_chat_bloc.dart';
import 'package:fedi_app/app/chat/conversation/conversation_chat_model.dart';
import 'package:fedi_app/app/chat/conversation/message/conversation_chat_message_model.dart';
import 'package:fedi_app/app/chat/conversation/repository/conversation_chat_repository.dart';
import 'package:fedi_app/app/chat/message/chat_message_model.dart';
import 'package:fedi_app/app/database/app_database.dart';
import 'package:fedi_app/app/pending/pending_model.dart';
import 'package:fedi_app/app/status/post/post_status_data_status_status_adapter.dart';
import 'package:fedi_app/app/status/post/post_status_model.dart';
import 'package:fedi_app/app/status/repository/status_repository.dart';
import 'package:fedi_app/app/status/status_model.dart';
import 'package:fedi_app/connection/connection_service.dart';
import 'package:fedi_app/id/fake_id_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:drift/drift.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:unifedi_api/unifedi_api.dart';

final _logger = Logger('conversation_chat_bloc_impl.dart');

class ConversationChatBloc extends ChatBloc implements IConversationChatBloc {
  // ignore: close_sinks
  final BehaviorSubject<IConversationChat> _chatSubject;

  // ignore: close_sinks
  final BehaviorSubject<IConversationChatMessage?> _lastMessageSubject;

  // ignore: close_sinks
  final BehaviorSubject<IConversationChatMessage> _lastPublishedMessageSubject =
      BehaviorSubject();

  final BehaviorSubject<List<IAccount>> _accountsSubject;

  @override
  List<IAccount> get accounts => _accountsSubject.value;

  @override
  Stream<List<IAccount>> get accountsStream =>
      _accountsSubject.stream.distinct(listEquals);

  @override
  IConversationChat get chat => _chatSubject.value;

  @override
  Stream<IConversationChat> get chatStream => _chatSubject.stream;

  @override
  IConversationChatMessage? get lastChatMessage =>
      _lastMessageSubject.valueOrNull;

  @override
  Stream<IConversationChatMessage?> get lastChatMessageStream =>
      _lastMessageSubject.stream;

  final StreamController<IConversationChatMessage>
      onMessageLocallyHiddenStreamController = StreamController.broadcast();

  @override
  Stream<IConversationChatMessage> get onMessageLocallyHiddenStream =>
      onMessageLocallyHiddenStreamController.stream;

  final IMyAccountBloc myAccountBloc;
  final IUnifediApiConversationService unifediConversationService;
  final IUnifediApiStatusService unifediApiStatusService;
  final IConversationChatRepository conversationRepository;
  final IStatusRepository statusRepository;
  final IAccountRepository accountRepository;
  final IConnectionService connectionService;

  @override
  List<IAccount> get accountsWithoutMe => accounts;

  @override
  Stream<List<IAccount>> get accountsWithoutMeStream => accountsStream;

  void listenForAccounts(IConversationChat conversation) {
    accountRepository
        .watchFindAllInAppType(
      filters: AccountRepositoryFilters.createForOnlyInConversation(
        conversation: conversation,
      ),
      pagination: null,
      orderingTerms: null,
    )
        .listen(
      (accounts) {
        var accountsWithoutMe = IAccount.excludeAccountFromList(
          accounts,
          (account) => !myAccountBloc.checkAccountIsMe(account),
        );
        // ignore: cascade_invocations
        accountsWithoutMe.sort(
          (a, b) => a.remoteId.compareTo(b.remoteId),
        );
        _accountsSubject.add(accountsWithoutMe);
      },
    ).disposeWith(this);
  }

  ConversationChatBloc({
    required this.unifediConversationService,
    required this.myAccountBloc,
    required this.conversationRepository,
    required this.unifediApiStatusService,
    required this.statusRepository,
    required this.accountRepository,
    required this.connectionService,
    required IConversationChat conversation,
    required IConversationChatMessage? lastChatMessage,
    bool needRefreshFromNetworkOnInit = false,
    bool isNeedWatchLocalRepositoryForUpdates =
        true, // todo: remove hack. Dont init when bloc quickly disposed. Help
    //  improve performance in timeline unnecessary recreations
    bool delayInit = true,
  })  : _accountsSubject = BehaviorSubject.seeded([]),
        _chatSubject = BehaviorSubject.seeded(conversation),
        _lastMessageSubject = BehaviorSubject.seeded(lastChatMessage),
        super(
          needRefreshFromNetworkOnInit: needRefreshFromNetworkOnInit,
          isNeedWatchLocalRepositoryForUpdates:
              isNeedWatchLocalRepositoryForUpdates,
          delayInit: delayInit,
        ) {
    _logger.finest(() => 'conversation chat bloc');

    _chatSubject.disposeWith(this);
    _lastMessageSubject.disposeWith(this);
    _lastPublishedMessageSubject.disposeWith(this);
    _accountsSubject.disposeWith(this);
    onMessageLocallyHiddenStreamController.disposeWith(this);

    listenForAccounts(conversation);
  }

  @override
  void watchLocalRepositoryForUpdates() {
    conversationRepository.watchByRemoteIdInAppType(chat.remoteId).listen(
      (updatedChat) {
        if (updatedChat != null) {
          _chatSubject.add(updatedChat);
        }
      },
    ).disposeWith(this);

    statusRepository
        .watchConversationLastStatus(
      conversation: chat,
    )
        .listen(
      (lastStatus) {
        if (lastStatus != null) {
          var conversationChatMessageStatusAdapter =
              ConversationChatMessageStatusAdapter(
            status: lastStatus,
          );
          _lastMessageSubject.add(
            conversationChatMessageStatusAdapter,
          );

          if (conversationChatMessageStatusAdapter
              .isPendingStatePublishedOrNull) {
            _lastPublishedMessageSubject.add(
              conversationChatMessageStatusAdapter,
            );
          }
        }
      },
    ).disposeWith(this);
  }

  @override
  Future<void> internalAsyncInit() async {
    var conversationLastStatus =
        await statusRepository.getConversationLastStatus(
      conversation: chat,
    );

    if (conversationLastStatus != null) {
      var conversationChatMessageStatusAdapter =
          conversationLastStatus.toConversationChatMessageStatusAdapter();
      if (!_lastMessageSubject.isClosed) {
        _lastMessageSubject.add(
          conversationChatMessageStatusAdapter,
        );
      }

      var pendingStatePublishedOrNull =
          conversationChatMessageStatusAdapter.isPendingStatePublishedOrNull;
      if (pendingStatePublishedOrNull) {
        _lastPublishedMessageSubject.add(
          conversationChatMessageStatusAdapter,
        );
      } else {
        var conversationLastPublishedStatus =
            await statusRepository.getConversationLastStatus(
          conversation: chat,
          onlyPendingStatePublishedOrNull: true,
        );
        if (!_lastPublishedMessageSubject.isClosed &&
            conversationLastPublishedStatus != null) {
          _lastPublishedMessageSubject.add(
            conversationLastPublishedStatus
                .toConversationChatMessageStatusAdapter(),
          );
        }
      }
    }
  }

  @override
  Future<void> refreshFromNetwork() async {
    var remoteConversation = await unifediConversationService.getConversation(
      conversationId: chat.remoteId,
    );

    await accountRepository.batch((batch) {
      if (remoteConversation.accounts.isNotEmpty) {
        for (final account in remoteConversation.accounts) {
          accountRepository.upsertConversationRemoteAccount(
            account,
            conversationRemoteId: remoteConversation.id,
            batchTransaction: batch,
          );
        }
      }
      var lastStatus = remoteConversation.lastStatus;
      if (lastStatus != null) {
        statusRepository.upsertRemoteStatusForConversation(
          lastStatus,
          conversationRemoteId: remoteConversation.id,
          batchTransaction: batch,
        );
      }

      _updateByRemoteChat(
        remoteConversation,
        batchTransaction: batch,
      );
    });
  }

  Future<void> _updateByRemoteChat(
    IUnifediApiConversation remoteChat, {
    required Batch batchTransaction,
  }) =>
      conversationRepository.updateAppTypeByRemoteType(
        appItem: chat,
        remoteItem: remoteChat,
        batchTransaction: batchTransaction,
      );

  static ConversationChatBloc createFromContext(
    BuildContext context, {
    required IConversationChat chat,
    required IConversationChatMessage? lastChatMessage,
    bool needRefreshFromNetworkOnInit = false,
  }) =>
      ConversationChatBloc(
        connectionService:
            Provider.of<IConnectionService>(context, listen: false),
        unifediConversationService:
            Provider.of<IUnifediApiConversationService>(context, listen: false),
        myAccountBloc: IMyAccountBloc.of(context, listen: false),
        conversation: chat,
        lastChatMessage: lastChatMessage,
        needRefreshFromNetworkOnInit: needRefreshFromNetworkOnInit,
        conversationRepository:
            IConversationChatRepository.of(context, listen: false),
        statusRepository: IStatusRepository.of(context, listen: false),
        accountRepository: IAccountRepository.of(context, listen: false),
        unifediApiStatusService: Provider.of<IUnifediApiStatusService>(
          context,
          listen: false,
        ),
      );

  @override
  Future<void> markAsRead() async {
    if (chat.unread > 0) {
      if (connectionService.isConnected) {
        var lastReadChatMessageId = lastChatMessage?.remoteId;
        if (lastReadChatMessageId == null) {
          var lastStatus = await statusRepository.getConversationLastStatus(
            conversation: chat,
          );
          lastReadChatMessageId = lastStatus?.remoteId;
        }
        var updatedRemoteChat =
            await unifediConversationService.markConversationAsRead(
          conversationId: chat.remoteId,
        );

        // ignore: avoid-ignoring-return-values
        await conversationRepository.upsertInRemoteType(
          updatedRemoteChat,
        );
      } else {
        // TODO: mark as read once app receive network connection
        await conversationRepository.markAsRead(
          conversation: chat,
          batchTransaction: null,
        );
      }
    }
  }

  @override
  bool get isCountInUnreadSupported => false;

  @override
  Future<void> deleteMessages(List<IChatMessage> chatMessages) async {
    // create queue instead of parallel requests to avoid throttle limit on server
    for (final chatMessage in chatMessages) {
      if (chatMessage.isPendingStatePublishedOrNull) {
        await unifediApiStatusService.deleteStatus(
          statusId: chatMessage.remoteId,
        );
      }
    }

    for (final chatMessage in chatMessages) {
      // todo: rework in one request
      await statusRepository.markStatusAsDeleted(
        statusRemoteId: chatMessage.remoteId,
      );
    }
  }

  @override
  Future<void> performActualDelete() async {
    var remoteId = conversation.remoteId;
    await unifediConversationService.deleteConversation(
      conversationId: remoteId,
    );

    await conversationRepository.deleteByRemoteId(
      remoteId,
      batchTransaction: null,
    );
  }

  @override
  // todo: refactor
  // ignore: long-method
  Future<void> postMessage({
    required IPostStatusData postStatusData,
    required IConversationChatMessage? oldPendingFailedConversationChatMessage,
  }) async {
    DbStatus dbStatus;
    int? localStatusId;

    UnifediApiPostStatus postStatus;
    String? idempotencyKey;
    var oldMessageExist = oldPendingFailedConversationChatMessage != null;
    if (oldMessageExist) {
      localStatusId = oldPendingFailedConversationChatMessage!.status.localId;
      dbStatus = oldPendingFailedConversationChatMessage.status
          .toDbStatus()
          .copyWith(id: localStatusId);

      idempotencyKey = dbStatus.wasSentWithIdempotencyKey;
      var inReplyToConversationIdSupported =
          unifediApiStatusService.isFeatureSupported(
        unifediApiStatusService.postStatusInReplyToConversationIdFeature,
      );

      var previewSupported = unifediApiStatusService.isFeatureSupported(
        unifediApiStatusService.postStatusPreviewFeature,
      );

      var expiresInSupported = unifediApiStatusService.isFeatureSupported(
        unifediApiStatusService.postStatusExpiresInFeature,
      );

      postStatus = postStatusData.toPostStatus(
        inReplyToConversationIdSupported: inReplyToConversationIdSupported,
        previewSupported: previewSupported,
        expiresInSupported: expiresInSupported,
      );

      await statusRepository.updateByDbIdInDbType(
        dbId: localStatusId!,
        dbItem: dbStatus.copyWith(
          pendingState: PendingState.pending,
        ),
        batchTransaction: null,
      );
    } else {
      var createdAt = DateTime.now();
      var fakeUniqueRemoteRemoteId = FakeIdHelper.generateUniqueId();
      var account = myAccountBloc.account;
      var postStatusDataStatusStatusAdapter = PostStatusDataStatusStatusAdapter(
        account: account.toDbAccountWrapper(),
        postStatusData: postStatusData.toPostStatusData(),
        localId: null,
        createdAt: createdAt,
        pendingState: PendingState.pending,
        oldPendingRemoteId: fakeUniqueRemoteRemoteId,
        // ignore: no-equal-arguments
        wasSentWithIdempotencyKey: fakeUniqueRemoteRemoteId,
      );

      // for unifedi
      int? conversationIdInt;
      try {
        conversationIdInt = int.parse(chat.remoteId);
        // ignore: avoid_catches_without_on_clauses
      } catch (e) {
        // nothing, not all backends use int for conversation id
      }

      dbStatus = postStatusDataStatusStatusAdapter
          .toDbStatus(
            fakeUniqueRemoteRemoteId: fakeUniqueRemoteRemoteId,
          )
          .copyWith(
            directConversationId: conversationIdInt,
            // ignore: no-equal-arguments
            conversationId: conversationIdInt,
          );

      localStatusId = await statusRepository.upsertInDbType(
        dbStatus,
      );

      await statusRepository.addStatusToConversation(
        statusRemoteId: fakeUniqueRemoteRemoteId,
        conversationRemoteId: chat.remoteId,
        batchTransaction: null,
      );

      idempotencyKey = fakeUniqueRemoteRemoteId;

      var inReplyToConversationIdSupported =
          unifediApiStatusService.isFeatureSupported(
        unifediApiStatusService.postStatusInReplyToConversationIdFeature,
      );

      var previewSupported = unifediApiStatusService.isFeatureSupported(
        unifediApiStatusService.postStatusPreviewFeature,
      );

      var expiresInSupported = unifediApiStatusService.isFeatureSupported(
        unifediApiStatusService.postStatusExpiresInFeature,
      );

      postStatus = postStatusData.toPostStatus(
        inReplyToConversationIdSupported: inReplyToConversationIdSupported,
        previewSupported: previewSupported,
        expiresInSupported: expiresInSupported,
      );
    }

    try {
      var unifediApiStatus = await unifediApiStatusService.postStatus(
        idempotencyKey: idempotencyKey,
        postStatus: postStatus,
      );

      var conversationChatMessageStatusAdapter =
          unifediApiStatus.toConversationChatMessageStatusAdapter();
      var dbStatusPopulatedWrapper = conversationChatMessageStatusAdapter.status
          .toDbStatusPopulatedWrapper();
      onMessageLocallyHiddenStreamController.add(
        conversationChatMessageStatusAdapter.copyWith(
          status: dbStatusPopulatedWrapper.copyWith(
            dbStatusPopulated:
                dbStatusPopulatedWrapper.dbStatusPopulated.copyWith(
              dbStatus:
                  dbStatusPopulatedWrapper.dbStatusPopulated.dbStatus.copyWith(
                remoteId: dbStatus.remoteId,
              ),
            ),
          ),
        ),
      );

      await statusRepository.updateByDbIdInDbType(
        dbId: localStatusId,
        dbItem: dbStatus.copyWith(
          hiddenLocallyOnDevice: true,
          pendingState: PendingState.published,
        ),
        batchTransaction: null,
      );

      await statusRepository.upsertRemoteStatusForConversation(
        unifediApiStatus,
        conversationRemoteId: chat.remoteId,
        batchTransaction: null,
      );
      // ignore: avoid_catches_without_on_clauses
    } catch (e, stackTrace) {
      _logger.warning(() => 'postMessage error', e, stackTrace);
      await statusRepository.updateByDbIdInDbType(
        dbId: localStatusId,
        dbItem: dbStatus.copyWith(
          pendingState: PendingState.fail,
        ),
        batchTransaction: null,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage({
    required IConversationChatMessage conversationChatMessage,
  }) async {
    if (conversationChatMessage.isPendingStatePublishedOrNull) {
      await unifediApiStatusService.deleteStatus(
        statusId: conversationChatMessage.status.remoteId!,
      );

      await statusRepository.markStatusAsDeleted(
        statusRemoteId: conversationChatMessage.status.remoteId!,
      );
    } else {
      await statusRepository.markStatusAsHiddenLocallyOnDevice(
        localId: conversationChatMessage.status.localId!,
      );

      onMessageLocallyHiddenStreamController.add(conversationChatMessage);
    }
  }

  @override
  IConversationChatMessage? get lastPublishedChatMessage =>
      _lastPublishedMessageSubject.valueOrNull;

  @override
  bool get isDeletePossible => true;
}
