import 'models.dart';

/// Links to hosted performances; no third-party lyrics or audio are bundled.
/// See docs/sing-catalog.md for source and verification notes.
class SongRecording {
  const SongRecording(
    this.id,
    this.title,
    this.transliteration,
    this.language,
    this.videoId,
    this.performer, {
    this.alternatives = const [],
  });
  final String id, title, transliteration, videoId, performer;
  final AppLanguage language;
  final List<SongPerformance> alternatives;
  String get videoUrl => 'https://www.youtube.com/watch?v=$videoId';
  bool matches(String query) {
    final value = query.trim().toLowerCase();
    return '$title $transliteration $performer'.toLowerCase().contains(value);
  }
}

class SongPerformance {
  const SongPerformance(this.videoId, this.performer);
  final String videoId, performer;
  String get videoUrl => 'https://www.youtube.com/watch?v=$videoId';
}

const songRecordings = <SongRecording>[
  SongRecording(
    'yapurai',
    'Япурай',
    'Yapurai',
    AppLanguage.kazakh,
    'YOy09eVGZTM',
    'Бекболат Тілеухан',
  ),
  SongRecording(
    'dudarai',
    'Дударай',
    'Dudarai',
    AppLanguage.kazakh,
    'Y4_UpbgH6vQ',
    'Роза Рымбаева',
    alternatives: [SongPerformance('tJ6a7oMULjM', 'Алиса Супронова')],
  ),
  SongRecording(
    'balqadisha',
    'Балқадиша',
    'Balqadisha',
    AppLanguage.kazakh,
    'isOln_AnnNA',
    'Тлеужан',
  ),
  SongRecording(
    'bir-bala',
    'Бір бала',
    'Bir Bala',
    AppLanguage.kazakh,
    'yrM01U6vhjM',
    'Балаларға арналған әндер',
  ),
  SongRecording(
    'qamajai',
    'Қамажай',
    'Qamajai',
    AppLanguage.kazakh,
    '00zSwKH8hpk',
    'Дауыс International',
  ),
  SongRecording(
    'elim-ai',
    'Елім-ай',
    'Elim-ai',
    AppLanguage.kazakh,
    'IUbiiko_3iU',
    'Өмірқұл Айниязов',
  ),
  SongRecording(
    'bipyl',
    'Бипыл',
    'Bipyl',
    AppLanguage.kazakh,
    'rZNlUtx4oCA',
    'Жамал Омарова',
  ),
  SongRecording(
    'guilderaiym',
    'Гүлдерайым',
    'Guilderaiym',
    AppLanguage.kazakh,
    'e4k8HELTzx4',
    'Айнұр Иманқызы',
  ),
  SongRecording(
    'daididau',
    'Дайдидау',
    'Daididau',
    AppLanguage.kazakh,
    'bvx7g70SIrg',
    'Дінмұхаммед Қайрат',
  ),
  SongRecording(
    'samaltau',
    'Самалтау',
    'Samaltau',
    AppLanguage.kazakh,
    '1NkoFc-bQ_s',
    'Димаш Құдайберген',
    alternatives: [SongPerformance('OLrFs0WRxgY', 'Димаш Құдайберген · 2021')],
  ),
  SongRecording(
    'kalinka',
    'Калинка',
    'Kalinka',
    AppLanguage.russian,
    'bobTxw_VJOM',
    'Вадим Ананьев',
  ),
  SongRecording(
    'korobeiniki',
    'Коробейники',
    'Korobeiniki',
    AppLanguage.russian,
    'KeurN5I-c6I',
    'Леонид Сметанников',
  ),
  SongRecording(
    'iz-za-ostrova',
    'Из-за острова на стрежень',
    'Iz-za ostrova na strezhen',
    AppLanguage.russian,
    'neB-Ns-CnUM',
    'Надежда Кадышева',
  ),
  SongRecording(
    'troika',
    'Вот мчится тройка почтовая',
    'Vot mchitsya troika pochtovaya',
    AppLanguage.russian,
    'Pqqinwbw6Bg',
    'Иван Скобцов',
  ),
  SongRecording(
    'ey-ukhnem',
    'Эй, ухнем',
    'Ey ukhnem',
    AppLanguage.russian,
    'eE-Q6RH_Zzk',
    'Леонид Харитонов',
  ),
  SongRecording(
    'dubinushka',
    'Дубинушка',
    'Dubinushka',
    AppLanguage.russian,
    'xeLxsBpzYDg',
    'Фёдор Шаляпин',
  ),
  SongRecording(
    'za-morem-sinichka',
    'За морем синичка',
    'Za morem sinichka',
    AppLanguage.russian,
    'ysDQMic86Fw',
    'Валерия Геллерт',
  ),
  SongRecording(
    'svetit-mesiats',
    'Светит месяц',
    'Svetit mesiats',
    AppLanguage.russian,
    'WQ-tBW5Abxg',
    'Жанна Бичевская, Бисер Киров, Дин Рид',
  ),
  SongRecording(
    'vanka',
    'Ванька холостой',
    'Vanka',
    AppLanguage.russian,
    '-nrd02DGQmM',
    'Русская песня',
  ),
  SongRecording(
    'vo-pole-bereza',
    'Во поле берёза стояла',
    'Vo pole bereza stoyala',
    AppLanguage.russian,
    'Ck00bzX1trA',
    'ВЕК',
  ),
];
