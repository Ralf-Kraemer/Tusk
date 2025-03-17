import 'package:fedi_app/repository/repository_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:drift/drift.dart' as drift;

part 'conversation_chat_repository_model.freezed.dart';

@freezed
class ConversationChatRepositoryFilters
    with _$ConversationChatRepositoryFilters {
  static const ConversationChatRepositoryFilters empty =
      ConversationChatRepositoryFilters();

  const ConversationChatRepositoryFilters._();
  const factory ConversationChatRepositoryFilters({
    @Default(false) bool withLastMessage,
  }) = _ConversationChatRepositoryFilters;
}

enum ConversationChatOrderType {
  remoteId,
  updatedAt,
}

@freezed
class ConversationRepositoryChatOrderingTermData
    with _$ConversationRepositoryChatOrderingTermData
    implements RepositoryOrderingTerm {
  const factory ConversationRepositoryChatOrderingTermData({
    required ConversationChatOrderType orderType,
    required drift.OrderingMode orderingMode,
  }) = _ConversationRepositoryChatOrderingTermData;

  static const ConversationRepositoryChatOrderingTermData remoteIdDesc =
      ConversationRepositoryChatOrderingTermData(
    orderingMode: drift.OrderingMode.desc,
    orderType: ConversationChatOrderType.remoteId,
  );
  static const ConversationRepositoryChatOrderingTermData remoteIdAsc =
      ConversationRepositoryChatOrderingTermData(
    orderingMode: drift.OrderingMode.asc,
    orderType: ConversationChatOrderType.remoteId,
  );

  static const ConversationRepositoryChatOrderingTermData updatedAtDesc =
      ConversationRepositoryChatOrderingTermData(
    orderingMode: drift.OrderingMode.desc,
    orderType: ConversationChatOrderType.updatedAt,
  );
  static const ConversationRepositoryChatOrderingTermData updatedAtAsc =
      ConversationRepositoryChatOrderingTermData(
    orderingMode: drift.OrderingMode.asc,
    orderType: ConversationChatOrderType.updatedAt,
  );

  static const List<ConversationRepositoryChatOrderingTermData> defaultTerms = [
    updatedAtDesc,
  ];
}
