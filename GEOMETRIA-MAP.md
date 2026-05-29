# Карта страниц · Наглядная геометрия (`/school/geometria`)

Source-of-truth index of the **`/school/geometria`** sub-series («Курс наглядной
геометрии»). Built like the `map/` node dataset, but as a human-readable doc.

- **Derived from** the module grid in `school/geometria.html` (lines 317–403), the
  authoritative hub — re-generate this doc if that grid changes.
- **Drives** the per-page edit task: each *module chapter* page should read
  `Наглядная геометрия · M#` in the logo caption and send «← к модулям» to
  `/school/geometria` (today they say `Геометрия Шарыгина · M#` and point at
  `/school/sharygin-pokolenia`).

## Сводка

- **10 модулей** (M1–M10), **56 ссылок** в гриде = **10 глав + 46 подразделов**
  («10 глав · 46 подразделов», как и заявлено в шапке грида).
- **На диске 55 файлов; 1 отсутствует** → ⚠ `M7 → /school/princip-kavaleri`
  ссылается на несуществующий `school/princip-kavaleri.html` (битая ссылка в гриде).
- **Два типа страниц, две схемы:**
  - **Глава** (chapter, 10 шт.): логотип-подпись `<a class="brand" href=…>` ⇒
    текст `Геометрия Шарыгина · M#`, ссылка → `/school/sharygin-pokolenia`;
    в шапке есть отдельная навигация `← к модулям` (тоже → `sharygin-pokolenia`).
  - **Подраздел** (углубление, 46 шт.): подпись `Углубление · <название>`,
    логотип → *родительская глава* (не sharygin, не geometria).
- **M10 уже приведён к целевому виду** ✅ — `naglyadnye-professii` показывает
  `Наглядная геометрия · M10` и ведёт логотипом на `/school/geometria`.
  Это эталон; задача — сделать M1–M9 такими же.
- «Геометрия Шарыгина» встречается и в `<title>` / `<meta>` / подвале **всех**
  страниц — это *не* логотип-подпись и в задачу про «logo caption» не входит.

Легенда: **гл** = глава · **пр** = подраздел · ✓ = есть «к модулям» · ⚠ = нет файла

## Объём правок (что меняется)

| Что | Где сейчас | Цель | Кол-во |
|---|---|---|---|
| Логотип-подпись | `Геометрия Шарыгина · M#` (главы M1–M9) | `Наглядная геометрия · M#` | **9** |
| «← к модулям» link | → `/school/sharygin-pokolenia` (главы M1–M9) | → `/school/geometria` | **9** |
| Логотип `href` главы | → `/school/sharygin-pokolenia` (M1–M9) | → `/school/geometria` *(как у M10)* | 9 *(подтвердить)* |
| M10 (`naglyadnye-professii`) | уже `Наглядная геометрия · M10` → `/school/geometria` | — | 0 ✅ |
| Подразделы (46) | `Углубление · <название>`, → родительская глава | *вне явного объёма задачи* | — *(подтвердить)* |
| ⚠ `princip-kavaleri` | в гриде M7, файла нет | создать страницу или убрать ссылку | 1 |

> Открытый вопрос для этапа правок: применять «Наглядная геометрия» только к 10
> главам-модулям (чисто, M10 = эталон), или также как-то к 46 подразделам (у них
> сейчас осмысленная подпись `Углубление · <название>`).

---

## M1 · От Евклида — в будущее
- **гл** [/school/ot-evklida-v-budushchee](school/ot-evklida-v-budushchee.html) — лого `Геометрия Шарыгина · M1` → `sharygin-pokolenia` · ✓ к-модулям → `sharygin-pokolenia`
- пр [/school/neevklidova-revolyutsiya](school/neevklidova-revolyutsiya.html) — Неевклидова революция · ← ot-evklida-v-budushchee
- пр [/school/dekart-koordinaty](school/dekart-koordinaty.html) — Декарт: координаты · ← ot-evklida-v-budushchee
- пр [/school/naglyadnaya-geometriya](school/naglyadnaya-geometriya.html) — Наглядная геометрия Шарыгина · ← ot-evklida-v-budushchee

## M2 · Вспомогательные построения
- **гл** [/school/vspomogatelnye-postroeniya](school/vspomogatelnye-postroeniya.html) — лого `Геометрия Шарыгина · M2` → `sharygin-pokolenia` · ✓ к-модулям → `sharygin-pokolenia`
- пр [/school/vspomogatelnaya-okruzhnost](school/vspomogatelnaya-okruzhnost.html) — Вспомогательная окружность · ← vspomogatelnye-postroeniya
- пр [/school/simmetriya-povorot](school/simmetriya-povorot.html) — Симметрия и поворот · ← vspomogatelnye-postroeniya
- пр [/school/dostroit-do-figury](school/dostroit-do-figury.html) — Достроить до фигуры · ← vspomogatelnye-postroeniya

## M3 · Циркуль и линейка
- **гл** [/school/cirkul-i-linejka](school/cirkul-i-linejka.html) — лого `Геометрия Шарыгина · M3` → `sharygin-pokolenia` · ✓ к-модулям → `sharygin-pokolenia`
- пр [/school/bazovye-postroeniya](school/bazovye-postroeniya.html) — Базовые построения · ← cirkul-i-linejka
- пр [/school/zolotoe-sechenie](school/zolotoe-sechenie.html) — Золотое сечение и правильные многоугольники · ← cirkul-i-linejka
- пр [/school/nerazreshimye-zadachi](school/nerazreshimye-zadachi.html) — Неразрешимые задачи · ← cirkul-i-linejka

## M4 · Пространственное мышление
- **гл** [/school/prostranstvennoe-myshlenie](school/prostranstvennoe-myshlenie.html) — лого `Геометрия Шарыгина · M4` → `sharygin-pokolenia` · ✓ к-модулям → `sharygin-pokolenia`
- пр [/school/myslennoe-vrashchenie](school/myslennoe-vrashchenie.html) — Мысленное вращение · ← prostranstvennoe-myshlenie
- пр [/school/teni-i-proekcii](school/teni-i-proekcii.html) — Тени и проекции · ← prostranstvennoe-myshlenie
- пр [/school/razvyortka-v-3d](school/razvyortka-v-3d.html) — От развёртки к 3D · ← prostranstvennoe-myshlenie

## M5 · Углы и расстояния в пространстве
- **гл** [/school/ugly-i-rasstoyaniya](school/ugly-i-rasstoyaniya.html) — лого `Геометрия Шарыгина · M5` → `sharygin-pokolenia` · ✓ к-модулям → `sharygin-pokolenia`
- пр [/school/dvugrannyj-ugol](school/dvugrannyj-ugol.html) — Двугранный угол · ← ugly-i-rasstoyaniya
- пр [/school/rasstoyaniya-v-prostranstve](school/rasstoyaniya-v-prostranstve.html) — Расстояния в пространстве · ← ugly-i-rasstoyaniya
- пр [/school/apofema-i-proekciya](school/apofema-i-proekciya.html) — Апофема и проекция · ← ugly-i-rasstoyaniya

## M6 · Тела и развёртки
- **гл** [/school/tela-i-razvyortki](school/tela-i-razvyortki.html) — лого `Геометрия Шарыгина · M6` → `sharygin-pokolenia` · ✓ к-модулям → `sharygin-pokolenia`
- пр [/school/formula-eylera](school/formula-eylera.html) — Формула Эйлера · ← tela-i-razvyortki
- пр [/school/pyat-pravilnyh-tel](school/pyat-pravilnyh-tel.html) — Пять правильных тел · ← tela-i-razvyortki
- пр [/school/prizmy-i-piramidy](school/prizmy-i-piramidy.html) — Призмы и пирамиды · ← tela-i-razvyortki
- пр [/school/razvyortki-mnogogrannikov](school/razvyortki-mnogogrannikov.html) — Развёртки многогранников · ← tela-i-razvyortki
- пр [/school/poluravilnye-tela](school/poluravilnye-tela.html) — Полуправильные тела · ← tela-i-razvyortki

## M7 · Метод следов
- **гл** [/school/metod-sledov](school/metod-sledov.html) — лого `Геометрия Шарыгина · M7` → `sharygin-pokolenia` · ✓ к-модулям → `sharygin-pokolenia`
- пр [/school/secheniya-kuba](school/secheniya-kuba.html) — Сечения куба · ← metod-sledov
- пр [/school/postroenie-metodom-sledov](school/postroenie-metodom-sledov.html) — Построение методом следов · ← metod-sledov
- пр [/school/secheniya-prizm-piramid](school/secheniya-prizm-piramid.html) — Сечения призм и пирамид · ← metod-sledov
- пр [/school/konicheskie-secheniya](school/konicheskie-secheniya.html) — Конические сечения · ← metod-sledov
- пр [/school/ploshchad-i-perimetr-secheniya](school/ploshchad-i-perimetr-secheniya.html) — Площадь и периметр сечения · ← metod-sledov
- пр [/school/secheniya-v-zadachah-vuzov](school/secheniya-v-zadachah-vuzov.html) — Сечения в задачах вузов · ← metod-sledov
- пр **⚠ /school/princip-kavaleri** — Принцип Кавальери · **файла нет** (битая ссылка в гриде M7)

## M8 · Начертательная геометрия
- **гл** [/school/nachertatelnaya-geometriya](school/nachertatelnaya-geometriya.html) — лого `Геометрия Шарыгина · M8` → `sharygin-pokolenia` · ✓ к-модулям → `sharygin-pokolenia`
- пр [/school/epyur-monzha](school/epyur-monzha.html) — Эпюр Монжа · ← nachertatelnaya-geometriya
- пр [/school/tri-vida](school/tri-vida.html) — Три вида · ← nachertatelnaya-geometriya
- пр [/school/razrezy-i-secheniya](school/razrezy-i-secheniya.html) — Разрезы и сечения · ← nachertatelnaya-geometriya
- пр [/school/aksonometriya](school/aksonometriya.html) — Аксонометрия · ← nachertatelnaya-geometriya
- пр [/school/peresechenie-poverhnostej](school/peresechenie-poverhnostej.html) — Пересечение поверхностей · ← nachertatelnaya-geometriya
- пр [/school/oformlenie-chertezha](school/oformlenie-chertezha.html) — Оформление чертежа · ← nachertatelnaya-geometriya
- пр [/school/perspektiva](school/perspektiva.html) — Перспектива · ← nachertatelnaya-geometriya

## M9 · От наглядности к вузу
- **гл** [/school/ot-naglyadnosti-k-vuzu](school/ot-naglyadnosti-k-vuzu.html) — лого `Геометрия Шарыгина · M9` → `sharygin-pokolenia` · ✓ к-модулям → `sharygin-pokolenia`
- пр [/school/vpisannyj-ugol](school/vpisannyj-ugol.html) — Вписанный угол · ← ot-naglyadnosti-k-vuzu
- пр [/school/stereometriya-na-ekzamene](school/stereometriya-na-ekzamene.html) — Стереометрия на экзамене · ← ot-naglyadnosti-k-vuzu
- пр [/school/kak-iskat-reshenie](school/kak-iskat-reshenie.html) — Как искать решение · ← ot-naglyadnosti-k-vuzu
- пр [/school/metod-koordinat](school/metod-koordinat.html) — Метод координат · ← ot-naglyadnosti-k-vuzu
- пр [/school/vektory-v-geometrii](school/vektory-v-geometrii.html) — Векторы в геометрии · ← ot-naglyadnosti-k-vuzu
- пр [/school/zadachi-s-issledovaniem](school/zadachi-s-issledovaniem.html) — Задачи с исследованием · ← ot-naglyadnosti-k-vuzu
- пр [/school/trigonometriya-v-geometrii](school/trigonometriya-v-geometrii.html) — Тригонометрия в геометрии · ← ot-naglyadnosti-k-vuzu

## M10 · Наглядные профессии ✅ *(эталон — уже в целевом виде)*
- **гл** [/school/naglyadnye-professii](school/naglyadnye-professii.html) — лого `Наглядная геометрия · M10` → `/school/geometria` ✅ *(нет отдельного текста «к модулям»)*
- пр [/school/geometriya-dlya-programmista](school/geometriya-dlya-programmista.html) — Геометрия для программиста · ← naglyadnye-professii
- пр [/school/geometriya-dlya-arhitektora](school/geometriya-dlya-arhitektora.html) — Геометрия для архитектора · ← naglyadnye-professii
- пр [/school/geometriya-dlya-inzhenera](school/geometriya-dlya-inzhenera.html) — Геометрия для инженера · ← naglyadnye-professii
- пр [/school/geometriya-dlya-fotografa](school/geometriya-dlya-fotografa.html) — Геометрия для фотографа · ← naglyadnye-professii
- пр [/school/geometriya-v-dizajne](school/geometriya-v-dizajne.html) — Геометрия в дизайне и вёрстке · ← naglyadnye-professii
