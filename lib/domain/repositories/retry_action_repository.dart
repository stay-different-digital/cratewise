import '../models/retry_action.dart';

abstract interface class RetryActionRepository {
  Future<void> add(RetryAction action);
  Future<List<RetryAction>> getAll();
  Future<RetryAction?> getById(String id);
  Future<List<RetryAction>> getPending();
  Future<void> update(RetryAction action);
  Future<void> remove(String id);
}
