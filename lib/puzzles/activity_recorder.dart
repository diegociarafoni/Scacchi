import '../progress/activity.dart';
import '../progress/progress_tracker.dart';

/// Registra un'attività nella gamification e restituisce l'aggiornamento.
typedef ActivityRecorder = Future<ProgressUpdate?> Function(Activity activity);
