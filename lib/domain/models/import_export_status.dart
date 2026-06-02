enum ImportExportStatus {
  /// Job has been created but not yet started.
  idle,

  /// Validating source data before running the job.
  validating,

  /// Generating a preview of what will be imported or exported.
  previewing,

  /// Job is actively running.
  running,

  /// Job completed successfully with no errors.
  completed,

  /// Job completed but some rows were skipped or failed.
  completedWithErrors,

  /// Job failed entirely and could not complete.
  failed,

  /// Job was cancelled before completion.
  cancelled,
}
