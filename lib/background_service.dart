import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Gère le service de premier plan (foreground service) qui protège
/// l'application pendant qu'une expédition est en cours : Android affiche
/// une notification permanente et ne tue pas le processus de l'app tant
/// que ce service tourne, même si l'utilisateur change d'application.
///
/// Le suivi GPS lui-même continue d'être géré normalement dans
/// ExpeditionScreen (isolate principal) — ce service ne fait pas le
/// tracking, il sert uniquement à garder le processus vivant et à
/// afficher la notification.
class ExpeditionForegroundService {
  static bool _initialized = false;
  static const int _serviceId = 1000;

  /// À appeler une seule fois avant le premier démarrage du service.
  static void init() {
    if (_initialized) return;
    _initialized = true;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'expedition_service',
        channelName: "Suivi d'expédition",
        channelDescription:
            "Notification affichée pendant qu'une expédition est en cours.",
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  /// Demande la permission d'affichage de notification (nécessaire sur
  /// Android 13+). À appeler une fois, par exemple au tout premier
  /// lancement de l'écran EXP.
  static Future<void> requestPermissions() async {
    final notifPermission = await FlutterForegroundTask.checkNotificationPermission();
    if (notifPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

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

  /// Met à jour uniquement le texte de la notification (ex: nombre de
  /// carrés collectés en direct), sans redémarrer le service.
  static Future<void> updateText(String text) async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(notificationText: text);
    }
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

// Le callback doit être une fonction de haut niveau (top-level), pas une
// méthode de classe : c'est une exigence du plugin, car elle est lancée
// dans un isolate séparé dédié au service.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_ExpeditionTaskHandler());
}

/// Handler minimal : il ne fait volontairement rien de particulier à
/// chaque "tick". Son seul rôle est de maintenir le service actif, ce qui
/// protège le processus de l'application contre l'arrêt forcé par le
/// système Android tant qu'une expédition est en cours.
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
