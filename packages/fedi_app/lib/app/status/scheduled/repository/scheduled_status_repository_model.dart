import 'package:fedi_app/repository/repository_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:drift/drift.dart' as drift;

part 'scheduled_status_repository_model.freezed.dart';

@freezed
class ScheduledStatusRepositoryFilters with _$ScheduledStatusRepositoryFilters {
  static const ScheduledStatusRepositoryFilters empty =
      ScheduledStatusRepositoryFilters();

  const factory ScheduledStatusRepositoryFilters({
    bool? excludeCanceled,
    bool? excludeScheduleAtExpired,
  }) = _ScheduledStatusRepositoryFilters;
}

enum ScheduledStatusRepositoryOrderType {
  remoteId,
}

@freezed
class ScheduledStatusRepositoryOrderingTermData
    with _$ScheduledStatusRepositoryOrderingTermData
    implements RepositoryOrderingTerm {
  const factory ScheduledStatusRepositoryOrderingTermData({
    required ScheduledStatusRepositoryOrderType orderType,
    required drift.OrderingMode orderingMode,
  }) = _ScheduledStatusRepositoryOrderingTermData;

  static const ScheduledStatusRepositoryOrderingTermData remoteIdDesc =
      ScheduledStatusRepositoryOrderingTermData(
    orderingMode: drift.OrderingMode.desc,
    orderType: ScheduledStatusRepositoryOrderType.remoteId,
  );
  static const ScheduledStatusRepositoryOrderingTermData remoteIdAsc =
      ScheduledStatusRepositoryOrderingTermData(
    orderingMode: drift.OrderingMode.asc,
    orderType: ScheduledStatusRepositoryOrderType.remoteId,
  );

  static const List<ScheduledStatusRepositoryOrderingTermData> defaultTerms = [
    remoteIdDesc,
  ];
}
