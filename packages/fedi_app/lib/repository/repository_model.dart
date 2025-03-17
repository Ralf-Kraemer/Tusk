import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:drift/drift.dart' as drift;

part 'repository_model.freezed.dart';

@freezed
class RepositoryPagination<T> with _$RepositoryPagination<T> {
  const RepositoryPagination._();
  const factory RepositoryPagination({
    T? newerThanItem,
    T? olderThanItem,
    int? limit,
    int? offset,
  }) = _RepositoryPagination<T>;
}

abstract class RepositoryOrderingTerm {
  drift.OrderingMode get orderingMode;

  const RepositoryOrderingTerm();
}
