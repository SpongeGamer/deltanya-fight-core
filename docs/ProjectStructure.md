## Структура проекта

- `fighters/` — боевые персонажи (`Character`) и монстры (`Monster`), их акты/спеллы.
- `soul/` — душа игрока, типы душ и поведения (bullet‑hell часть).
- `pellets/` — пули и снаряды.
- `holdables/` — предметы, экипировка, use‑predicate’ы.
- `ui/battle/` — боевой интерфейс (нижняя панель, выбор действий, TP‑бар, SoulCage).
- `ui/overworld/` — инвентарь и прочий UI поверх мира.
- `globals/` — автозагрузки: `Global`, `PartyData`, `Sounds`, `SceneTransition`, `PostProcessing`, `OverworldParty` и т.п.
- `resources/` — ресурсы диалогов и прочего конфига.
- `scripts/overworld/` — логика передвижения по миру, триггеры, камера, диалоги.
- `scripts/debug/` — тестовые помощники (запуски боёв, dev‑сцены).
- `scenes/battle/` — сцены боя.
- `scenes/menus/` — титульный экран, экраны победы/поражения, настройки.
- `scenes/prefabs/` — общие префабы (player, body, диалоговые зоны и т.п.).
- `scenes/overworld/` — комнаты мира (overworld‑локации).
- `docs/` — документация по доменам (Characters, Soul, Overworld, ProjectStructure).

## Основные потоки

- **Бой**:
  - Скрипты/сцены в `fighters/`, `soul/`, `pellets/`, `ui/battle/`, `scenes/battle/`.
  - Запуск через encounter‑скрипты (например `scripts/debug/test_enemy_encounter.gd`) или специфические триггеры.

- **Overworld**:
  - Комнаты в `scenes/overworld/` по шаблону `Room → Bg/Actors/Fg`.
  - Переходы — `TravelTrigger` + `SceneTransition`.
  - Камера — `CameraController` (autload), вызывается при спавне игрока.

- **Инвентарь**:
  - Открывается из `player.gd` (overworld).
  - Сцена `ui/overworld/overworld_inventory.tscn` читает `Global.items` и `Global.characters`.

