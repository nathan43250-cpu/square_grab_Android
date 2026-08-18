import 'language_controller.dart';

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

    'ressayer_bouton': {
      AppLanguage.fr: 'ressayer',
      AppLanguage.en: 'retry',
      AppLanguage.zh: '重试',
    },

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

static String tCount(String key, AppLanguage language, int count) {
  final template = t(key, language);
  return template.replaceAll('{count}', count.toString());
}
  static String t(String key, AppLanguage language) {
    return _dictionary[key]?[language] ?? key;
  }
}