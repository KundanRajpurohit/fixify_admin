import 'dart:async';
import 'package:fixify_admin/helpers/job_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JobTimerNotifier extends StateNotifier<JobTimerState> {
  JobTimerNotifier() : super(JobTimerState.initial);

  Timer? _timer;

  void start() {
    if (state.isRunning) return;

    final startTime = DateTime.now();

    state = state.copyWith(
      isRunning: true,
      startedAt: startTime,
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(startTime);
      state = state.copyWith(elapsed: elapsed);
    });
  }

  void stop() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    state = JobTimerState.initial;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final jobTimerProvider =
    StateNotifierProvider<JobTimerNotifier, JobTimerState>(
  (ref) => JobTimerNotifier(),
);
