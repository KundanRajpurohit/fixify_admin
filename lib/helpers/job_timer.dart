class JobTimerState {
  final bool isRunning;
  final Duration elapsed;
  final DateTime? startedAt;

  const JobTimerState({
    required this.isRunning,
    required this.elapsed,
    this.startedAt,
  });

  JobTimerState copyWith({
    bool? isRunning,
    Duration? elapsed,
    DateTime? startedAt,
  }) {
    return JobTimerState(
      isRunning: isRunning ?? this.isRunning,
      elapsed: elapsed ?? this.elapsed,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  static const initial = JobTimerState(
    isRunning: false,
    elapsed: Duration.zero,
  );
}
