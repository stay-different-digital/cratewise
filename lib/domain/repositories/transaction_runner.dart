/// Runs a unit of work inside a single database transaction.
///
/// Used to batch many writes (e.g. importing thousands of rows) into one
/// commit instead of one implicit transaction per insert: far faster, and
/// all-or-nothing if the app is interrupted mid-import.
abstract interface class TransactionRunner {
  Future<T> run<T>(Future<T> Function() action);
}
