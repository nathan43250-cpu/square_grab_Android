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

    // Onglet RULE
    'how_to_play_title': {
      AppLanguage.fr: 'Comment jouer',
      AppLanguage.en: 'How to play',
      AppLanguage.zh: '游戏方法',
    },
    'rule_step_1_title': {
      AppLanguage.fr: 'Démarre une expédition',
      AppLanguage.en: 'Start an expedition',
      AppLanguage.zh: '开始探险',
    },
    'rule_step_1_text': {
      AppLanguage.fr: "Va dans l'onglet EXP et appuie sur \"Démarrer l'expédition\".",
      AppLanguage.en: 'Go to the EXP tab and tap "Start expedition".',
      AppLanguage.zh: '前往"探险"标签，点击"开始探险"。',
    },
    'rule_step_2_title': {
      AppLanguage.fr: 'Déplace-toi',
      AppLanguage.en: 'Move around',
      AppLanguage.zh: '开始移动',
    },
    'rule_step_2_text': {
      AppLanguage.fr:
          'Chaque case de ~200m que tu traverses dans le monde réel est enregistrée automatiquement.',
      AppLanguage.en:
          'Every ~200m square you cross in the real world is automatically recorded.',
      AppLanguage.zh: '你在现实世界中经过的每个约200米方格都会被自动记录。',
    },
    'rule_step_3_title': {
      AppLanguage.fr: "Termine l'expédition",
      AppLanguage.en: 'End the expedition',
      AppLanguage.zh: '结束探险',
    },
    'rule_step_3_text': {
      AppLanguage.fr: 'Appuie sur "Terminer" et choisis le moyen de transport que tu as utilisé.',
      AppLanguage.en: 'Tap "End" and choose the transport you used.',
      AppLanguage.zh: '点击"结束"并选择你使用的交通方式。',
    },
    'rule_step_4_title': {
      AppLanguage.fr: 'Récupère tes carrés',
      AppLanguage.en: 'Claim your squares',
      AppLanguage.zh: '获得你的方块',
    },
    'rule_step_4_text': {
      AppLanguage.fr: 'Les carrés parcourus sont ajoutés à ta carte, colorés selon le transport choisi.',
      AppLanguage.en: 'Squares you crossed are added to your map, colored by the transport used.',
      AppLanguage.zh: '经过的方块会被添加到地图上，并根据所用交通方式着色。',
    },
    'rule_step_5_title': {
      AppLanguage.fr: 'La hiérarchie des couleurs',
      AppLanguage.en: 'The color hierarchy',
      AppLanguage.zh: '颜色等级',
    },
    'rule_step_5_text': {
      AppLanguage.fr:
          'Marche > Vélo > Voiture. Un carré ne change de couleur que si tu le retraverses avec un transport plus "actif" — jamais dans l\'autre sens.',
      AppLanguage.en:
          'Walk > Bike > Car. A square only changes color if you cross it again with a more "active" transport — never the other way around.',
      AppLanguage.zh: '步行 > 自行车 > 汽车。只有用更"积极"的交通方式再次经过时，方块颜色才会改变——反之则不会。',
    },
    'color_legend_title': {
      AppLanguage.fr: 'Légende des couleurs',
      AppLanguage.en: 'Color legend',
      AppLanguage.zh: '颜色图例',
    },
    'color_legend_subtitle': {
      AppLanguage.fr: 'Priorité du plus fort au plus faible',
      AppLanguage.en: 'Priority from strongest to weakest',
      AppLanguage.zh: '优先级从高到低',
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
    'expedition_result_with_upgrade': {
      AppLanguage.fr: '{count} nouveau(x) + {upgraded} amélioré(s) en {mode} !',
      AppLanguage.en: '{count} new + {upgraded} upgraded, by {mode}!',
      AppLanguage.zh: '通过{mode}：{count}个新方块，{upgraded}个升级！',
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
