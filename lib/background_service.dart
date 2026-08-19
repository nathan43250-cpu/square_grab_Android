import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Gère le service de premier plan (Foreground Service) Android.
/// Indispensable pour continuer à recevoir des mises à jour GPS précises 
/// même lorsque l'utilisateur met l'application en arrière-plan ou éteint son écran.
class ExpeditionForegroundService {
  static bool _initialized = false;
  static const int _serviceId = 1000;

  /// Configure les paramètres du service (canaux de notification, options Android/iOS).
  static void init() {
    if (_initialized) return;
    _initialized = true;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'expedition_service',
        channelName: "Suivi d'expédition",
        channelDescription:
            "Notification affichée pendant qu'une expédition est en cours.",
        onlyAlertOnce: true, // Évite de faire vibrer le téléphone à chaque mise à jour du texte.
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000), // Intervalle de répétition interne.
        autoRunOnBoot: false,
        allowWakeLock: true,   // Empêche le CPU de s'endormir complètement.
        allowWifiLock: false,
      ),
    );
  }

  /// Demande explicitement la permission d'afficher des notifications (obligatoire sur Android 13+).
  static Future<void> requestPermissions() async {
    final notifPermission = await FlutterForegroundTask.checkNotificationPermission();
    if (notifPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  /// Démarre le service. Si déjà lancé, met à jour les textes de la notification.
  static Future<void> start({required String title, required String text}) async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
      return;
    }
    await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: title,
      notificationText: text,
      callback: startCallback,
    );
  }

  /// Met à jour uniquement le texte descriptif de la notification (ex: nombre de carrés).
  static Future<void> updateText(String text) async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(notificationText: text);
    }
  }

  /// Arrête définitivement le service et supprime la notification.
  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

/// Point d'entrée obligatoire pour le handler de tâche (doit être top-level et @pragma).
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_ExpeditionTaskHandler());
}

/// Handler gérant les événements du service en arrière-plan.
/// Pour cette application, on utilise principalement le service pour son aspect "Keep Alive"
/// et non pour effectuer des calculs lourds séparés du thread UI.
class _ExpeditionTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}
