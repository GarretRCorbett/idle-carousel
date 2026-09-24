# Topic B: Input routing and scene/UI layout

This memo proposes a Phase 2 implementation for Garret’s approval. It does not authorize scene edits or settle pending game-design decisions.

**Recommendation:** use one central `_unhandled_input()` router that selects enemies by distance, a viewport-centered `World` node, and a HUD whose transparent layout containers ignore mouse input while bounded UI panels block it.

All custom methods and signals below are **proposed project interfaces**, not existing APIs. No commands, file changes, or tests were run.

## 1. Click routing

### Compare the three approaches

| Approach | Strengths | Problems for Idle Carousel | Recommendation |
|---|---|---|---|
| Enemy `Area2D.input_event`, with `input_pickable = true` | Built-in shape picking; convenient for isolated clickable objects | Physics picking happens after `_unhandled_input()`. A central empty-space handler can boost before the enemy receives the event. Overlapping enemies also need explicit arbitration. | Avoid for gameplay clicks. |
| Central `_unhandled_input()` plus physics point query | One decision point; uses existing collision geometry | A point query has no click-radius parameter. Enlarged click areas or a circle shape query are needed. Physics queries should be processed during `_physics_process()`, introducing timing considerations for moving enemies. | Viable, but unnecessary complexity here. |
| Central `_unhandled_input()` plus distance checks against registered enemies | Simple adjustable radius; immediate selection; deterministic overlap handling; easy unit testing | Linear scan per click; circular picking approximates silhouettes; registry needs lifecycle cleanup | **Use for Phase 2.** |

The input-order issue is important: Godot routes GUI input before `_unhandled_input()`, but physics object picking afterward. Do not combine an unconditional empty-space handler in `_unhandled_input()` with enemy physics picking. [Godot input propagation](https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html)

Distance picking does **not** replace the required physics ray queries for mount sweeps. These solve different problems.

### Routing contract

For each **left-button press**:

1. Let GUI processing happen first.
2. If the event reaches the router, verify it lies inside the gameplay viewport.
3. Convert its viewport position to world coordinates.
4. Select at most one eligible enemy within its click radius.
5. If selected, emit an enemy-click request.
6. Otherwise, emit a play-area-click request.
7. Mark the event handled.

The resulting effects are mutually exclusive:

| Destination | Result |
|---|---|
| HUD panel or button | UI only |
| Approaching or latched enemy | Click damage only; normal death rewards still apply |
| Other play-area location | Spin boost; additionally, click Gold when latch count is zero |
| Outside the gameplay viewport | Nothing |

Do not award a boost as a fallback if an enemy-click handler kills or removes the target. The click has already been classified.

Treat the second press in a double-click as another click. Ignore releases, wheel events, and other mouse buttons.

### Click radius and overlapping targets

Add an independent field to `EnemyData`:

```gdscript
@export_range(0.0, 256.0, 1.0, "or_greater", "suffix:px")
var click_radius: float = 18.0
```

The default is a proposed starting value for tuning. The existing Leaf’s placeholder radius is `10.0`; its click radius can be larger without making Wolf hits more generous.

Proposed formula:

```text
effective click radius = EnemyData.click_radius + click-range upgrade bonus
```

Keep the upgrade bonus in upgrade data and update it through the existing upgrade system.

For overlaps, propose **nearest center wins**, with exact ties retaining registry order. This is predictable and easy to test, but Garret should approve it because the GDD does not specify overlap priority.

Use squared distances. Do not sort or scan every frame—only when a gameplay click arrives.

### How UI blocks clicks

Use these filters deliberately:

- **`MOUSE_FILTER_STOP` (`0`):** receives mouse input and automatically handles it. Use on bounded UI panels and buttons.
- **`MOUSE_FILTER_PASS` (`1`):** allows unhandled input to bubble through ancestors. It does not mean “send through to whatever is behind this.”
- **`MOUSE_FILTER_IGNORE` (`2`):** does not receive or automatically handle mouse input. Use on full-screen scaffolding and decoration.

An ignored parent does not, by itself, disable its interactive children. Therefore, an ignored full-screen root can contain a working `STOP` shop panel. Transparency does not determine hit testing: a visually empty full-screen `STOP` Control still blocks gameplay. [Godot Control mouse filters](https://docs.godotengine.org/en/stable/classes/class_control.html#enum-control-mousefilter)

For this HUD, use `IGNORE` on the full-screen `Control`, `MarginContainer`, layout `HBoxContainer`, spacer, and left-column layout. Use `STOP` on the actual stats panel and shop.

Do not detect gameplay clicks using `Input.is_action_just_pressed()` in `_process()`: global input state is not suppressed when UI handles an event. [Godot Input](https://docs.godotengine.org/en/stable/classes/class_input.html)

### Central router sketch

Proposed `EnemyBase` contract:

- `data: EnemyData`
- `can_receive_click() -> bool`, false immediately on death
- Runtime health separate from the shared data Resource

```gdscript
class_name ClickRouter
extends Node2D

signal enemy_click_requested(enemy: EnemyBase)
signal play_area_click_requested()

@export var click_radius_bonus: float = 0.0

var _enemies: Array[EnemyBase] = []


func register_enemy(enemy: EnemyBase) -> void:
    if not _enemies.has(enemy):
        _enemies.append(enemy)


func unregister_enemy(enemy: EnemyBase) -> void:
    _enemies.erase(enemy)


func _unhandled_input(event: InputEvent) -> void:
    var mouse_event: InputEventMouseButton = event as InputEventMouseButton
    if mouse_event == null:
        return
    if mouse_event.button_index != MOUSE_BUTTON_LEFT:
        return
    if not mouse_event.pressed:
        return
    if not get_viewport_rect().has_point(mouse_event.position):
        return

    # Input position is already in viewport coordinates.
    # Invert the world canvas transform, not this node's global transform.
    var world_point: Vector2 = (
        get_canvas_transform().affine_inverse() * mouse_event.position
    )

    get_viewport().set_input_as_handled()
    route_world_click(world_point)


func route_world_click(world_point: Vector2) -> void:
    var target: EnemyBase = choose_target(
        world_point, _enemies, click_radius_bonus
    )
    if target != null:
        enemy_click_requested.emit(target)
        return

    play_area_click_requested.emit()


static func choose_target(
    world_point: Vector2,
    enemies: Array[EnemyBase],
    radius_bonus: float
) -> EnemyBase:
    var best: EnemyBase = null
    var best_distance_squared: float = INF

    for enemy: EnemyBase in enemies:
        if not is_instance_valid(enemy):
            continue
        if enemy.is_queued_for_deletion():
            continue
        if not enemy.can_receive_click():
            continue

        var radius: float = maxf(
            0.0, enemy.data.click_radius + radius_bonus
        )
        var distance_squared: float = (
            world_point.distance_squared_to(enemy.global_position)
        )

        if distance_squared > radius * radius:
            continue
        if distance_squared < best_distance_squared:
            best = enemy
            best_distance_squared = distance_squared

    return best
```

`get_canvas_transform()` maps this world canvas into viewport coordinates. Its inverse produces coordinates comparable with enemy `global_position`. Do not also subtract `World.position`; that would mix coordinate spaces. [Godot CanvasItem transforms](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html#class-canvasitem-method-get-canvas-transform)

**Lifecycle wiring:** `Game` connects spawn/removal signals to register/unregister functions. Remove dead enemies promptly, and retain the validity checks for deferred deletion. This registry indexes scene objects; it does not become another owner of health, Gold, or latch counts.

**Effect wiring:** `Game` connects router signals to controlled gameplay functions:

- Enemy click → apply the current click damage.
- Play-area click → add boost, then grant click Gold only if the authoritative latch count is zero.

Keep the play-area operation synchronous so another event cannot slip between its latch check and payout. Gameplay emits state changes; HUD observes them.

### Fast-moving enemies

Select the target immediately when handling the event. Do not store only the click position and select again next physics tick; the enemy could move away.

A larger radius improves usability but is not motion compensation. Initially, use current simulation positions and tune the radius. If physics interpolation creates visible disagreement, investigate that specifically; do not silently add historical-position picking or velocity-based hitboxes.

### If physics picking is chosen later

A point-query sketch uses the actual Godot 4 API:

```gdscript
# Inside a Node2D script; call during _physics_process().
@export_flags_2d_physics var enemy_query_mask: int = 0
@export var query_result_limit: int = 64


func query_enemies_at(world_point: Vector2) -> Array[Dictionary]:
    var query: PhysicsPointQueryParameters2D = (
        PhysicsPointQueryParameters2D.new()
    )
    query.position = world_point
    query.collision_mask = enemy_query_mask
    query.collide_with_areas = true
    query.collide_with_bodies = false

    var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
    return space.intersect_point(query, query_result_limit)
```

Configure the mask in the Inspector. A point query cannot supply click padding; use dedicated click geometry or `PhysicsShapeQueryParameters2D` with a `CircleShape2D`. Resolve overlaps explicitly and account for result limits. [Godot physics queries](https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate2d.html)

## 2. Exact `Game.tscn` structure

### World positioning

**Use `World: Node2D` centered in the viewport, without a `Camera2D` for Phase 2.**

There is no camera movement or zoom requirement. A centered world is easier to inspect, and the fixed booth and latched enemies remain siblings of the rotating carousel.

At the design resolution:

```text
World.position = (640, 360)
World.rotation = 0
World.scale = (1, 1)
```

Recenter on viewport resizing, using logical viewport dimensions:

```gdscript
class_name Game
extends Node2D

@onready var world: Node2D = $World


func _ready() -> void:
    get_viewport().size_changed.connect(_center_world)
    _center_world()


func _center_world() -> void:
    world.position = get_viewport_rect().get_center()
```

A window resize changes presentation placement for all World children together. During gameplay, neither `World` nor `EnemyLayer` rotates.

### World and systems tree

```text
Game (Node2D)                           game.gd
├── World (Node2D)                      position=(640,360) at design size
│   ├── Carousel (Node2D)               carousel.gd; rotation applied here
│   │   ├── Visual (Node2D)             placeholder _draw()
│   │   └── MountSlots (Node2D)
│   │       ├── Slot1 (Marker2D)
│   │       │   └── Horse (Mount.tscn instance; when populated)
│   │       ├── Slot2 (Marker2D)
│   │       ├── Slot3 (Marker2D)
│   │       ├── Slot4 (Marker2D)
│   │       ├── Slot5 (Marker2D)
│   │       └── Slot6 (Marker2D)
│   ├── TicketBooth (Node2D)            ticket_booth.gd; fixed relative to World
│   │   └── Visual (Node2D)             placeholder _draw()
│   ├── EnemyLayer (Node2D)             rotation=0; scale=(1,1)
│   ├── ProjectileLayer (Node2D)        world-space; empty until needed
│   └── ClickLayer (Node2D)             click_router.gd
├── WaveManager (Node)                  added in Step 8
│   └── WaveTimer (Timer)               recurring wave scheduling
└── HUD (CanvasLayer)                   layer=1; identity transform
    └── HUDRoot (Control)               full rect
        └── ScreenMargin (MarginContainer)
            └── Columns (HBoxContainer)
                ├── LeftColumn (VBoxContainer)
                │   └── StatsPanel (PanelContainer)
                │       └── StatsMargin (MarginContainer)
                │           └── StatsVBox (VBoxContainer)
                │               ├── GoldLabel (Label)
                │               ├── GoldPerSecLabel (Label)
                │               ├── HealthBar (ProgressBar)
                │               └── WaveCountdownLabel (Label)
                ├── WorldSpacer (Control)
                └── ShopPanel (PanelContainer)
                    └── ShopMargin (MarginContainer)
                        └── UpgradeRows (VBoxContainer)
                            ├── SpinSpeed1Row (HBoxContainer)
                            │   ├── TextVBox (VBoxContainer)
                            │   │   ├── NameLabel (Label)
                            │   │   └── DescriptionLabel (Label)
                            │   └── CostButton (Button)
                            ├── SpinSpeed2Row (HBoxContainer)
                            │   ├── TextVBox (VBoxContainer)
                            │   │   ├── NameLabel (Label)
                            │   │   └── DescriptionLabel (Label)
                            │   └── CostButton (Button)
                            ├── ClickDamage1Row (HBoxContainer)
                            │   ├── TextVBox (VBoxContainer)
                            │   │   ├── NameLabel (Label)
                            │   │   └── DescriptionLabel (Label)
                            │   └── CostButton (Button)
                            ├── MountSlot2Row (HBoxContainer)
                            │   ├── TextVBox (VBoxContainer)
                            │   │   ├── NameLabel (Label)
                            │   │   └── DescriptionLabel (Label)
                            │   └── CostButton (Button)
                            └── WolfRow (HBoxContainer)
                                ├── TextVBox (VBoxContainer)
                                │   ├── NameLabel (Label)
                                │   └── DescriptionLabel (Label)
                                └── CostButton (Button)
```

This is the **Phase 2 endpoint tree**. Add functional nodes at their roadmap steps; Step 2 need not implement the shop or waves.

No `TicketBooth2`, tier controls, mount popup, or wave-control buttons are required for this phase. Add them through their later approved plans.

Slot markers represent capacity, not permanent six-way spacing. Position occupied mounts according to occupied count: one mount at the top, two opposite, and so forth. Buying capacity alone does not create a mount or redistribute an unchanged occupied set. Relayout must reset booth-pass tracking appropriately.

### HUD properties

Abbreviations below:

- **Fill:** `SIZE_FILL`
- **Expand Fill:** `SIZE_EXPAND_FILL`
- **Shrink Begin:** `SIZE_SHRINK_BEGIN`
- **Shrink End:** `SIZE_SHRINK_END`

Only `HUDRoot` and `ScreenMargin` use full-rect anchors. Descendants managed by containers use **`layout_mode = 2`**, with positions and sizes assigned by their parent.

| Node | Layout and proposed initial values | Mouse filter |
|---|---|---|
| `HUDRoot` | Full Rect; all offsets zero; grow both axes | Ignore |
| `ScreenMargin` | Full Rect; all offsets zero; margins left/top/right/bottom = `16` | Ignore |
| `Columns` | Horizontal and vertical Fill; separation `24` | Ignore |
| `LeftColumn` | Minimum width `220`; horizontal Fill without Expand; vertical Fill; separation `12` | Ignore |
| `StatsPanel` | Horizontal Fill; vertical Shrink Begin | **Stop** |
| `StatsMargin` | Fill both; four margins `12` | Ignore |
| `StatsVBox` | Fill both; separation `8` | Ignore |
| `GoldLabel` | Horizontal Fill; vertical Shrink Begin | Ignore |
| `GoldPerSecLabel` | Horizontal Fill; vertical Shrink Begin | Ignore |
| `HealthBar` | Horizontal Fill; minimum height `20`; `show_percentage = false` | Ignore |
| `WaveCountdownLabel` | Horizontal Fill; vertical Shrink Begin | Ignore |
| `WorldSpacer` | Expand Fill horizontally; Fill vertically | Ignore |
| `ShopPanel` | Minimum width `260`; horizontal Shrink End without Expand; vertical Fill | **Stop** |
| `ShopMargin` | Fill both; four margins `12` | Ignore |
| `UpgradeRows` | Fill both; separation `12`; alignment Begin | Ignore |
| Every upgrade row | Horizontal Fill; vertical Shrink Begin; separation `8` | Ignore |
| Every `TextVBox` | Horizontal Expand Fill; vertical Shrink Begin; separation `4` | Ignore |
| Every `NameLabel` | Horizontal Fill; clip/overrun policy to avoid widening the shop | Ignore |
| Every `DescriptionLabel` | Horizontal Fill; word-smart wrapping | Ignore |
| Every `CostButton` | Minimum width `72`; horizontal Shrink End; vertical Shrink Center | **Stop** |

The ignored labels remain protected by their surrounding `STOP` panel. This includes clicks on the health bar, labels, panel padding, disabled shop buttons, and empty shop background.

The stats blocker is deliberately **content-height**. The rest of `LeftColumn` is transparent to world clicks.

Use the exact theme constants:

```text
MarginContainer:
    margin_left
    margin_top
    margin_right
    margin_bottom

HBoxContainer / VBoxContainer:
    separation
```

These numbers are proposed layout settings, not gameplay constants. Store recurring margins, separations, and styles in a HUD `Theme` `.tres`; expose adjustable dimensions through HUD exports or a layout Resource. Avoid scattering layout numbers through runtime code.

Leave labels and button copy empty until supplied by Garret. Use code comments such as `# TODO(Garret): text`; node names are implementation identifiers, not UI copy.

### Room for the carousel at 1280×720

With the proposed dimensions, assuming content does not force either column wider:

```text
Outer content:       x=16 … 1264
Left column:         x=16 … 236
Spacer:              x=260 … 980
Shop:                x=1004 … 1264
Carousel center:     (640,360)
```

A proposed **300-unit presentation envelope** around the center occupies:

```text
x=340 … 940
y=60  … 660
```

That leaves room for the carousel, booth, enemies near the rim, and their health bars without covering them with the shop. It is a layout budget, not a chosen combat radius.

Keep platform radius, mount radius, booth distance, and spawning distances in exports or Resources. Fit their combined envelope inside this budget during editor review.

The spacer does not position or clip the world. It reserves HUD space only. Enemy spawn positions must separately avoid appearing underneath opaque UI.

## 3. `Enemy.tscn` and `Mount.tscn`

### Enemy: use an `Area2D` root

An `Area2D` is useful even with distance-based clicking: mount ray queries need physics targets.

```text
Enemy (Area2D)                          enemy_base.gd / EnemyBase
├── CollisionShape2D                   CircleShape2D; combat geometry
├── Visual (Node2D)                    placeholder _draw(); may tumble
│   └── Sprite2D                       centered; hidden when texture is null
└── HealthBar (ProgressBar)             local position above enemy
```

Set:

- `input_pickable = false`: central router owns clicks.
- `collision_layer`: named enemy hurtbox layer.
- `collision_mask = 0` if the enemy does not itself scan for overlaps.
- `monitoring = false` if unused.
- `CollisionShape2D.disabled = false`.
- Health bar: `mouse_filter = IGNORE`, `show_percentage = false`, `focus_mode = FOCUS_NONE`.

Disabling input picking does not disable the collision shape for direct physics queries. Picking and collision participation are separate concerns. [Godot CollisionObject2D](https://docs.godotengine.org/en/stable/classes/class_collisionobject2d.html)

Add a separate combat-radius field to `EnemyData` if needed. **Do not reuse click padding as the combat hurtbox.**

The root translates in world space. Animate tumbling on `Visual` alone so the health bar stays upright.

For the bar:

- Anchors: Top Left.
- Size from an exported setting, for example `Vector2(28, 4)`.
- Horizontal position: negative half its width.
- Vertical position: above the visual radius, with an exported gap.
- `max_value` from resolved maximum health; `value` from current runtime health.

A small world-attached health bar is not a responsive HUD layout; positioning it relative to the enemy is appropriate.

If combat shapes are resized at runtime, allocate per-instance shapes or make them local to the scene. Do not mutate one shared `CircleShape2D` and resize every enemy accidentally.

### Mount: use a `Node2D` root

```text
Mount (Node2D)                          mount_base.gd / MountBase
├── Visual (Node2D)                    placeholder _draw()
│   └── Sprite2D                       centered; texture optional
└── SweepOrigin (Marker2D)              at outward attack origin
```

A populated slot owns the mount:

```text
World/Carousel/MountSlots/Slot1/Horse
```

Keep the base scene’s root script as `MountBase`; Horse and Wolf variants can use inherited scenes with scripts extending `MountBase`.

No mount `Area2D` is needed for automatic attacks. Sweep code uses the marker’s global position and the mount’s global orientation. Horse has no attack query.

Mount-info click behavior remains an open routing question; do not add a second independent input handler now.

## 4. Placeholder drawing

Use a small reusable visual script driven by exported values or the existing data Resource fields:

```gdscript
class_name PlaceholderVisual
extends Node2D

@export var radius: float = 12.0
@export_range(3, 32, 1) var vertex_count: int = 6
@export var fill_color: Color = Color.WHITE


func _draw() -> void:
    var vertices: PackedVector2Array = PackedVector2Array()
    for index: int in range(vertex_count):
        var angle: float = TAU * float(index) / float(vertex_count)
        vertices.append(Vector2.RIGHT.rotated(angle) * radius)

    draw_colored_polygon(vertices, fill_color)
```

`TAU`, zero, and index arithmetic are mathematical constants, not balance tunables.

Populate these values from `EnemyData` or `MountData`, then call `queue_redraw()` when they change. Rotation or translation of the node does not require rebuilding its polygon every frame. Custom drawing belongs in `_draw()`, with redraw requests when visual data changes. [Godot CanvasItem drawing](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html#class-canvasitem-method-queue-redraw)

Keep placeholders as simple code-drawn shapes. Do not generate silhouettes, textures, icons, or player-facing text.

## 5. Writing `.tscn` text correctly

New scenes use `format=3`. Omit `uid=` and `unique_id=`; ordinary resource IDs such as `id="1_script"` are still valid and needed for references.

This is a minimal standalone HUD fragment showing correct property spelling and layout modes. It intentionally contains no UI copy:

```ini
[gd_scene format=3]

[node name="HUD" type="CanvasLayer"]
layer = 1

[node name="HUDRoot" type="Control" parent="."]
layout_mode = 0
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2

[node name="ScreenMargin" type="MarginContainer" parent="HUDRoot"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
theme_override_constants/margin_left = 16
theme_override_constants/margin_top = 16
theme_override_constants/margin_right = 16
theme_override_constants/margin_bottom = 16

[node name="Columns" type="HBoxContainer" parent="HUDRoot/ScreenMargin"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
mouse_filter = 2
theme_override_constants/separation = 24

[node name="WorldSpacer" type="Control" parent="HUDRoot/ScreenMargin/Columns"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
mouse_filter = 2

[node name="ShopPanel" type="PanelContainer" parent="HUDRoot/ScreenMargin/Columns"]
custom_minimum_size = Vector2(260, 0)
layout_mode = 2
size_flags_horizontal = 8
size_flags_vertical = 1
mouse_filter = 0
```

Relevant serialized values:

| Property | Value | Meaning |
|---|---:|---|
| `anchors_preset` | `15` | Full Rect |
| `grow_horizontal`, `grow_vertical` | `2` | Both directions |
| `size_flags_*` | `1` | Fill |
| `size_flags_*` | `3` | Expand Fill |
| `size_flags_*` | `8` | Shrink End |
| `mouse_filter` | `0` / `2` | Stop / Ignore |

The root Control has a `CanvasLayer` parent, so `layout_mode = 0` is appropriate; its explicit anchors still define viewport-relative sizing. `ScreenMargin` has a Control parent and uses anchor mode. Container children use mode `2`.

For actual implementation:

1. Put the complete node tree and properties in Claude’s approval plan.
2. Before editing an existing scene, have Garret save and close it, then reread it.
3. Preserve editor changes and existing generated IDs.
4. Run `tools\check.bat` after each change.
5. Ask Garret to open and save new scenes once so Godot assigns IDs.

## 6. Stretch and layout pitfalls

### CanvasLayer is screen space, not physical-pixel space

Keep `HUD` at identity offset/rotation/scale, with `follow_viewport_enabled = false`. A separate CanvasLayer keeps HUD placement independent of world camera transforms, while root viewport stretching still applies. Do not add a manual `window_size / 1280` scale to the HUD. [Godot CanvasLayer](https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html)

`canvas_items` scales the design canvas while rendering at the target resolution. Stretch aspect is a separate setting. **Propose `keep` for the initial fixed 1280×720 composition**, pending approval; `expand` requires testing the wider/taller logical viewport. [Godot multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)

### Full-screen Controls are the most likely input bug

Check every full-screen overlay, including future dimmers and decorative backgrounds. An invisible or transparent `STOP` rectangle can consume every world click.

Conversely, an empty shop area must still block clicks. Its `PanelContainer` supplies that bounded blocker.

Enemy health bars must ignore input, or they can prevent clicking the enemy beneath them.

### Container minimum sizes can move the shop inward

`custom_minimum_size.x = 260` is a minimum, not a maximum. Long names, unwrapped descriptions, large cost text, or theme content margins can force a wider panel.

Wrap descriptions and constrain name overflow. Verify layout with realistic Garret-authored strings and large numeric costs. Do not “fix” overflow by scaling the entire HUD.

### Keep world and UI scale independent of gameplay tuning

Keep `World`, `EnemyLayer`, and enemy roots at unit scale. Change data dimensions rather than scaling enemy roots, otherwise a world-unit click radius can disagree with the visual footprint.

Centering a Node2D does not automatically protect the carousel from HUD overlap. The geometry budget and real text sizes still need editor review.

## 7. GdUnit4 verification

Use `GdUnitTestSuite` with typed assertions. GdUnit4 provides `assert_float`, `assert_int`, and `assert_bool`; these examples use its basic assertion API. [GdUnit4 assertions](https://godot-gdunit-labs.github.io/gdUnit4/latest/testing/assert/)

### Picker and routing tests

The following sketches assume Claude implements:

- `EnemyBase.initialize(data: EnemyData)`, callable before entering the tree.
- `EnemyBase.apply_damage(amount: float)`.
- `EnemyBase.can_receive_click()`.
- The router shown above.

Initialization must establish runtime health without requiring `@onready` visual nodes.

```gdscript
class_name TestClickRouter
extends GdUnitTestSuite

var _enemy_requests: int = 0
var _play_requests: int = 0


func before_test() -> void:
    _enemy_requests = 0
    _play_requests = 0


func _make_enemy(at: Vector2, radius: float) -> EnemyBase:
    var data: EnemyData = EnemyData.new()
    data.base_health = 2.0
    data.click_radius = radius

    var enemy: EnemyBase = auto_free(EnemyBase.new()) as EnemyBase
    enemy.initialize(data)
    enemy.position = at
    return enemy


func _on_enemy_requested(_enemy: EnemyBase) -> void:
    _enemy_requests += 1


func _on_play_requested() -> void:
    _play_requests += 1


func test_click_radius_includes_boundary() -> void:
    var enemy: EnemyBase = _make_enemy(Vector2.ZERO, 10.0)
    var enemies: Array[EnemyBase] = [enemy]

    assert_bool(
        ClickRouter.choose_target(Vector2(10.0, 0.0), enemies, 0.0)
        == enemy
    ).is_true()
    assert_bool(
        ClickRouter.choose_target(Vector2(10.1, 0.0), enemies, 0.0)
        == null
    ).is_true()


func test_radius_bonus_does_not_modify_shared_data() -> void:
    var enemy: EnemyBase = _make_enemy(Vector2.ZERO, 10.0)
    var enemies: Array[EnemyBase] = [enemy]

    assert_bool(
        ClickRouter.choose_target(Vector2(14.0, 0.0), enemies, 4.0)
        == enemy
    ).is_true()
    assert_float(enemy.data.click_radius).is_equal(10.0)


func test_nearest_enemy_wins_even_when_registered_second() -> void:
    var farther: EnemyBase = _make_enemy(Vector2(8.0, 0.0), 20.0)
    var nearer: EnemyBase = _make_enemy(Vector2(3.0, 0.0), 20.0)
    var enemies: Array[EnemyBase] = [farther, nearer]

    assert_bool(
        ClickRouter.choose_target(Vector2.ZERO, enemies, 0.0)
        == nearer
    ).is_true()


func test_enemy_click_emits_no_play_area_request() -> void:
    var router: ClickRouter = auto_free(ClickRouter.new()) as ClickRouter
    var enemy: EnemyBase = _make_enemy(Vector2.ZERO, 10.0)
    router.register_enemy(enemy)
    router.enemy_click_requested.connect(_on_enemy_requested)
    router.play_area_click_requested.connect(_on_play_requested)

    router.route_world_click(Vector2.ZERO)

    assert_int(_enemy_requests).is_equal(1)
    assert_int(_play_requests).is_equal(0)


func test_empty_space_emits_one_play_area_request() -> void:
    var router: ClickRouter = auto_free(ClickRouter.new()) as ClickRouter
    router.enemy_click_requested.connect(_on_enemy_requested)
    router.play_area_click_requested.connect(_on_play_requested)

    router.route_world_click(Vector2.ZERO)

    assert_int(_enemy_requests).is_equal(0)
    assert_int(_play_requests).is_equal(1)


func test_dead_enemy_is_ineligible_before_deferred_free() -> void:
    var enemy: EnemyBase = _make_enemy(Vector2.ZERO, 10.0)

    enemy.apply_damage(2.0)

    assert_bool(enemy.can_receive_click()).is_false()
    assert_float(enemy.data.base_health).is_equal(2.0)
```

Also test exact-distance ties, unregistering an enemy, duplicate registration, and both approaching and latched eligibility.

### GUI propagation requires integration tests

Calling `route_world_click()` directly cannot prove that UI blocks input. Instantiate the planned scene in an isolated viewport, wait for container layout, and inject a complete press/release pair through `Viewport.push_input(event, true)`.

Example injection helper:

```gdscript
func _push_left_click(viewport: Viewport, at: Vector2) -> void:
    var press: InputEventMouseButton = InputEventMouseButton.new()
    press.position = at
    press.global_position = at
    press.button_index = MOUSE_BUTTON_LEFT
    press.pressed = true
    viewport.push_input(press, true)

    var release: InputEventMouseButton = (
        press.duplicate() as InputEventMouseButton
    )
    release.pressed = false
    viewport.push_input(release, true)
```

The `true` argument identifies positions as local to the receiving viewport. Use an attached `SubViewport` with an explicit `1280×720` size and input enabled. [Godot Viewport input injection](https://docs.godotengine.org/en/stable/classes/class_viewport.html#class-viewport-method-push-input)

Required integration cases:

| Case | Assertions |
|---|---|
| Click visible enabled shop button | Button activates once; enemy/play request counts both zero |
| Click disabled button | Both gameplay request counts zero |
| Click empty shop background or padding | Both gameplay request counts zero |
| Click Gold label or carousel health bar | Both gameplay request counts zero |
| Click transparent spacer | Play-area request count increases by one |
| Click below content-height stats panel | Gameplay routing remains available |
| Enemy positioned behind shop | Enemy receives no click damage |
| Click enemy through its health-bar Control | One enemy request; zero play requests |
| Release or right-button event | No gameplay request |
| Two press/release pairs | Exactly two requests |
| Click kills last latched enemy | No boost or click Gold from that same click; normal kill reward allowed |
| Subsequent empty-space click | Boost and click Gold occur |
| Viewport resize | Center and click selection remain aligned |

Use `assert_float` on actual health/Gold changes, `assert_int` on request counts, and `assert_bool` on eligibility and handled-state outcomes. Reset GameState for each fixture and disable wave spawning and rotation where deterministic placement is needed.

After implementation, `tools\check.bat` must pass. Garret should then verify real mouse input at 1280×720 and at one larger window size; headless tests do not establish visual usability.

## Open questions / uncertain

- **Mount-slot clicks:** the GDD requires a mount-info popup but also assigns other play-area clicks to boost. Priority and whether a popup-opening click also boosts are unspecified. Leave this unresolved until Garret decides.
- **Overlap selection:** nearest-center selection with stable registry-order ties is a proposal, not an established GDD rule.
- **Radius semantics:** the proposed click radius uses world/design units and circular targets. Screen-pixel-constant picking under future camera zoom would need a separate decision.
- **Fast-motion presentation:** current simulation positions are assumed sufficient initially. Interpolation-related click disagreement needs playtesting.
- **Stretch aspect:** the supplied project sets `canvas_items` but does not explicitly specify aspect behavior. `keep` is recommended for the first layout.
- **Layout values:** widths, spacing, bar dimensions, and the 300-unit presentation envelope require Garret’s editor review. They are starting values, not settled balance.
- **Document scope:** the requested left column follows Phase 2’s skeleton. The full GDD also requires a tier indicator and later wave controls.
- **Missing context:** the roadmap and notes were referenced but not supplied; no additional rules or decisions from them were assumed.
- **Existing documentation mismatch:** `MountData.base_gold_bonus` still says “before spin-speed scaling.” The approved booth rule is fixed payout per pass; its comment should be corrected in the relevant approved implementation.
- **Verification:** these are Godot 4 API design sketches, checked against official documentation but not compiled or loaded in the project’s Godot 4.7.2 / GdUnit4 6.2.1 environment.
- **DECISION PENDING:** death/fail state and prestige remain untouched.