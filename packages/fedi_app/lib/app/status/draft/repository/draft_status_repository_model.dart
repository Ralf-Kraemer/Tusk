import 'package:fedi_app/repository/repository_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:drift/drift.dart' as drift;

part 'draft_status_repository_model.freezed.dart';

@freezed
class DraftStatusRepositoryFilters with _$DraftStatusRepositoryFilters {
  static const DraftStatusRepositoryFilters empty =
      DraftStatusRepositoryFilters();

  const factory DraftStatusRepositoryFilters() = _DraftStatusRepositoryFilters;
}

enum DraftStatusRepositoryOrderType {
  localId,
  updatedAt,
}

@freezed
class DraftStatusRepositoryOrderingTermData
    with _$DraftStatusRepositoryOrderingTermData
    implements RepositoryOrderingTerm {
  const DraftStatusRepositoryOrderingTermData._();

  const factory DraftStatusRepositoryOrderingTermData({
    required DraftStatusRepositoryOrderType orderType,
    required drift.OrderingMode orderingMode,
  }) = _DraftStatusRepositoryOrderingTermData;

  static const DraftStatusRepositoryOrderingTermData localIdDesc =
      DraftStatusRepositoryOrderingTermData(
    orderingMode: drift.OrderingMode.desc,
    orderType: DraftStatusRepositoryOrderType.localId,
  );
  static const DraftStatusRepositoryOrderingTermData localIdAsc =
      DraftStatusRepositoryOrderingTermData(
    orderingMode: drift.OrderingMode.asc,
    orderType: DraftStatusRepositoryOrderType.localId,
  );
  static const DraftStatusRepositoryOrderingTermData updatedAtDesc =
      DraftStatusRepositoryOrderingTermData(
    orderingMode: drift.OrderingMode.desc,
    orderType: DraftStatusRepositoryOrderType.updatedAt,
  );
  static const DraftStatusRepositoryOrderingTermData updatedAtAsc =
      DraftStatusRepositoryOrderingTermData(
    orderingMode: drift.OrderingMode.asc,
    orderType: DraftStatusRepositoryOrderType.updatedAt,
  );

  static const List<DraftStatusRepositoryOrderingTermData> defaultTerms = [
    updatedAtDesc,
  ];
}
