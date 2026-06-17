import '../../domain/repositories/retry_action_repository.dart';

class PurgeStaleFailedActionsUseCase {
  PurgeStaleFailedActionsUseCase({
    required this._retryRepo,
    this._ttl = const Duration(days: 30),
  });

  final RetryActionRepository _retryRepo;
  final Duration _ttl;

  Future<void> execute() async {
    final cutoff = DateTime.now().subtract(_ttl);
    await _retryRepo.deleteFailedBefore(cutoff);
  }
}
