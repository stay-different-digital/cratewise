import '../../domain/repositories/transaction_runner.dart';
import 'app_database.dart';

/// [TransactionRunner] backed by the Drift [AppDatabase]. Every repository
/// write issued inside [run] joins the same transaction, since all
/// repositories share this database instance.
class DatabaseTransactionRunner implements TransactionRunner {
  DatabaseTransactionRunner(this._db);

  final AppDatabase _db;

  @override
  Future<T> run<T>(Future<T> Function() action) => _db.transaction(action);
}
