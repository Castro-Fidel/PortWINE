# PortProton (PortWINE) - Документация для AI агентов

## Обзор проекта

**PortProton** (также известный как **PortWINE**) — это инструмент для Linux, предназначенный для упрощения запуска Windows-игр и приложений на Linux. Разрабатывается в основном русским сообществом линукс-геймеров (linux-gaming.ru).

Проект предоставляет:
- GUI-обёртку вокруг Wine/Proton для запуска Windows-исполняемых файлов
- Автоустановку в один клик для популярных игровых лаунчеров (Epic Games, Battle.net, Steam и др.)
- Преднастроенные эмуляторы для консольных игр
- Оптимизированные настройки для максимальной игровой производительности
- Интеграцию с MangoHud, vkBasalt, GameScope и dgVoodoo2

**Официальный сайт:** https://linux-gaming.ru  
**Лицензия:** MIT License (Copyright 2026 Castro-Fidel)  
**Основной язык документации и комментариев:** Русский

## Технологический стек

| Компонент | Технология |
|-----------|------------|
| Основной язык | Bash (shell-скрипты) |
| GUI-фреймворк | YAD (Yet Another Dialog) с GTK |
| Windows-совместимость | Wine / Proton (форк Valve) / Proton-GE |
| Контейнер | Steam Linux Runtime (SLR) + Bubblewrap sandbox |
| Графические API | Vulkan, OpenGL, DXVK (DirectX→Vulkan), VKD3D (DirectX 12→Vulkan) |
| Оверлей-инструменты | MangoHud (оверлей производительности), vkBasalt (улучшение графики) |
| Система сборки | Отсутствует (скриптовая, компиляция не требуется) |

## Структура проекта

```
PortWINE/
├── data_from_portwine/           # Основная директория с данными
│   ├── scripts/                  # Основные shell-скрипты
│   │   ├── start.sh              # Точка входа (~1220 строк)
│   │   ├── functions_helper      # Основная функциональность (~8300 строк)
│   │   ├── var                   # Переменные конфигурации по умолчанию
│   │   ├── setup.sh              # Скрипт установки/настройки
│   │   ├── portwine_db           # Определения базы данных игр
│   │   ├── pw_autoinstall/       # Скрипты автоустановки игр/лаунчеров
│   │   ├── add_in_steam.sh       # Утилиты интеграции со Steam
│   │   ├── clear_db.sh           # Утилита очистки базы данных
│   │   └── thanks                # Файл благодарностей
│   ├── themes/                   # Темы GUI
│   │   ├── default/              # Файлы темы по умолчанию
│   │   ├── default.pptheme       # Конфигурация темы по умолчанию
│   │   ├── classic/              # Классическая тема
│   │   ├── classic.pptheme
│   │   ├── compact/              # Компактная тема
│   │   └── compact.pptheme
│   ├── locales/                  # Переводы
│   │   ├── ru/LC_MESSAGES/       # Русский перевод
│   │   └── es/LC_MESSAGES/       # Испанский перевод
│   ├── img/                      # Иконки и изображения
│   │   ├── gui/                  # Иконки GUI (PNG, SVG)
│   │   └── *.png                 # Иконки приложений
│   ├── changelog_en              # Английский changelog
│   ├── changelog_ru              # Русский changelog
│   ├── dxvk.conf                 # Конфигурация DXVK
│   └── vkBasalt.conf             # Конфигурация vkBasalt
├── README.md                     # Английский README
├── README-RU.md                  # Русский README
└── LICENSE                       # Лицензия MIT
```

## Ключевые скрипты и их назначение

### Основная точка входа
- **`data_from_portwine/scripts/start.sh`** - Основная точка входа в приложение.
  - Обрабатывает аргументы CLI и инициализацию GUI
  - Подключает `functions_helper` и `var`
  - Управляет основным циклом приложения

### Основная библиотека
- **`data_from_portwine/scripts/functions_helper`** - Содержит все основные функции (~8300 строк):
  - Операции с файлами (try_copy, try_remove и т.д.)
  - Управление загрузками с индикаторами прогресса
  - Управление префиксами Wine
  - GUI-диалоги (yad_info, yad_error, yad_question)
  - Интеграция со Steam
  - Логика автоустановки
  - Управление базой данных

### Конфигурация
- **`data_from_portwine/scripts/var`** - Переменные окружения и настройки по умолчанию:
  - Версии Wine (PROTON_LG, WINE_LG)
  - Версии DXVK/VKD3D
  - Настройки переключателей по умолчанию (PW_MANGOHUD, PW_VKBASALT и т.д.)
  - Настройки темы GUI по умолчанию

### Скрипты автоустановки
Расположены в `data_from_portwine/scripts/pw_autoinstall/`, каждый скрипт следует формату:
```bash
#!/usr/bin/env bash
# type: games|emulators
# name: Отображаемое название
# image: имя_иконки
# info_en: Описание на английском
# info_ru: Описание на русском
```

Примеры: PW_EPIC, PW_BATTLE_NET, PW_STEAM, PW_PPSSPP, PW_CEMU и др.

## Соглашения о коде

### Стиль shell-скриптов
- Все скрипты используют `#!/usr/bin/env bash`
- `#!/usr/bin/env bash` в начале каждого скрипта
- Широкое использование `export` для глобальных переменных
- Функции используют именование в стиле snake_case
- Глобальные переменные используют ВЕРХНИЙ_РЕГИСТР с префиксом PW_ для настроек PortProton

### Распространённые префиксы переменных
- `PW_` - Настройки PortProton (например, PW_MANGOHUD, PW_VULKAN_USE)
- `PORT_WINE_` - Переменные, связанные с путями (например, PORT_WINE_PATH)
- `GUI_` - Настройки, связанные с GUI
- `DXVK_` / `VKD3D_` - Версии, связанные с графикой

### Шаблон операций с файлами
Кодовая база последовательно использует функции-обёртки для безопасных операций с файлами:
- `try_copy_file "источник" "назначение"`
- `try_remove_file "путь_к_файлу"`
- `try_remove_dir "путь_к_директории"`
- `create_new_dir "путь_к_директории"`
- `try_force_link_file "источник" "ссылка"`

### Система переводов
Переводы управляются через gettext:
- Файл шаблона: `data_from_portwine/locales/PortProton.pot`
- Русский перевод: `data_from_portwine/locales/ru/LC_MESSAGES/PortProton.po`
- Испанский перевод: `data_from_portwine/locales/es/LC_MESSAGES/PortProton.po`
- В коде: `${translations[ИМЯ_КЛЮЧА]}`

### Разработка GUI
GUI построен с использованием YAD (Yet Another Dialog):
- Темы определяются в файлах `.pptheme`
- Стилизация CSS через `style.css` в директориях тем
- Кастомный скомпилированный бинарник YAD: `data_from_portwine/themes/gui/yad_gui_pp`
- Бинарник трей-иконки: `data_from_portwine/themes/tray/tray_gui_pp`

## Ключевые файлы конфигурации

### Файлы тем (.pptheme)
Файлы тем настраивают внешний вид GUI:
- `THEME_NAME` - Идентификатор темы
- `YAD_OPTIONS` - Глобальные опции YAD включая путь к CSS
- Размеры кнопок: `BUTTON_SIZE_MM`, `BUTTON_SIZE`, `TAB_SIZE`
- Размеры окна: `PW_MAIN_SIZE_W`, `PW_MAIN_SIZE_H`
- Настройки раскладки: `MAIN_GUI_COLUMNS` и т.д.

### Пользовательская конфигурация (user.conf)
Создаётся во время выполнения в директории PortProton:
- Хранит предпочтения пользователя
- Изменяется через `edit_user_conf_from_gui()`
- Подключается при запуске

### База данных игр (.ppdb файлы)
Файлы конфигурации для конкретных игр, хранящиеся рядом с исполняемыми файлами:
- Содержат переменные окружения для конкретной игры
- Переопределяют настройки по умолчанию
- Могут быть загружены с https://ppdb.linux-gaming.ru

## CLI интерфейс

PortProton поддерживает работу через командную строку:

```bash
# Запуск с GUI
./data_from_portwine/scripts/start.sh

# CLI режим
portproton cli --launch /path/to/game.exe
portproton cli --edit-db /path/to/game.exe PW_MANGOHUD=1
portproton cli --autoinstall PW_EPIC
portproton cli --winecfg WINE_LG DEFAULT
portproton cli --backup-prefix DEFAULT /path/to/backup
portproton cli --restore-prefix /path/to/backup.ppack
```

## Важные зависимости времени выполнения

Требуемые системные пакеты:
- `bash` - Интерпретатор скриптов
- `bubblewrap` - Песочница
- `curl` - Загрузки
- `yad` (кастомная версия включена) - GUI диалоги
- `cabextract`, `zstd`, `tar` - Работа с архивами
- `icoutils` - Извлечение иконок
- `xdg-utils` - Интеграция с рабочим столом
- `jq` - Обработка JSON
- `xterm` - Fallback терминала
- `vulkan-driver`, `vulkan-icd-loader` - Поддержка Vulkan

## Руководство по разработке

### Добавление новых скриптов автоустановки
1. Создать файл в `data_from_portwine/scripts/pw_autoinstall/`
2. Использовать соглашение об именовании: `PW_UPPER_CASE_NAME`
3. Включить заголовочные комментарии с type, name, image, info_en, info_ru
4. Установить требуемые переменные (LAUNCH_PARAMETERS, PW_AUTOINSTALL_EXE и т.д.)
5. Вызвать `pw_clear_pfx`, `start_portwine`, затем `stop_portwine`

### Добавление новых функций
1. Добавить в файл `functions_helper`
2. Использовать `export -f function_name` для функций, используемых в subshell
3. Использовать `print_info`, `print_warning`, `print_error` для логирования
4. Следовать существующим соглашениям об именовании

### Изменение переводов
1. Редактировать `data_from_portwine/locales/PortProton.pot` для шаблона
2. Обновить `.po` файлы для каждого языка
3. Использовать функцию `generate_pot` для регенерации шаблона

## Тестирование и отладка

### Режим отладки
Запуск с выводом отладочной информации:
```bash
portproton cli --debug
```
Создаёт файл `scripts-debug.log` с полным трейсом.

### Типичные сценарии тестирования
- Тестирование обоих режимов: GUI и CLI
- Тестирование с разными версиями Wine (WINE_LG, PROTON_LG)
- Тестирование создания и удаления префиксов
- Тестирование скриптов автоустановки в чистом префиксе

### Устранение неполадок
- Проверить `PortProton.log` в директории PortProton
- Использовать флаг `--debug` для подробного вывода
- Проверить установку всех зависимостей
- Проверить наличие lock-файлов в `/tmp/PortProton_$USER/`

## Соображения безопасности

1. **Проверка root**: Скрипты явно отказываются запускаться от root (кроме Batocera)
2. **Песочница**: Используется bubblewrap для контейнеризации
3. **Загрузки**: Проверка SHA256 контрольных сумм для загружаемых файлов
4. **Интеграция со Steam**: Безопасное изменение файла shortcuts.vdf Steam
5. **Lock-файлы**: Предотвращение множественных одновременных запусков

## Управление версиями

Номера версий определены в:
- `data_from_portwine/scripts/var`: `SCRIPTS_NEXT_VERSION` и `SCRIPTS_STABLE_VERSION`
- Формат: Четыре цифры (например, 2474)
- Обновления загружаются с `url_cloud` или `url_git`

## Связанные проекты и ресурсы

- **Используемые источники Wine**:
  - WINE-PROTON: https://github.com/ValveSoftware/Proton
  - WINE-PROTON-GE: https://github.com/GloriousEggroll/proton-ge-custom
- **База данных настроек**: https://ppdb.linux-gaming.ru
- **Платформа переводов**: https://translate.codeberg.org/projects/portproton/
- **Пакет Flathub**: ru.linux_gaming.PortProton

## Примечания для AI агентов

1. **Основной язык — русский** - Комментарии и часть документации на русском языке
2. **Нет системы сборки** - Это чистый shell-скрипт проект, компиляция не требуется
3. **Широкое использование глобальных переменных** - Функции сильно зависят от экспортированных переменных окружения
4. **Зависимость от YAD** - GUI требует кастомной сборки YAD, включённой в репозиторий
5. **Интеграция с Wine** - Тесная интеграция с внутренностями Wine/Proton
6. **Совместимость со Steam** - Специальная обработка для Steam Deck и интеграции со Steam
