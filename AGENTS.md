# PortProton (PortWINE) - Документация для AI агентов

## Обзор проекта

**PortProton** (также известный как **PortWINE**) — это инструмент для Linux, предназначенный для упрощения запуска Windows-игр и приложений на Linux. Разрабатывается в основном русским сообществом линукс-геймеров (linux-gaming.ru).

Проект предоставляет:
- GUI-обёртку вокруг Wine/Proton для запуска Windows-исполняемых файлов
- Автоустановку в один клик для популярных игровых лаунчеров (Epic Games, Battle.net, Steam и др.)
- Преднастроенные эмуляторы для консольных игр
- Оптимизированные настройки для максимальной игровой производительности
- Интеграцию с MangoHud, vkBasalt, GameScope, dgVoodoo2, OptiScaler, lsfg-vk

**Официальный сайт:** https://linux-gaming.ru  
**Лицензия:** MIT License (Copyright 2026 Castro-Fidel)  
**Основной язык документации и комментариев:** Русский

### Статус проекта (важно!)

С версии скриптов 2481 (август 2026) проект находится в **режиме поддержки**: обновляется только для исправления критических ошибок. Основная разработка перенесена в **PortProtonQt** (https://github.com/linux-gaming-ru/PortProtonQt) — Qt-интерфейс, который использует CLI этого репозитория как бэкенд (`portproton cli ...`).

Следствия для агентов:
- Не ломать CLI-команды и формат их вывода (`--list-db`, `--show-ppdb`, `--get-user-conf` и т.д.) — от них зависит PortProtonQt
- Новые фичи GUI на YAD не приветствуются, приоритет — исправления и совместимость с PortProtonQt
- В changelog_en есть пометка «ATTENTION: PortProton is updated only to fix critical issues!»

## Технологический стек

| Компонент | Технология |
|-----------|------------|
| Основной язык | Bash (shell-скрипты) |
| GUI-фреймворк | YAD (Yet Another Dialog) с GTK, кастомная сборка `yad_gui_pp` |
| Трей-иконка | Кастомный бинарник `tray_gui_pp` |
| Windows-совместимость | Wine / Proton (форк Valve) / Proton-GE; сборки PROTON_LG и WINE_LG от linux-gaming.ru |
| Контейнер | Steam Linux Runtime (SLR, Sniper) через pressure-vessel + Bubblewrap |
| Графические API | Vulkan, OpenGL, DXVK (DirectX→Vulkan), VKD3D-Proton (DirectX 12→Vulkan), dxvk-nvapi |
| Оверлей-инструменты | MangoHud, vkBasalt, GameScope, OBS vkcapture |
| Апскейлеры | OptiScaler, lsfg-vk, WINE_FULLSCREEN_FSR |
| Загрузки | curl с зеркалами (CLOUD linux-gaming.ru / GITHUB) |
| Система сборки | Отсутствует (скриптовая, компиляция не требуется) |

## Структура репозитория

```
PortWINE/
├── data_from_portwine/           # Содержимое каталога data/ в установленном PortProton
│   ├── scripts/                  # Основные shell-скрипты
│   │   ├── start.sh              # Точка входа (~1220 строк)
│   │   ├── functions_helper      # Основная библиотека функций (~8300 строк, ~160 функций)
│   │   ├── var                   # Переменные по умолчанию + версии (SCRIPTS_*_VERSION)
│   │   ├── setup.sh              # Установка .desktop, миграция на flatpak
│   │   ├── add_in_steam.sh       # Добавление ярлыков в Steam (shortcuts.vdf, GPL-3.0, на базе steamtinkerlaunch)
│   │   ├── clear_db.sh           # Нормализация .ppdb в portwine_db/ (утилита мейнтейнера)
│   │   ├── portwine_db/          # ~200 преднастроек игр (*.ppdb)
│   │   ├── pw_autoinstall/       # ~70 скриптов автоустановки (PW_*)
│   │   └── thanks                # Файл благодарностей
│   ├── themes/                   # Темы GUI
│   │   ├── default/, classic/, compact/   # style.css (+ gif-анимации в classic/)
│   │   ├── *.pptheme             # Конфигурация темы (bash, source-ится)
│   │   ├── gui/yad_gui_pp        # Кастомный YAD (+ source/, COPYING.txt)
│   │   └── tray/tray_gui_pp      # Трей-иконка (+ source/, LICENSE.txt)
│   ├── locales/                  # Переводы (gettext)
│   │   ├── PortProton.pot        # Шаблон основных скриптов
│   │   ├── tray.pot              # Шаблон трея
│   │   └── {ru,es}/LC_MESSAGES/  # PortProton.po, tray.po, tray.mo
│   ├── img/                      # Иконки (gui/ — ~100 файлов PNG/SVG для YAD)
│   ├── changelog_en / changelog_ru
│   ├── dxvk.conf                 # Конфигурация DXVK (DXVK_CONFIG_FILE)
│   └── vkBasalt.conf
├── README.md / README-RU.md
├── AGENTS.md                     # Этот файл
└── LICENSE
```

## Структура установленного PortProton (runtime)

Скрипты из репозитория копируются в `$PORT_WINE_PATH/data/scripts/`. Остальное создаётся при запуске:

```
$PORT_WINE_PATH/                  # Корень установки (например ~/PortProton)
├── PortProton.log                # Лог запусков (PW_LOG_FILE)
├── scripts-debug.log             # Трейс при --debug
├── *.desktop                     # Ярлыки игр
├── steam_scripts/                # Обёртки для Steam
├── prefixes -> data/prefixes     # Симлинк
└── data/
    ├── scripts/                  # Содержимое data_from_portwine/scripts
    ├── user.conf                 # Пользовательские настройки (USER_CONF)
    ├── dist/                     # Версии Wine (PROTON_LG_10-28, WINE_LG_11-1, ...), имена в ВЕРХНЕМ регистре
    ├── prefixes/                 # Wine-префиксы (DEFAULT, DOTNET, ...), имена в ВЕРХНЕМ регистре
    └── tmp/                      # PORT_WINE_TMP_PATH
        ├── PortProton_ver, scripts_ver, PortProton_loc   # версия, версия скриптов, язык
        ├── VULKAN/               # DXVK/VKD3D (dxvk-<ver>, vkd3d-proton-<ver>)
        ├── plugins_v20/          # MangoHud, vkBasalt, xterm и др. (PW_PLUGINS_VER)
        ├── libs_v3.0.20260218/   # Steam Linux Runtime (PW_LIBS_VER)
        ├── cache_lang/           # Скомпилированные переводы (bash-массив translations)
        ├── gecko/, mono/         # Кеш Wine
        └── statistics, update_skip_mirror, update_remind_later
```

Временные файлы сессии: `/tmp/PortProton_$USER/` (PW_TMPFS_PATH): `portproton.lock`, `var.log` (дамп переменных при запуске), `process.log`, `tmp_yad_form`.

## Поток запуска

1. `start.sh`: проверка root, определение путей, `source functions_helper`, создание каталогов
2. Разбор `$1`: `.exe/.bat/.msi/.reg/.lnk` → `portwine_exe`; `.ppdb` → `update_ext_ppdb`; `.ppack` → распаковка префикса; `portproton://URL` → скачивание ppdb; `cli` → `PW_CLI=1`
3. `source var` → `check_user_conf` (source user.conf) → `check_translations` → source темы `.pptheme`
4. Выбор `BRANCH` (master/devel), `MIRROR` (CLOUD/GITHUB), проверка обновлений `pw_port_update` (не в CLI)
5. `pw_init_db` — поиск и загрузка `.ppdb` для `portwine_exe`
6. `pw_check_and_download_dxvk_and_vkd3d`, `pw_download_libs`
7. CLI: `case "$1"` по `--командам` → выход. GUI: главное меню YAD (`--notebook`), затем `case "$PW_YAD_SET"`
8. Запуск игры: `portwine_launch` → `start_portwine` (префикс, Wine, DXVK, runtime, env) → `pw_run` (запуск через SLR) → `stop_portwine` (очистка, ярлык, хуки)

Важные переменные среды, устанавливаемые на старте: `PORT_WINE_PATH`, `PORT_SCRIPTS_PATH`, `PORT_WINE_TMP_PATH`, `PW_TMPFS_PATH`, `PW_GUI_ICON_PATH`, `PW_GUI_THEMES_PATH`, `pw_yad`, `USER_CONF`, `WINEPREFIX` (в `start_portwine`).

### Режим совместимости Steam (steamplay)
Если задан `STEAM_COMPAT_DATA_PATH`, `start.sh` вызывает `steamplay_launch` — PortProton работает как compatibility tool внутри Steam (используется PortProtonQt).

## Ключевые скрипты и функции

### start.sh
- Обрабатывает аргументы и CLI-команды (см. ниже)
- Собирает главное меню YAD: вкладки INSTALLED / AUTOINSTALLS / EMULATORS / WINE SETTINGS / PORTPROTON SETTINGS
- Числовые коды `PW_YAD_SET` (98, 100, 102...) — это коды возврата кнопок YAD

### functions_helper (группы функций)
| Группа | Функции |
|--------|---------|
| Логирование | `print_info`, `print_warning`, `print_error`, `print_ok`, `print_var`, `fatal`, `process_log` |
| Файлы | `try_copy_file`, `try_copy_dir`, `try_remove_file`, `try_remove_dir`, `create_new_dir`, `try_force_link_file`, `try_force_link_dir`, `lsbash`, `unpack` |
| Переменные | `check_variables VAR default`, `set_several_variables`, `add_to_var`, `rm_from_var`, `add_to_array`, `rm_from_array`, `var_winedlloverride_update`, `var_vkd3d_config_update` |
| Загрузка | `try_download URL DEST [silent\|no_mirror]`, `try_check_sha256sum`, `pw_download_libs`, `pw_check_and_download_dxvk_and_vkd3d`, `pw_check_and_download_plugins`, `gui_proton_downloader` |
| Окружение | `check_flatpak`, `check_start_from_steam`, `check_gamescope_session`, `check_wayland_session`, `check_vendor_gpu`, `pw_check_vulkan`, `pw_check_dxvk`, `get_gpu_names`, `compare_versions` |
| База данных | `pw_init_db`, `edit_db_from_gui VAR...`, `gui_edit_db`, `update_ext_ppdb`, `find_ext_ppdb`, `pw_skip_get_info` |
| user.conf | `check_user_conf`, `edit_user_conf_from_gui VAR...`, `manage_user_conf_value get\|set\|delete` |
| Запуск | `start_portwine`, `pw_run`, `portwine_launch`, `stop_portwine`, `kill_portwine`, `init_wine_ver`, `pw_init_runtime`, `steamplay_launch` |
| Префиксы | `pw_clear_pfx`, `pw_prefix_manager` (winetricks), `pw_create_prefix_backup[_cli]`, `pw_unpack_prefix`, `pw_winecfg/winefile/winecmd/winereg` |
| GUI | `yad_info`, `yad_error`, `yad_question`, `pw_start_progress_bar_*`, `pw_stop_progress_bar`, `gui_mangohud`, `gui_vkbasalt`, `gui_dgvoodoo2`, `gui_gamescope`, `gui_userconf`, `pw_tray_icon` |
| Ярлыки | `portwine_create_shortcut`, `pw_auto_create_shortcut`, `portwine_change_shortcut`, `portwine_delete_shortcut`, `parse_lnk`, `get_lnk_path`, `pw_create_gui_png` |
| Переводы | `check_translations`, `create_translations`, `generate_pot` |
| Обновления | `pw_port_update`, `gui_pw_update`, `pw_reinstall_pp`, `fixes_after_update` |
| Автоустановка | `pw_autoinstall_from_db` |

### var
- Версии: `PW_PROTON_LG_VER`, `PW_WINE_LG_VER`, `DXVK_{NEW,OLD,SAREK}_VER`, `VKD3D_{NEW,OLD,SAREK}_VER`, `PW_LIBS_VER`, `PW_PLUGINS_VER`, `DGV2_VER`, `DOTPFX_VER`
- Переключатели по умолчанию (`PW_MANGOHUD`, `PW_VKBASALT`, `PW_USE_ESYNC` и т.д.)
- `PW_MUST_WINEDLLOVERRIDES` — обязательные DLL-оверрайды
- Хуки-заглушки `add_in_start_portwine`, `add_in_stop_portwine`, `pw_other_fixes` (переопределяются в .ppdb)
- Шапка файла: `#SCRIPTS_NEXT_VERSION=NNNN` / `#SCRIPTS_STABLE_VERSION=NNNN` — читаются механизмом обновлений

## Важные значения переменных

### PW_WINE_USE
- `PROTON_LG` — алиас на `$PW_PROTON_LG_VER` (по умолчанию)
- `WINE_LG` — алиас на `$PW_WINE_LG_VER`
- Конкретное имя из `data/dist/` (например `PROTON_LG_9-12`, `WINE_LG_11-1`)
- `USE_SYSTEM_WINE` — системный wine, без SLR

### PW_VULKAN_USE (3D API)
| Значение | Режим | Версии |
|----------|-------|--------|
| `0` | WineD3D OpenGL | без DXVK |
| `1` | Sarek (Vulkan 1.1+) | `DXVK_SAREK_VER`, `VKD3D_SAREK_VER` |
| `2` | Stable (Vulkan 1.3+) | `DXVK_OLD_VER`, `VKD3D_OLD_VER` |
| `6` | Newest (MESA 25+ / NVIDIA 550+) | `DXVK_NEW_VER`, `VKD3D_NEW_VER` |

### PW_PREFIX_NAME
- `DEFAULT` — обычный префикс
- `DOTNET` — префикс с предустановленным .NET (скачивается `dotpfx${DOTPFX_VER}.tar.xz` с GitHub releases)
- Любое другое имя → создаётся новый префикс. Имена нормализуются в ВЕРХНИЙ регистр, пробелы → `_`

### Другие
- `MIRROR` — `CLOUD` (cloud.linux-gaming.ru, по умолчанию для ru) или `GITHUB`
- `BRANCH` — `master` (STABLE) или `devel` (DEVEL, версия отображается с суффиксом `-dev`)
- `PW_GUI_START` — `NOTEBOOK` или `PANED`
- `PW_LOG=1` — подробный лог Wine/DXVK в PortProton.log
- `PW_CLI=1` — CLI-режим (без GUI, `PROCESS_LOG=1`)
- `PW_DISABLED_CREATE_DB=1` — не создавать/редактировать .ppdb (включается для setup/install/.msi, автоустановки)

## База данных игр (.ppdb)

Формат файла — обычный bash, который `source`-ится:
```bash
#!/usr/bin/env bash
#Author: имя
#GameName.exe            # ОБЯЗАТЕЛЬНО: имя exe для поиска (grep -ilw "#name.exe")
#Rating=1-5
################################################
export PW_WINE_USE="PROTON_LG"
export PW_VULKAN_USE="2"
export PW_DLL_INSTALL="vcrun2019"
export WINEDLLOVERRIDES="..."
export LAUNCH_PARAMETERS="--skip-launcher"
export PW_COMMENT_DB="Комментарий, показывается в GUI"

add_in_start_portwine () { :; }   # хук перед запуском
add_in_stop_portwine () { :; }    # хук после завершения
```

Поиск `.ppdb` в `pw_init_db`:
1. Если `portwine_exe` содержит `_vo_` или `_gv_` → `gamesvoice.ppdb` (русификаторы)
2. `<exe>.ppdb` рядом с exe — приоритет
3. Иначе grep по `#name.exe` в `scripts/portwine_db/`; найденный копируется рядом с exe (если не `PW_DISABLED_CREATE_DB`)
4. Несколько совпадений → диалог выбора

`edit_db_from_gui VAR...` записывает текущие значения переменных в `.ppdb` (`sed` замена или `echo >>`).

Правила `clear_db.sh` (запускать перед коммитом новых ppdb): удаляет пользовательские переменные (`MANGOHUD`, `VKBASALT`, `GAMESCOPE`, `FPS_LIMIT`, `_RAY_TRACING`, `_DLSS`, `PW_USE_GAMEMODE` и т.д.), нормализует `PW_WINE_USE` до `WINE_LG`/`PROTON_LG`, убирает `.exe` из имени файла, проверяет дубликаты `#name.exe`.

Внешние ppdb: https://ppdb.linux-gaming.ru (кнопка `find_ext_ppdb`, URL-схема `portproton://`).

## Скрипты автоустановки

Расположены в `data_from_portwine/scripts/pw_autoinstall/`, имя файла `PW_UPPER_CASE_NAME`. Заголовок парсится GUI:
```bash
#!/usr/bin/env bash
# Author: имя
# type: games|emulators
# name: Отображаемое название
# image: имя_иконки            # data_from_portwine/img/<image>.png
# info_en: Описание на английском
# info_ru: Описание на русском
########################################################################
export LAUNCH_PARAMETERS="/VERYSILENT"
export PW_AUTOINSTALL_EXE="${PW_USER_TEMP}/Setup.exe"
export PW_PREFIX_NAME="DEFAULT"
export PW_WINE_USE="PROTON_LG"
export PORTWINE_CREATE_SHORTCUT_NAME="Имя ярлыка"

pw_clear_pfx          # опционально, чистый префикс
start_portwine
if try_download "https://.../Setup.exe" "${PW_AUTOINSTALL_EXE}" no_mirror ; then
    pw_start_progress_bar_install_game "Имя."
    pw_run "${PW_AUTOINSTALL_EXE}"          # или: pw_run msiexec /i "${PW_AUTOINSTALL_EXE}"
    portwine_exe="$WINEPREFIX/drive_c/Program Files/App/app.exe"
    try_remove_file "${PW_AUTOINSTALL_EXE}"
    try_remove_file "${portwine_exe}.ppdb"
    kill_portwine
    pw_stop_progress_bar
    portwine_create_shortcut
fi
stop_portwine
```

`pw_autoinstall_from_db` перед `source` скрипта задаёт: `PW_USER_TEMP=$PORT_WINE_TMP_PATH`, `PW_VULKAN_USE=1`, `PW_DISABLED_CREATE_DB=1`, отключает MangoHud/vkBasalt/gamemode/EAC/esync/fsync. Список «топовых» для первой вкладки — `AI_TOP_GAMES` в `var`.

## CLI интерфейс

Полный список (`portproton cli --help`):

```
--help                 справка
--repair               восстановление скриптов
--reinstall            переустановка PortProton
--generate-pot         регенерация .pot/.po
--debug <exe>          трейс в scripts-debug.log
--update               проверка обновлений
--launch <exe>         немедленный запуск
--edit-db <exe> VAR=VAL ...     запись переменных в .ppdb
--get-user-conf VAR / --set-user-conf VAR VAL / --delete-user-conf VAR
--list-db              список переменных для редактирования (+NUMA, LOCALE_LIST; «blocked» для недоступных)
--show-ppdb <exe|.ppdb>  итоговые значения: ppdb > user.conf > var
--backup-prefix <PREFIX> <DIR>  → .ppack
--restore-prefix <file.ppack>
--winefile|--winecfg|--winecmd|--winereg|--wine_uninstaller|--clear_pfx <WINE_VER> <PREFIX>
--mangohud-preview ["config"]
--initial              только инициализация
--autoinstall PW_NAME
```

Запуск без `cli`: `start.sh /path/game.exe` открывает окно настроек запуска. Формат `file://` поддерживается.

## Зеркала и обновления

- `try_download URL DEST [флаг]`: при `MIRROR=CLOUD` сначала пробует `$url_cloud/<basename>`, затем URL; при `GITHUB` наоборот. Флаг `no_mirror` — только прямой URL (сторонние установщики), `silent` — без GUI
- Кнопка в прогресс-баре позволяет переключить зеркало (записывается в user.conf)
- `pw_port_update`: выбирает самый быстрый из двух источников скриптов (raw.githubusercontent.com, git.linux-gaming.ru), кеширует выбор в `data/tmp/update_skip_mirror`; читает `SCRIPTS_STABLE_VERSION` (master) или `SCRIPTS_NEXT_VERSION` (devel) из `var` удалённой ветки
- Wine-сборки: GitHub releases Castro-Fidel/PortWINE + метаданные с зеркала (см. `gui_proton_downloader`)
- `SKIP_CHECK_UPDATES=1` отключает проверку (используется при перезапуске)

## Соглашения о коде

### Стиль shell-скриптов
- `#!/usr/bin/env bash` в начале каждого скрипта; заголовок `# Author: ...`
- Отступ 4 пробела; `[[ ]]` для условий; многострочные условия через `\` в начале строки с `&&`/`||`
- `export` для глобальных переменных; `export -f` для функций, используемых в subshell
- Функции: `snake_case`, объявление `name () {`
- Глобальные переменные: `ВЕРХНИЙ_РЕГИСТР`; служебные lowercase (`portwine_exe`, `pw_yad`, `install_ver`)
- Директивы `# shellcheck disable=...` / `# shellcheck source=/dev/null` используются; код должен проходить `shellcheck` без новых предупреждений
- Булевы значения — строки `"0"`/`"1"`; «выключено» для списковых настроек — `"disabled"`

### Префиксы переменных
- `PW_` — настройки PortProton (`PW_MANGOHUD`, `PW_VULKAN_USE`, `PW_USE_*`)
- `PW_DGV2_` — dgVoodoo2, `PW_GS_` — GameScope
- `PORT_WINE_` / `PORT_SCRIPTS_` — пути
- `GUI_`, `THEME_`, `*_GUI_TYPE_*` — GUI/темы
- `DXVK_` / `VKD3D_` — версии и настройки графики
- `translations[...]` — ассоциативный массив переводов

### Операции с файлами
Всегда использовать обёртки вместо `cp/rm/mkdir/ln`:
`try_copy_file`, `try_copy_dir`, `try_remove_file`, `try_remove_dir`, `create_new_dir`, `try_force_link_file`, `try_force_link_dir`.

### Логирование
`print_info` / `print_warning` / `print_error` / `print_ok` — цветной вывод в терминал + `process.log`. `fatal` — ошибка и выход. Не использовать голый `echo` для сообщений пользователю.

### Система переводов
- В коде: `${translations[English text]}` — ключ = английская строка. Многострочные ключи содержат `\\n`
- `generate_pot` (`portproton cli --generate-pot`) извлекает ключи из `functions_helper`, `start.sh`, `setup.sh`, `add_in_steam.sh` через `xgettext`, обновляет `PortProton.pot` и `.po` для `LANGUAGES_LIST` (ru es)
- `.po` компилируются в кеш `data/tmp/cache_lang/<lang>` при первом запуске (`create_translations`); кеш инвалидируется по версии скриптов
- Переводы ведутся на Weblate: https://translate.codeberg.org/projects/portproton/ — **не редактировать `.po` вручную** без необходимости, только добавлять новые ключи через `generate_pot`
- Язык выбирается при первом запуске, хранится в `data/tmp/PortProton_loc`; в gamescope-сессии всегда `en`

### Разработка GUI
- Темы: `*.pptheme` (bash, задаёт `YAD_OPTIONS`, размеры кнопок/окон, количество колонок) + `style.css`
- `pw_yad` — путь к `yad_gui_pp`; расширения кастомного YAD: `--gui-type=...`, `--key=`, `--tab-pos`, `--keep-icon-size`
- Переключатели: `THEME_CHKBOX=SW|CHK`; `combobox_fix` ставит текущее значение первым в `:CB`
- `yad_info` / `yad_error` / `yad_question` — стандартные диалоги; поддерживают pango-разметку (`<b>`)
- В CLI (`PW_CLI=1`) `pw_yad` может быть пустым — функции GUI должны это учитывать

## Ветки и релизы

- `devel` — основная ветка разработки (default для PR); `master` — стабильная
- Ветки контрибьюторов: `<github-user>-<topic>` (например `Boria138-mirror`), вливаются в `devel` merge-коммитом
- Коммит версии: `Scripts version NNNN` (devel: `SCRIPTS_NEXT_VERSION` в `var` + changelog) или `STABLE: Scripts version NNNN` (обе версии + changelog). Changelog пишется в оба файла `changelog_en` и `changelog_ru`, формат `###Scripts version NNNN### / [stable /] Date: DD.MM.YYYY / Download update size: N megabytes`
- Стиль коммитов свободный; встречаются Conventional Commits (`fix:`, `feat(wine):`)
- **Агентам: не менять версию в `var` и changelog без явной просьбы**

## Тестирование и отладка

Проверки без запуска:
```bash
bash -n data_from_portwine/scripts/start.sh data_from_portwine/scripts/functions_helper
shellcheck -x data_from_portwine/scripts/start.sh   # ожидаются существующие предупреждения
```

Ручной запуск из репозитория невозможен напрямую — скрипты ожидают структуру установленного PortProton (`data/tmp/PortProton_ver` и т.д.). Для теста копировать `data_from_portwine/scripts/*` в `$PORT_WINE_PATH/data/scripts/` существующей установки или использовать `gui_open_scripts_from_backup`.

Отладка:
- `portproton cli --debug /path/game.exe` → `scripts-debug.log` (`set -x`)
- `PW_LOG=1` (user.conf или ppdb) → подробный лог Wine/DXVK/VKD3D в `PortProton.log`
- `/tmp/PortProton_$USER/var.log` — все `DXVK_*`, `VKD3D_*`, `WINE*`, `PW_*` переменные последнего запуска
- Lock-файл `/tmp/PortProton_$USER/portproton.lock` — при зависании удалить

Типичные сценарии:
- GUI и CLI режимы; запуск через Steam (compat tool) и flatpak (`check_flatpak`: SLR отключён, `PW_USE_RUNTIME=0`)
- Разные Wine (WINE_LG, PROTON_LG) и 3D API (0/1/2/6)
- Создание/очистка/бэкап префиксов (`.ppack`)
- Автоустановка в чистом префиксе

## Особенности платформ

- **Flatpak** (`ru.linux_gaming.PortProton`): без SLR, симлинк `~/PortProton`, миграция из скриптовой установки в `setup.sh`
- **Steam Deck / SteamOS / gamescope-сессия**: язык `en`, загрузки через xterm, `.desktop` копируется на рабочий стол
- **Alt Linux**: пакет `portproton` в репозитории (`/usr/bin/portproton`), особые пути NVIDIA в `pw_init_runtime`
- **ROSA / RED OS**: `LOCPATH` для контейнера
- **Batocera**: единственный случай, когда допускается запуск от root

## Важные зависимости времени выполнения

Требуемые системные пакеты: `bash`, `bubblewrap`, `curl`, `cabextract`, `zstd`, `tar`, `xz`, `icoutils`, `xdg-utils`, `jq`, `file`, `xrandr`, `vulkan-driver` + `vulkan-icd-loader` (32 и 64 бит), `openssl`. Опционально: `gamemode`, `xterm`, `exiftool`, `perl` (для add_in_steam.sh), `xgettext` (для переводов).

## Соображения безопасности

1. **Проверка root**: скрипты отказываются запускаться от root (кроме Batocera)
2. **Песочница**: SLR + bubblewrap; монтирование управляется `PW_RT_MOUNT_RO` / `PW_RT_MOUNT_RW` в `var`
3. **Загрузки**: `try_check_sha256sum` для файлов с контрольными суммами; `curl -f` с fallback на зеркало
4. **Steam**: `add_in_steam.sh` бинарно редактирует `shortcuts.vdf` через perl/hex — менять осторожно
5. **Lock-файлы**: предотвращение одновременных запусков (не в flatpak)
6. **`.ppdb` — исполняемый bash**: файлы из внешних источников `source`-ятся без проверки; не добавлять автоматическое скачивание без подтверждения пользователя
7. В `var` присутствует API-ключ SteamGridDB (`SGDBAPIKEY`) — публичный ключ проекта, не заменять личным

## Связанные проекты и ресурсы

- **PortProtonQt** (преемник): https://github.com/linux-gaming-ru/PortProtonQt
- **Wine**: https://github.com/ValveSoftware/Proton, https://github.com/GloriousEggroll/proton-ge-custom
- **Сборки PROTON_LG / WINE_LG, dotpfx**: https://github.com/Castro-Fidel/PortWINE/releases
- **Установщик для Alt**: https://github.com/Castro-Fidel/PortProton_ALT
- **База ppdb**: https://ppdb.linux-gaming.ru
- **Переводы**: https://translate.codeberg.org/projects/portproton/
- **Flathub**: ru.linux_gaming.PortProton
- **Зеркала скриптов**: git.linux-gaming.ru/CastroFidel/PortWINE
- **Сообщество**: https://t.me/linux_gaming_ru

## Примечания для AI агентов

1. **Основной язык — русский**: комментарии, changelog_ru, ответы пользователю. Ключи переводов — английские
2. **Нет системы сборки и тестов**: проверять `bash -n` и `shellcheck`; поведение зависит от окружения (GPU, DE, Wayland)
3. **Глобальное состояние**: функции зависят от экспортированных переменных и порядка `source` (`functions_helper` → `var` → user.conf → ppdb). Изменяя дефолт в `var`, учитывать `--show-ppdb` и `--list-db`
4. **Режим поддержки**: предпочитать минимальные точечные исправления; не ломать CLI для PortProtonQt
5. **functions_helper — один файл на 8300 строк**: искать функции по `grep -n '^name ()'`, читать фрагментами
6. **Числовые коды в `case "$PW_YAD_SET"`** — коды возврата кнопок YAD, не менять без правки соответствующих `--button=...:N`
7. **Добавляя строку в GUI** — обернуть в `${translations[...]}` и перегенерировать `.pot` через `generate_pot`
8. **Добавляя новую переменную настройки** — дефолт в `var`, при необходимости в `clear_db.sh` (если пользовательская), в `gui_edit_db` (`PW_EDIT_DB_FINAL_LIST`) и в `DISABLE_EDIT_DB_LIST` для несовместимых режимов
