import 'models.dart';
import 'day_models.dart';

class ReadingMaterial {
  const ReadingMaterial(
    this.id,
    this.genre,
    this.titles,
    this.paragraphs,
    this.questions,
    this.answers,
  );
  final String id, genre;
  final List<String> titles;

  /// Each language has three independently navigable paragraphs.
  final List<List<String>> paragraphs;
  final List<List<String>> questions, answers;
  int index(AppLanguage l) => switch (l) {
    AppLanguage.english => 0,
    AppLanguage.kazakh => 1,
    AppLanguage.russian => 2,
  };
  String title(AppLanguage l) => titles[index(l)];
  List<String> text(AppLanguage l) => paragraphs[index(l)];
  String bookId(AppLanguage l) => '$id:${l.name}';
  Map<String, String> metadata(AppLanguage l) => {
    'title': title(l),
    'author': 'ÖmirAI',
    'language': localized(l, 'English', 'Қазақша', 'Русский'),
    'translator': localized(
      l,
      'ÖmirAI — original localized edition',
      'ÖmirAI — төл аударылған басылым',
      'ÖmirAI — оригинальное переведённое издание',
    ),
    'source': localized(
      l,
      'Bundled ÖmirAI original material $id',
      'Қолданбадағы ÖmirAI төл материалы $id',
      'Встроенный оригинальный материал ÖmirAI $id',
    ),
    'rightsStatus': localized(
      l,
      'Original ÖmirAI material',
      'ÖmirAI төл материалы',
      'Оригинальный материал ÖmirAI',
    ),
    'license': localized(
      l,
      'Included for reading in ÖmirAI',
      'ÖmirAI ішінде оқуға арналған',
      'Для чтения в ÖmirAI',
    ),
    'edition': '1, 2026',
    'publicationPermission': localized(
      l,
      'Original material created for this ÖmirAI release',
      'ÖmirAI қолданбасының осы нұсқасына арналған төл материал',
      'Оригинальный материал для этой версии ÖmirAI',
    ),
  };
}

const readingLibrary = <ReadingMaterial>[
  ReadingMaterial(
    'window-garden',
    'stories',
    ['The window garden', 'Терезе алдындағы бақ', 'Сад на подоконнике'],
    [
      [
        'Amina placed three empty pots by the window. She filled one with mint, one with beans, and one with a flower seed. She wrote a small label for each pot so that she would remember what was growing.',
        'Each morning she turned the pots a little. The new leaves leaned toward the light. Her grandson drew their shapes in a notebook. The bean leaves were broad; the mint leaves had tiny edges like the teeth of a comb.',
        'After a week, the flower pot still looked empty. Amina left it in place and continued to care for it. On Saturday a green tip appeared. They added a new drawing to the notebook.',
      ],
      [
        'Әмина терезе алдына үш құмыра қойды. Біріне жалбыз, екіншісіне бұршақ, үшіншісіне гүл тұқымын екті. Не өсіп жатқанын есте сақтау үшін әр құмыраға белгі жапсырды.',
        'Ол күнде таңертең құмыраларды сәл бұрып қоятын. Жас жапырақтар жарыққа қарай иілді. Немересі олардың суретін дәптерге салды. Бұршақтың жапырағы жалпақ, ал жалбыз жапырағының жиегі тарақтың тісіндей еді.',
        'Бір аптадан кейін гүл құмырасында әлі ештеңе көрінбеді. Әмина оны күте берді. Сенбі күні кішкентай жасыл өскін шықты. Дәптерге тағы бір сурет қосылды.',
      ],
      [
        'Амина поставила у окна три горшка. В один она посадила мяту, в другой фасоль, а в третий семечко цветка. На каждом горшке появилась подпись, чтобы помнить, что в нём растёт.',
        'Каждое утро она немного поворачивала горшки. Молодые листья тянулись к свету. Внук рисовал их в тетради. Листья фасоли были широкими, а края листьев мяты напоминали зубчики расчёски.',
        'Через неделю горшок с цветком всё ещё казался пустым. Амина продолжала ухаживать за ним. В субботу показался зелёный кончик. В тетради появился новый рисунок.',
      ],
    ],
    [
      ['Where were the pots?', 'What appeared on Saturday?'],
      ['Құмыралар қайда тұрды?', 'Сенбіде не пайда болды?'],
      ['Где стояли горшки?', 'Что появилось в субботу?'],
    ],
    [
      ['By the window', 'A green shoot'],
      ['Терезе алдында', 'Жасыл өскін'],
      ['У окна', 'Зелёный росток'],
    ],
  ),
  ReadingMaterial(
    'bench',
    'stories',
    ['A place to sit', 'Демалатын орын', 'Место для отдыха'],
    [
      [
        'On his usual walk, Marat noticed that a park bench had been moved. It now faced a row of young trees instead of the road. He sat down and listened to the leaves.',
        'A neighbour joined him with a paper bag of apples. They talked about the changing park. Marat remembered when the trees had been no taller than the bench. His neighbour remembered the first summer flowers.',
        'Before leaving, they found a fallen apple beside the bag. The neighbour put it back and offered Marat another one. The walk had taken the same route as always, but the new view gave them something different to discuss.',
      ],
      [
        'Марат серуен кезінде саябақтағы орындықтың орны ауысқанын байқады. Енді ол жолға емес, жас ағаштарға қарап тұрды. Марат отырып, жапырақтардың сыбдырын тыңдады.',
        'Қағаз қапшыққа алма салып алған көршісі келді. Олар саябақ туралы әңгімелесті. Марат ағаштардың орындықтан да аласа болған кезін есіне алды. Көршісі алғашқы жазғы гүлдерді еске түсірді.',
        'Кетерде қапшықтың жанынан түсіп қалған алма тапты. Көршісі оны орнына салып, Маратқа басқа алма ұсынды. Жол бұрынғыдай еді, бірақ жаңа көрініс әңгімеге арқау болды.',
      ],
      [
        'На привычной прогулке Марат заметил, что скамейку переставили. Теперь она смотрела на молодые деревья, а не на дорогу. Он сел и послушал шелест листьев.',
        'Рядом устроился сосед с бумажным пакетом яблок. Они заговорили о парке. Марат помнил, как деревья были ниже скамейки. Сосед вспомнил первые летние цветы.',
        'Перед уходом они заметили выпавшее яблоко. Сосед положил его обратно, а другое предложил Марату. Маршрут остался прежним, но новый вид дал им новую тему для разговора.',
      ],
    ],
    [
      ['What had moved?', 'What did the neighbour carry?'],
      ['Ненің орны ауысты?', 'Көршісі не әкелді?'],
      ['Что переставили?', 'Что принёс сосед?'],
    ],
    [
      ['A bench', 'Apples'],
      ['Орындықтың', 'Алма'],
      ['Скамейку', 'Яблоки'],
    ],
  ),
  ReadingMaterial(
    'recipe',
    'culture',
    ['The recipe card', 'Рецепт жазылған қағаз', 'Карточка с рецептом'],
    [
      [
        'Dana found a recipe card between two books. The handwriting belonged to her aunt. There were instructions for a simple soup, but the last line said only: taste and decide.',
        'Dana set out a carrot, an onion, and a small bowl of lentils. She read each instruction before moving to the next. Beside the quantities, her aunt had drawn a tiny spoon.',
        'When the soup was ready, Dana wrote the date on the back of the card. She added her own note: I used the blue pot. Next time she would not have to remember every detail. The card now held a small piece of both their days.',
      ],
      [
        'Дана екі кітаптың арасынан рецепт жазылған қағаз тапты. Жазу апасына тиесілі еді. Онда қарапайым көже дайындау жолы берілген. Соңғы жолда: дәмін татып, өзің шеш деп жазылыпты.',
        'Дана сәбіз, пияз және жасымық салынған ыдысты дайындады. Әр қадамды бастамас бұрын нұсқауды оқыды. Мөлшерлердің қасына апасы кішкентай қасықтың суретін салыпты.',
        'Көже дайын болғанда, Дана қағаздың сыртына күнін жазды. Көк қазанды қолдандым деген белгі қосты. Келесі жолы барлық ұсақ-түйекті есте сақтаудың қажеті болмайды.',
      ],
      [
        'Дана нашла между книгами карточку с рецептом. Почерк принадлежал её тёте. На карточке был простой суп, а последняя строка гласила: попробуй и реши сама.',
        'Дана приготовила морковь, луковицу и миску чечевицы. Перед каждым шагом она читала инструкцию. Рядом с количеством продуктов тётя нарисовала маленькую ложку.',
        'Когда суп был готов, Дана поставила дату на обороте. Она добавила: я использовала синюю кастрюлю. В следующий раз не придётся помнить каждую мелочь. Теперь карточка хранила частичку дня каждой из них.',
      ],
    ],
    [
      ['Who wrote the recipe?', 'What colour was the pot?'],
      ['Рецептті кім жазды?', 'Қазанның түсі қандай?'],
      ['Кто написал рецепт?', 'Какого цвета была кастрюля?'],
    ],
    [
      ['Dana’s aunt', 'Blue'],
      ['Дананың апасы', 'Көк'],
      ['Тётя Даны', 'Синяя'],
    ],
  ),
  ReadingMaterial(
    'map',
    'travel',
    ['A map for a visitor', 'Қонаққа арналған карта', 'Карта для гостя'],
    [
      [
        'Timur wanted to show a visitor his neighbourhood. Instead of listing street names, he drew a map with three landmarks: the bakery, the library, and the bridge.',
        'The visitor followed the smell of fresh bread to the bakery. At the library, she noticed a bright yellow door. The bridge came last, just beyond a quiet square.',
        'That evening she added a yellow rectangle to Timur’s map. He added a small loaf beside the bakery. Their map was not useful for measuring distance, but it was full of things they had actually noticed.',
      ],
      [
        'Тимур қонаққа өз ауданын көрсеткісі келді. Көше атауларын жазудың орнына үш белгісі бар карта салды: наубайхана, кітапхана және көпір.',
        'Қонақ жаңа нанның иісімен наубайханаға жетті. Кітапханадан ашық сары есікті байқады. Тыныш алаңнан кейін көпірге келді.',
        'Кешке қонақ картаға сары төртбұрыш қосты. Тимур наубайхананың жанына нанның суретін салды. Бұл карта қашықтық өлшеуге арналмаса да, олардың байқаған нәрселерін сақтады.',
      ],
      [
        'Тимур хотел показать гостье свой район. Вместо названий улиц он нарисовал карту с тремя ориентирами: пекарней, библиотекой и мостом.',
        'Запах свежего хлеба привёл гостью к пекарне. У библиотеки она заметила яркую жёлтую дверь. Мост оказался за тихой площадью.',
        'Вечером гостья добавила на карту жёлтый прямоугольник. Тимур нарисовал хлеб рядом с пекарней. Карта не годилась для измерения расстояний, зато сохраняла то, что они действительно заметили.',
      ],
    ],
    [
      [
        'How many landmarks were on the map?',
        'What colour was the library door?',
      ],
      ['Картада неше белгі болды?', 'Кітапхана есігінің түсі қандай?'],
      ['Сколько ориентиров было на карте?', 'Какого цвета была дверь?'],
    ],
    [
      ['Three', 'Yellow'],
      ['Үш', 'Сары'],
      ['Три', 'Жёлтая'],
    ],
  ),
  ReadingMaterial(
    'shadow',
    'science',
    ['Watching a shadow', 'Көлеңкені бақылау', 'Наблюдая за тенью'],
    [
      [
        'Lena placed a cup on the balcony table in the morning. Its shadow stretched across a sheet of paper. She traced the edge with a pencil and wrote down the time.',
        'At midday she returned to the same table. The cup had not moved, but its shadow had changed. She used a different pencil to trace the new shape.',
        'In the evening the paper held three outlines. Lena did not need special equipment to compare them. Keeping the cup in the same place had made the changes easier to see. Tomorrow she planned to observe the shadow of a taller object.',
      ],
      [
        'Лена таңертең балкондағы үстелге кесе қойды. Оның көлеңкесі қағазға түсті. Ол көлеңкенің шетін қарындашпен сызып, уақытын жазды.',
        'Түсте Лена қайта келді. Кесе қозғалмаған, бірақ көлеңкесі өзгерген еді. Жаңа пішінді басқа қарындашпен белгіледі.',
        'Кешке қағазда үш сұлба болды. Оларды салыстыруға арнайы құрал қажет емес еді. Кесенің бір орында тұруы өзгерісті байқауды жеңілдетті. Ертең ол биігірек заттың көлеңкесін бақыламақ.',
      ],
      [
        'Утром Лена поставила чашку на балконный стол. Тень легла на лист бумаги. Она обвела край карандашом и записала время.',
        'В полдень Лена вернулась. Чашка не двигалась, а тень изменилась. Новую форму она обвела другим карандашом.',
        'К вечеру на бумаге было три контура. Для сравнения не понадобились специальные приборы. Чашка оставалась на месте, поэтому перемены было легче заметить. Завтра Лена решила наблюдать за тенью более высокого предмета.',
      ],
    ],
    [
      ['What object made the shadow?', 'Did the cup move?'],
      ['Қай заттың көлеңкесі түсті?', 'Кесе қозғалды ма?'],
      ['Какой предмет отбрасывал тень?', 'Чашка двигалась?'],
    ],
    [
      ['A cup', 'No'],
      ['Кесенің', 'Жоқ'],
      ['Чашка', 'Нет'],
    ],
  ),
  ReadingMaterial(
    'thread',
    'culture',
    ['The blue thread', 'Көк жіп', 'Синяя нить'],
    [
      [
        'Saule opened a box of sewing supplies. There were buttons, needles, and a blue thread wound around a piece of cardboard. The cardboard still carried part of an old greeting.',
        'She needed to repair a cloth bag. Before sewing, she placed the buttons in a small dish so none would roll away. The blue thread matched the stripe along the bag’s edge.',
        'When she finished, she wound the remaining thread back onto the card. The repaired bag would go with her to the market. She kept the old greeting in the box, where it had quietly become part of an everyday tool.',
      ],
      [
        'Сәуле тігін қорабын ашты. Ішінде түймелер, инелер және қатырма қағазға оралған көк жіп бар еді. Қағазда ескі құттықтаудың бір бөлігі сақталыпты.',
        'Оған мата сөмкені жөндеу керек болды. Түймелер домалап кетпесін деп, оларды кішкентай ыдысқа салды. Көк жіп сөмкенің шетіндегі жолаққа сәйкес келді.',
        'Жұмысы біткен соң қалған жіпті қағазға қайта орады. Жөнделген сөмкемен базарға бармақ. Ескі құттықтау күнделікті құралдың бір бөлшегіне айналып, қорапта қалды.',
      ],
      [
        'Сауле открыла коробку для шитья. Там были пуговицы, иголки и синяя нить на кусочке картона. На картоне сохранилась часть старого поздравления.',
        'Нужно было починить тканевую сумку. Сауле положила пуговицы в блюдце, чтобы они не раскатились. Синяя нить подходила к полоске по краю сумки.',
        'Закончив работу, она намотала остаток нити на карточку. С починенной сумкой можно идти на рынок. Старое поздравление осталось в коробке, став частью обычного инструмента.',
      ],
    ],
    [
      ['What needed repair?', 'Where did Saule put the buttons?'],
      ['Нені жөндеу керек еді?', 'Түймелерді қайда салды?'],
      ['Что нужно было починить?', 'Куда Сауле положила пуговицы?'],
    ],
    [
      ['A cloth bag', 'In a dish'],
      ['Мата сөмкені', 'Ыдысқа'],
      ['Тканевую сумку', 'В блюдце'],
    ],
  ),
  ReadingMaterial(
    'station',
    'travel',
    ['The early train', 'Ерте пойыз', 'Ранний поезд'],
    [
      [
        'Arman arrived at the station early. He checked the platform number and found a seat near a large window. Outside, a worker watered flowers in long wooden boxes.',
        'Arman had brought a book, but first he watched the station wake up. A family counted their bags. A cleaner moved a trolley. The clock above the door clicked forward.',
        'When the train was announced, Arman checked his ticket once more. He put the book into the front pocket of his bag so it would be easy to reach. The quiet wait had become the first part of his journey.',
      ],
      [
        'Арман вокзалға ерте келді. Платформа нөмірін тексеріп, үлкен терезенің жанына отырды. Сыртта жұмысшы ағаш жәшіктердегі гүлдерге су құйып жүрді.',
        'Арман кітап әкелген еді, бірақ алдымен вокзалдың тіршілігін бақылады. Бір отбасы сөмкелерін санады. Тазалықшы арбасын жылжытты. Есіктің үстіндегі сағат алға жүрді.',
        'Пойыз туралы хабарланғанда, Арман билетін тағы тексерді. Кітапты оңай алу үшін сөмкесінің алдыңғы қалтасына салды. Тыныш күту сапарының алғашқы бөлігіне айналды.',
      ],
      [
        'Арман пришёл на вокзал заранее. Он проверил номер платформы и сел у большого окна. Снаружи работник поливал цветы в деревянных ящиках.',
        'Арман принёс книгу, но сначала наблюдал за вокзалом. Семья считала сумки. Уборщик передвигал тележку. Часы над дверью отсчитывали время.',
        'Когда объявили поезд, Арман ещё раз проверил билет. Книгу он положил в передний карман сумки, чтобы легко достать. Спокойное ожидание стало первой частью путешествия.',
      ],
    ],
    [
      ['Where did Arman sit?', 'Where did he put his book?'],
      ['Арман қайда отырды?', 'Кітабын қайда салды?'],
      ['Где сел Арман?', 'Куда он положил книгу?'],
    ],
    [
      ['Near a window', 'In the front pocket'],
      ['Терезе жанына', 'Алдыңғы қалтаға'],
      ['У окна', 'В передний карман'],
    ],
  ),
  ReadingMaterial(
    'rain',
    'stories',
    ['After the rain', 'Жаңбырдан кейін', 'После дождя'],
    [
      [
        'The rain stopped just before lunch. Vera opened the door to the courtyard. Small pools of water reflected the sky, and the stone path looked darker than usual.',
        'She noticed a paper boat beside the steps. A child had folded it from a sheet covered in pencil marks. Vera set the boat in a shallow pool and watched it turn slowly.',
        'A breeze pushed the boat toward the edge. The child came back with another sheet of paper and showed Vera how to make a wider base. Together they compared the two boats before bringing both inside to dry.',
      ],
      [
        'Түскі ас алдында жаңбыр тоқтады. Вера аула есігін ашты. Шалшықтардан аспан көрініп, тас жол әдеттегіден күңгірт болып тұрды.',
        'Баспалдақ жанынан қағаз қайық байқады. Бала оны қарындаш іздері бар қағаздан бүктеген екен. Вера қайықты таяз шалшыққа жіберіп, баяу бұрылғанын қарады.',
        'Самал қайықты шетке итерді. Бала тағы қағаз әкеліп, түбін кеңірек жасауды көрсетті. Екеуі қайықтарды салыстырып, кептіру үшін үйге алып кірді.',
      ],
      [
        'Дождь закончился перед обедом. Вера открыла дверь во двор. В лужах отражалось небо, а каменная дорожка казалась темнее обычного.',
        'У ступенек лежал бумажный кораблик. Ребёнок сложил его из листа с карандашными линиями. Вера опустила кораблик в мелкую лужу и посмотрела, как он поворачивается.',
        'Ветерок подтолкнул кораблик к краю. Ребёнок вернулся с новым листом и показал Вере, как сделать дно шире. Они сравнили два кораблика и забрали их домой сушиться.',
      ],
    ],
    [
      ['What reflected the sky?', 'What did they bring inside?'],
      ['Аспан неден көрінді?', 'Үйге не алып кірді?'],
      ['Где отражалось небо?', 'Что они забрали домой?'],
    ],
    [
      ['Pools of water', 'Two paper boats'],
      ['Шалшықтардан', 'Екі қағаз қайық'],
      ['В лужах', 'Два бумажных кораблика'],
    ],
  ),
  ReadingMaterial(
    'notebook',
    'stories',
    ['One line a day', 'Күніне бір жол', 'Одна строка в день'],
    [
      [
        'Nurlan bought a small notebook with a plain cover. He decided to write one thing he noticed each day. The first entry was short: a red bicycle beside the gate.',
        'On Tuesday he wrote about the smell of bread. On Wednesday he described a conversation with his brother. Some entries were only a few words; others filled half a page.',
        'At the end of the week he read the notes aloud to himself. He had not recorded every task or every hour. The notebook simply held seven details that might otherwise have blended into one another.',
      ],
      [
        'Нұрлан қарапайым мұқабалы шағын дәптер сатып алды. Күн сайын байқаған бір нәрсесін жазуға шешім қабылдады. Алғашқы жазбасы қысқа болды: қақпа жанындағы қызыл велосипед.',
        'Сейсенбіде нанның иісін жазды. Сәрсенбіде ағасымен әңгімесін сипаттады. Кей жазбалар бірнеше сөзден тұрды, басқалары жарты бетті толтырды.',
        'Апта соңында жазбаларын дауыстап оқыды. Ол әр істі немесе әр сағатты тіркемеген еді. Дәптерде бір-бірімен араласып кетуі мүмкін жеті ерекше сәт сақталды.',
      ],
      [
        'Нурлан купил маленькую тетрадь с простой обложкой. Он решил каждый день записывать что-нибудь замеченное. Первая запись была короткой: красный велосипед у ворот.',
        'Во вторник он написал о запахе хлеба. В среду описал разговор с братом. Одни записи занимали несколько слов, другие — полстраницы.',
        'В конце недели он прочитал заметки вслух. Он не записывал каждое дело или каждый час. Тетрадь сохранила семь деталей, которые иначе могли бы смешаться друг с другом.',
      ],
    ],
    [
      [
        'What colour was the bicycle?',
        'How many daily details did the notebook hold?',
      ],
      ['Велосипедтің түсі қандай?', 'Дәптерде неше сәт сақталды?'],
      ['Какого цвета был велосипед?', 'Сколько деталей сохранила тетрадь?'],
    ],
    [
      ['Red', 'Seven'],
      ['Қызыл', 'Жеті'],
      ['Красный', 'Семь'],
    ],
  ),
  ReadingMaterial(
    'stones',
    'science',
    ['Sorting stones', 'Тастарды сұрыптау', 'Сортируем камни'],
    [
      [
        'Mira placed six clean stones on a tray. First she arranged them from small to large. Then she tried a different arrangement, putting smooth stones on one side and rough stones on the other.',
        'One large stone was also very smooth. It had belonged at the end of the first row, but now it sat beside a much smaller stone. The stones had not changed; the rule had.',
        'Mira drew both arrangements on paper. She gave each drawing a title so she could explain it later. Looking at the same collection in two ways had revealed different similarities.',
      ],
      [
        'Мира алты таза тасты науаға салды. Алдымен кішісінен үлкеніне қарай тізді. Кейін тегіс тастарды бір жаққа, кедір-бұдыр тастарды екінші жаққа қойды.',
        'Бір үлкен тас өте тегіс еді. Алғашқы қатардың соңында тұрған ол енді кішкентай тастың жанында жатты. Тастар өзгерген жоқ, тек сұрыптау ережесі өзгерді.',
        'Мира екі ретті де қағазға салды. Кейін түсіндіру үшін әр суретке атау берді. Бір жинаққа екі түрлі қарау басқа ұқсастықтарды көрсетті.',
      ],
      [
        'Мира положила на поднос шесть чистых камней. Сначала она разложила их от маленького к большому. Затем отделила гладкие камни от шероховатых.',
        'Один большой камень был очень гладким. Раньше он стоял в конце ряда, а теперь лежал рядом с маленьким. Камни не изменились — изменилось правило.',
        'Мира нарисовала оба варианта и дала рисункам названия, чтобы позже объяснить их. Два способа посмотреть на одну коллекцию показали разные сходства.',
      ],
    ],
    [
      [
        'How many stones were there?',
        'What changed: the stones or the sorting rule?',
      ],
      ['Неше тас болды?', 'Тастар өзгерді ме, ереже ме?'],
      ['Сколько было камней?', 'Что изменилось: камни или правило?'],
    ],
    [
      ['Six', 'The sorting rule'],
      ['Алты', 'Ереже'],
      ['Шесть', 'Правило'],
    ],
  ),
  ReadingMaterial(
    'teacups',
    'culture',
    ['Four different cups', 'Төрт түрлі кесе', 'Четыре разные чашки'],
    [
      [
        'For an afternoon visit, Aliya put four cups on the table. They did not match. One had a blue rim, one was plain white, one had a flower, and one was taller than the rest.',
        'Each visitor chose a cup. The flowered one reminded a friend of her grandmother’s kitchen. The tall one was comfortable for someone who liked a large handle.',
        'Aliya had once thought she needed a matching set. Now the different cups gave everyone an easy choice and started a conversation. After washing them, she put all four together on the same shelf.',
      ],
      [
        'Әлия қонақтарға төрт кесе дайындады. Олар әртүрлі еді: бірінің жиегі көк, бірі ақ, бірінде гүл бар, ал біреуі басқалардан биік болатын.',
        'Әр қонақ өз кесесін таңдады. Гүлді кесе құрбысына әжесінің асүйін еске салды. Үлкен тұтқаны ұнататын қонаққа биік кесе ыңғайлы болды.',
        'Әлия бұрын бірдей кесе жинағы керек деп ойлайтын. Енді әртүрлі кеселер таңдау жасауға және әңгіме бастауға көмектесті. Жуып болған соң төртеуін бір сөреге қойды.',
      ],
      [
        'Алия поставила для гостей четыре разные чашки. У одной был синий ободок, другая была белой, третья с цветком, а четвёртая выше остальных.',
        'Каждый выбрал чашку. Цветок напомнил подруге о бабушкиной кухне. Высокая чашка понравилась гостю, которому была удобна большая ручка.',
        'Раньше Алия думала, что нужен одинаковый сервиз. Теперь разные чашки помогли каждому сделать выбор и начать разговор. После мытья она поставила все четыре на одну полку.',
      ],
    ],
    [
      [
        'How many cups were on the table?',
        'What reminded a visitor of her grandmother?',
      ],
      ['Үстелде неше кесе болды?', 'Қонаққа әжесін не еске салды?'],
      ['Сколько чашек было на столе?', 'Что напомнило гостье о бабушке?'],
    ],
    [
      ['Four', 'The flowered cup'],
      ['Төрт', 'Гүлді кесе'],
      ['Четыре', 'Чашка с цветком'],
    ],
  ),
  ReadingMaterial(
    'evening',
    'poetry',
    ['Evening light', 'Кешкі жарық', 'Вечерний свет'],
    [
      [
        'A square of light upon the floor,\nA quiet cup beside the door,\nThe curtain moves, then rests again,\nBeyond the glass, the sound of rain.',
        'A book lies open where I read,\nNo other page is what I need.\nI keep my place, I close the day,\nAnd put the folded cloth away.',
        'Tomorrow brings another view,\nA different sky, a task or two.\nFor now the room is soft and still,\nWith evening gathered on the sill.',
      ],
      [
        'Еденде жарық төртбұрыш,\nЕсік түбінде кесе тұр.\nПерде қозғалып, тынады,\nТерезеден жаңбыр үні естіледі.',
        'Оқыған кітабым ашық жатыр,\nБүгінге осы бет жеткілікті.\nОқыған жерімді белгілеймін,\nБүктелген матаны жинаймын.',
        'Ертең басқа көрініс келер,\nӨзге аспан, бір-екі іс күтер.\nАл қазір бөлме тыныш,\nТерезе алды кешкі жарыққа толы.',
      ],
      [
        'На полу квадрат из света,\nЧашка возле двери где-то.\nШтора движется едва,\nЗа стеклом дождя слова.',
        'Книга ждёт на прежнем месте,\nС ней мы день закончим вместе.\nЯ закладку положу,\nТкань на полку уберу.',
        'Завтра будет вид иной,\nНебо новое со мной.\nА пока покой вокруг,\nВечер сел на подоконник вдруг.',
      ],
    ],
    [
      ['What can be heard outside?', 'What helps keep the reading place?'],
      ['Сырттан не естіледі?', 'Оқыған орынды не сақтайды?'],
      ['Что слышно снаружи?', 'Что сохраняет место в книге?'],
    ],
    [
      ['Rain', 'A bookmark'],
      ['Жаңбыр', 'Белгі'],
      ['Дождь', 'Закладка'],
    ],
  ),
];

String genreLabel(String genre, AppLanguage l) => switch (genre) {
  'stories' => localized(l, 'Stories', 'Әңгімелер', 'Рассказы'),
  'culture' => localized(l, 'Culture', 'Мәдениет', 'Культура'),
  'travel' => localized(l, 'Travel', 'Саяхат', 'Путешествия'),
  'science' => localized(l, 'Science', 'Ғылым', 'Наука'),
  _ => localized(l, 'Poetry', 'Поэзия', 'Поэзия'),
};
