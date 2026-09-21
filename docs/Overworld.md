## Overworld

- **Структура комнат**:
  - Каждая локация — сцена с корнем `Room` (`Node2D`).
  - Дочерние ноды:
    - `Bg` — фон, пол, стены, декорации фона (без `y_sort_enabled`, `z_index` обычно отрицательный).
    - `Actors` — игрок, компаньоны, NPC, триггеры (тут включён `y_sort_enabled = true`).
    - `Fg` (опционально) — объекты перед всеми (арки, колонны; без `y_sort_enabled`, `z_index` положительный).

- **Y‑sort**:
  - Включаем `y_sort_enabled = true` только у контейнера `Actors`.
  - У ходячих (`player`, `Companion`, body NPC) в `_physics_process` задаём
    `z_index = int(global_position.y)`, чтобы корректно сортировать внутри `Actors`.
  - `Bg`/`Fg` не участвуют в y‑sort, только в слоёности по `z_index`.

- **Переходы между комнатами**:
  - Используется `TravelTrigger` (`scripts/overworld/travel_trigger.gd`).
  - Поля:
    - `target_scene` — путь к целевой комнате.
    - `spawn_point` — имя `Node2D` внутри целевой комнаты для спавна игрока.
    - `require_interact` — нужен ли `interact` для активации.
    - `set_dark_world` — включить/выключить тёмный мир при переходе.
  - Триггер вызывает `SceneTransition.travel(target_scene, spawn_point, set_dark_world)`.

- **Переход и fade**:
  - `SceneTransition.travel`:
    - вызывает `PostProcessing.fade_out(0.2)`,
    - после затемнения применяет `Global.is_dark_world = set_dark_world`,
    - меняет сцену и затем делает `PostProcessing.fade_in(0.2)`.
  - Бои используют `PostProcessing.flash_to_black/flash_from_black` для более ярких вспышек.

- **Камера**:
  - Автозагрузка `CameraController` (`scripts/overworld/camera_controller.gd`).
  - При спавне игрока: `CameraController.instance.start_follow(player, Vector2(0, -16))`.
  - Ограничения комнаты: `CameraController.instance.set_room_limits(min, max)` из скрипта комнаты.

