import 'package:fedi_app/repository/repository_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:drift/drift.dart' as drift;

part 'unifedi_chat_repository_model.freezed.dart';

@freezed
class UnifediChatRepositoryFilters with _$UnifediChatRepositoryFilters {
  static const UnifediChatRepositoryFilters empty =
      UnifediChatRepositoryFilters();

  const UnifediChatRepositoryFilters._();

  const factory UnifediChatRepositoryFilters({
    @Default(false) bool withLastMessage,
  }) = _UnifediChatRepositoryFilters;
}

enum UnifediChatOrderType {
  remoteId,
  updatedAt,
}

@freezed
class UnifediChatRepositoryOrderingTermData
    with _$UnifediChatRepositoryOrderingTermData
    implements RepositoryOrderingTerm {
  const UnifediChatRepositoryOrderingTermData._();

  const factory UnifediChatRepositoryOrderingTermData({
    required UnifediChatOrderType orderType,
    required drift.OrderingMode orderingMode,
  }) = _UnifediChatRepositoryOrderingTermData;

  static const UnifediChatRepositoryOrderingTermData remoteIdDesc =
      UnifediChatRepositoryOrderingTermData(
    orderingMode: drift.OrderingMode.desc,
    orderType: UnifediChatOrderType.remoteId,
  );
  static const UnifediChatRepositoryOrderingTermData remoteIdAsc =
      UnifediChatRepositoryOrderingTermData(
    orderingMode: drift.OrderingMode.asc,
    orderType: UnifediChatOrderType.remoteId,
  );

  static const UnifediChatRepositoryOrderingTermData updatedAtDesc =
      UnifediChatRepositoryOrderingTermData(
    orderingMode: drift.OrderingMode.desc,
    orderType: UnifediChatOrderType.updatedAt,
  );
  static const UnifediChatRepositoryOrderingTermData updatedAtAsc =
      UnifediChatRepositoryOrderingTermData(
    orderingMode: drift.OrderingMode.asc,
    orderType: UnifediChatOrderType.updatedAt,
  );

  static const List<UnifediChatRepositoryOrderingTermData> defaultTerms = [
    updatedAtDesc,
  ];
}
