import 'language_controller.dart';

/// Petit dictionnaire de traductions.
class AppTranslations {
  static const Map<String, Map<AppLanguage, String>> _dictionary = {
    'settings_title': {
      AppLanguage.fr: 'Paramètres',
      AppLanguage.en: 'Settings',
      AppLanguage.zh: '设置',
    },
    'language_label': {
      AppLanguage.fr: 'Langue',
      AppLanguage.en: 'Language',
      AppLanguage.zh: '语言',
    },

    // Navigation
    'exp_tab': {
      AppLanguage.fr: 'EXP',
      AppLanguage.en: 'EXP',
      AppLanguage.zh: '探险',
    },
    'map_tab': {
      AppLanguage.fr: 'MAP',
      AppLanguage.en: 'MAP',
      AppLanguage.zh: '地图',
    },
    'rule_tab': {
      AppLanguage.fr: 'RULE',
      AppLanguage.en: 'RULE',
      AppLanguage.zh: '规则',
    },

    // Onglet EXP
    'expedition_running': {
      AppLanguage.fr: 'Expédition en cours...',
      AppLanguage.en: 'Expedition in progress...',
      AppLanguage.zh: '探险进行中...',
    },
    'expedition_ready': {
      AppLanguage.fr: 'Prêt pour une expédition ?',
      AppLanguage.en: 'Ready for an expedition?',
      AppLanguage.zh: '准备好探险了吗？',
    },
    'start_expedition': {
      AppLanguage.fr: "Démarrer l'expédition",
      AppLanguage.en: 'Start expedition',
      AppLanguage.zh: '开始探险',
    },
    'stop_expedition': {
      AppLanguage.fr: "Terminer l'expédition",
      AppLanguage.en: 'End expedition',
      AppLanguage.zh: '结束探险',
    },
    'stat_squares': {
      AppLanguage.fr: 'carrés',
      AppLanguage.en: 'squares',
      AppLanguage.zh: '方块',
    },
    'location_off_title': {
      AppLanguage.fr: 'Position indisponible.',
      AppLanguage.en: 'Position unavailable.',
      AppLanguage.zh: '无法获取位置。',
    },
    'retry_button': {
      AppLanguage.fr: 'Réessayer',
      AppLanguage.en: 'Retry',
      AppLanguage.zh: '重试',
    },
    'gps_disabled_error': {
      AppLanguage.fr: 'Le GPS est désactivé sur ton téléphone.',
      AppLanguage.en: 'GPS is disabled on your phone.',
      AppLanguage.zh: '手机的GPS已关闭。',
    },
    'permission_denied_error': {
      AppLanguage.fr: 'Permission de localisation refusée.',
      AppLanguage.en: 'Location permission denied.',
      AppLanguage.zh: '位置权限被拒绝。',
    },
    'location_permission_snackbar': {
      AppLanguage.fr: 'Permission de localisation requise.',
      AppLanguage.en: 'Location permission required.',
      AppLanguage.zh: '需要位置权限。',
    },
    'no_squares_snackbar': {
      AppLanguage.fr: 'Aucun carré parcouru pendant cette expédition.',
      AppLanguage.en: 'No squares covered during this expedition.',
      AppLanguage.zh: '本次探险没有经过任何方块。',
    },
    'transport_prompt_title': {
      AppLanguage.fr: 'Quel moyen de transport as-tu utilisé ?',
      AppLanguage.en: 'Which transport did you use?',
      AppLanguage.zh: '你使用了什么交通方式？',
    },
    'position_error': {
      AppLanguage.fr: 'Impossible de récupérer ta position.',
      AppLanguage.en: 'Unable to get your position.',
      AppLanguage.zh: '无法获取你的位置。',
    },
    'gps_tracking_error': {
      AppLanguage.fr: 'Erreur GPS pendant le suivi.',
      AppLanguage.en: 'GPS error during tracking.',
      AppLanguage.zh: '追踪过程中GPS出错。',
    },
    'expedition_result': {
      AppLanguage.fr: '{count} nouveau(x) carré(s) collecté(s) en {mode} !',
      AppLanguage.en: '{count} new square(s) collected by {mode}!',
      AppLanguage.zh: '通过{mode}收集了{count}个新方块！',
    },
    'stat_squares_count': {
      AppLanguage.fr: '{count} carrés',
      AppLanguage.en: '{count} squares',
      AppLanguage.zh: '{count} 个方块',
    },
    'stat_total_squares': {
      AppLanguage.fr: 'Total : {count}',
      AppLanguage.en: 'Total: {count}',
      AppLanguage.zh: '总计：{count}',
    },
    'notification_title': {
      AppLanguage.fr: 'Expédition en cours',
      AppLanguage.en: 'Expedition in progress',
      AppLanguage.zh: '探险进行中',
    },
    'notification_text': {
      AppLanguage.fr: '{count} carrés collectés — appuie pour revenir à l\'app',
      AppLanguage.en: '{count} squares collected — tap to return to the app',
      AppLanguage.zh: '已收集{count}个方块 — 点击返回应用',
    },
    'legend_title': {
      AppLanguage.fr: 'Progression',
      AppLanguage.en: 'Progress',
      AppLanguage.zh: '进度',
    },

    // Onglet MAP
    'map_title': {
      AppLanguage.fr: 'Ta carte — {count} carré(s)',
      AppLanguage.en: 'Your map — {count} square(s)',
      AppLanguage.zh: '你的地图 — {count} 个方块',
    },

    // Modes de transport
    'transport_walk': {
      AppLanguage.fr: 'Marche / Course',
      AppLanguage.en: 'Walk / Run',
      AppLanguage.zh: '步行/跑步',
    },
    'transport_bike': {
      AppLanguage.fr: 'Vélo',
      AppLanguage.en: 'Bike',
      AppLanguage.zh: '自行车',
    },
    'transport_car': {
      AppLanguage.fr: 'Voiture',
      AppLanguage.en: 'Car',
      AppLanguage.zh: '汽车',
    },
  };

  static String t(String key, AppLanguage language) {
    return _dictionary[key]?[language] ?? key;
  }

  /// Traduit une clé ET remplace le placeholder {count} par une valeur.
  /// Exemple d'usage : tCount('map_title', lang, cells.length)
  static String tCount(String key, AppLanguage language, int count) {
    final template = t(key, language);
    return template.replaceAll('{count}', count.toString());
  }

  /// Traduit une clé et remplace plusieurs placeholders à la fois.
  /// Exemple : tVars('expedition_result', lang, {'count': '3', 'mode': 'Vélo'})
  static String tVars(String key, AppLanguage language, Map<String, String> vars) {
    var result = t(key, language);
    for (final entry in vars.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }
}
