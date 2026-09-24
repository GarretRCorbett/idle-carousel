# Topic F — Residual rotation jitter

## Assessment

**Keep the current rotation architecture. Test presentation timing and effective interpolation before changing rotation code.**

The supplied code has the right structure: one physics driver, an unwrapped simulation angle, and transform changes on physics ticks. The color-only `_process()` does not inherently interfere with transform interpolation.

The earlier probe establishes steady **engine frame timing for about 9.6 seconds**, before the latest changes. It does not establish steady delivery to the physical display. The improvement from disabling Embed Game makes the window/presentation path a leading suspect, although embedding also changes scaling and workload.

## Ranked causes and distinguishing tests

These rankings are hypotheses based on the supplied evidence.

| Rank | Candidate | How to distinguish it | Action if confirmed |
|---|---|---|---|
| **1** | **Presentation pacing: DWM, mixed-refresh displays, hybrid GPU path, driver overrides** | Repeat the same constant-speed run entirely on each monitor. Record screen, refresh rate, rendering GPU, and window mode. Compare windowed with exclusive fullscreen. Clean engine timing alongside visible pauses points downstream of simulation. | Use the smooth display/window combination as the baseline. Test with only that display active and driver VSync/FPS overrides reset. Rendering on the adapter driving the display may help; verify rather than assume. |
| **2** | **Interpolation disabled somewhere, additional transform writers, or excessive resets** | Check effective interpolation on Carousel and Horse. Temporarily test at **10 physics Hz**: correctly interpolated constant rotation should remain smooth. Count resize/reset events and inspect animation/tween writers. | Correct interpolation inheritance; keep continuous transforms in physics; reset only for actual discontinuities. |
| **3** | **Intentional speed changes perceived as jolts** | Compare a no-input, settled-speed run against clicks/boost decay. Log each emitted angular step. A sudden change in step size is a real velocity change. | No jitter correction required. Smoothing acceleration would change game feel and needs a separate approved design decision. |
| **4** | **Spatial aliasing or ordinary 60 Hz motion stepping** | If only spoke edges shimmer while the Horse moves steadily, compare a larger window, thicker existing spokes, and both pixel-snap settings disabled. | Keep antialiased drawing; consider 2D MSAA only if edge quality improves. Higher display refresh helps temporal stepping. |
| **5** | **Workload spikes: editor, resource loading, allocation/freeing, shader/pipeline compilation** | Record wall-clock intervals and process/physics monitors. Compare editor-open versus editor-closed runs; compare first activation of effects with repeated activations. Correlate booth passage, saves, HUD updates, and spawning. | Optimize the correlated work. Preload/warm resources only when evidence supports it. Compare D3D12 with Vulkan after other variables are controlled. |
| **6** | **Timer/scheduling noise, including phase noise near physics boundaries** | Inspect physics count plus interpolation fraction, not fraction alone. Compare raw wall-clock intervals with `_process(delta)`. A/B 60 versus 120 physics Hz. | Keep delta smoothing enabled initially. Use 120 Hz if consistently beneficial and affordable. Avoid speculative Windows timer-resolution changes. |
| **7** | **±PI wrap or a specific interpolation regression** | Check whether jolts recur at the same orientation. At constant 45°/s, wrap happens first at 4 seconds, then every 8 seconds; at 225°/s, first at 0.8 seconds, then every 1.6 seconds. | Keep wrapping unless a minimal reproduction demonstrates failure. If confirmed, investigate the exact engine build before adopting manual visuals. |

Windows windowed presentation and fullscreen differences are documented concerns, but neither DWM nor Optimus is proven responsible here. [Godot jitter/stutter guidance](https://docs.godotengine.org/en/4.6/tutorials/rendering/jitter_stutter.html)

**Being on the 120 Hz panel is not itself a bug.** With interpolation enabled and rendering at 120 FPS, 60 Hz physics should produce intermediate visual states. Alternating zero/one physics updates per rendered frame is normal.

Likewise, GDScript does **not** have a periodic tracing garbage collector to blame. Allocation, resource destruction, and node deletion can still cost time. [GDScript memory management](https://docs.godotengine.org/en/4.0/tutorials/scripting/gdscript/gdscript_basics.html#memory-management)

## Why fraction wobble alone is inconclusive

Let `N` be the completed physics-tick count and `α` the interpolation fraction. At fixed tick rate, examine:

```text
interpolated simulation coordinate = N - 1 + α
advance between frames            = ΔN + Δα
```

The fraction resetting from nearly one to nearly zero is normal when the tick count advances. Its reset does not imply a backward jump.

For constant angular speed, ordinary interpolation reconstructs continuous rotation despite alternating tick counts. Small timing errors can still alter the sampled position, but **“60 Hz physics equals 60 Hz display” is not sufficient evidence of an interpolation defect**.

At radius 100, 45°/s produces approximately **1.31 pixels of tangential movement per 60 Hz frame**; 225°/s produces **6.54 pixels**. Even perfectly paced high-speed rotation has visible temporal stepping at 60 Hz. Increasing physics frequency cannot add display refreshes.

## Small diagnostic probe

Proposed temporary node, subject to the eventual implementation plan:

```text
Game (Node2D)
├── RotationProbe (Node)           # new diagnostic node
├── World (Node2D)
│   ├── Carousel (Node2D)
│   │   └── MountSlots (Node2D)    # existing descendants unchanged
│   ├── EnemyLayer (Node2D)       # world-space enemies, when present
│   └── TicketBooth
└── HUD
```

Assign `carousel` through the Inspector. The probe uses the existing signal and buffers measurements without printing during capture.

```gdscript
class_name RotationProbe
extends Node

signal capture_finished

const USEC_PER_SECOND: float = 1_000_000.0

@export var carousel: Carousel
@export_range(1, 12000, 1) var sample_limit: int = 1800

var rows: Array[PackedFloat64Array] = []
var _last_usec: int = 0
var _last_tick: int = 0
var _previous_angle: float = 0.0
var _current_angle: float = 0.0


func _ready() -> void:
	_previous_angle = carousel.get_unwrapped_angle()
	_current_angle = _previous_angle
	carousel.rotation_advanced.connect(_on_rotation_advanced)

	var screen: int = DisplayServer.window_get_current_screen()
	print({
		"engine": Engine.get_version_info(),
		"screen": screen,
		"refresh_hz": DisplayServer.screen_get_refresh_rate(screen),
		"gpu": RenderingServer.get_video_adapter_name(),
		"window_mode": DisplayServer.window_get_mode(),
		"vsync": DisplayServer.window_get_vsync_mode(),
		"physics_hz": Engine.physics_ticks_per_second,
		"max_fps": Engine.max_fps,
		"interpolation": carousel.is_physics_interpolated_and_enabled(),
	})
	_last_usec = Time.get_ticks_usec()
	_last_tick = Engine.get_physics_frames()


func _on_rotation_advanced(previous: float, step: float) -> void:
	_previous_angle = previous
	_current_angle = previous + step


func _process(delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	var tick: int = Engine.get_physics_frames()
	var alpha: float = Engine.get_physics_interpolation_fraction()

	# Columns: time_us, wall_s, delta_s, tick, steps, alpha,
	# previous_angle, current_angle, estimated_visual_angle,
	# process_s, physics_s.
	rows.append(PackedFloat64Array([
		float(now),
		float(now - _last_usec) / USEC_PER_SECOND,
		delta,
		float(tick),
		float(tick - _last_tick),
		alpha,
		_previous_angle,
		_current_angle,
		lerpf(_previous_angle, _current_angle, alpha),
		Performance.get_monitor(Performance.TIME_PROCESS),
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
	]))
	_last_usec = now
	_last_tick = tick

	if rows.size() >= sample_limit:
		set_process(false)
		capture_finished.emit()
```

Export/print the buffer **after** capture. Repeat a run without the probe to check instrumentation overhead; preallocate numeric buffers if needed.

Interpretation and limits:

- `_process(delta)` can be smoothed. `Time.get_ticks_usec()` differences measure actual intervals between callbacks.
- Performance monitors describe engine workload, not display scanout; some values update less frequently or are unavailable in release builds. Add `OBJECT_COUNT`, `MEMORY_STATIC`, and `RENDER_TOTAL_DRAW_CALLS_IN_FRAME` if workload spikes appear. [Performance API](https://docs.godotengine.org/en/stable/classes/class_performance.html)
- Record screen metadata again after moving monitors. A refresh result of `-1.0` means unavailable, not 60 Hz. The GPU name identifies the rendering adapter, not the complete presentation route. [DisplayServer API](https://docs.godotengine.org/en/stable/classes/class_displayserver.html)
- Check `is_physics_interpolated_and_enabled()` on Horse as well as Carousel. [Node API](https://docs.godotengine.org/en/4.7/classes/class_node.html#class-node-method-is-physics-interpolated-and-enabled)
- The estimated angle is a diagnostic expectation. **Node2D has no `get_global_transform_interpolated()`**; reading `global_transform` does not retrieve the displayed interpolated transform. [Node2D API](https://docs.godotengine.org/en/4.7/classes/class_node2d.html)
- This signal-based angle estimate assumes continuous nonzero rotation. The current Carousel emits nothing for a zero step; a general manual interpolator must explicitly advance stationary snapshots.

A GDScript probe cannot conclusively diagnose DWM delivery or cross-adapter copies. If internal timing stays clean, use a slow-motion camera or PresentMon. PresentMon exposes displayed-frame duration, presentation mode, and optional hybrid-present tracking. [PresentMon measurement reference](https://github.com/GameTechDev/PresentMon/blob/main/README-ConsoleApplication.md)

## Recommended settings

Use these as a controlled baseline, changing one variable per comparison:

| Setting | Recommendation |
|---|---|
| `physics/common/physics_interpolation` | `true` |
| `physics/common/physics_jitter_fix` | Keep `0.0` |
| `physics/common/physics_ticks_per_second` | Baseline `60`; A/B `120` |
| `display/window/vsync/vsync_mode` | `1` — Enabled |
| `application/run/max_fps` | `0` — let VSync pace rendering |
| `application/run/delta_smoothing` | `true` |
| `application/run/frame_delay_msec` | `0` |
| `application/run/low_processor_mode` | `false` |
| `rendering/2d/snap/snap_2d_transforms_to_pixel` | `false` |
| `rendering/2d/snap/snap_2d_vertices_to_pixel` | `false` |
| `rendering/rendering_device/driver.windows` | Keep `"d3d12"` initially; later A/B `"vulkan"` |
| `rendering/rendering_device/vsync/swapchain_image_count` | Keep default `3` initially |
| `rendering/rendering_device/vsync/frame_queue_size` | Keep default `2` initially |

The 4.7 swapchain setting is under **`rendering/rendering_device/vsync/`**, unlike older documentation paths. Double buffering (`2`) is a latency experiment and may worsen missed-frame behavior. [Godot 4.7 settings reference](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html)

**120 physics Hz is reasonable, but optional.** It halves the interpolation history interval from about 16.7 to 8.3 ms and doubles simulation update frequency. It does not fix compositor stalls. Validate boost decay, income integration, and booth-pass counts before adopting it. [Engine timing API](https://docs.godotengine.org/en/4.7/classes/class_engine.html)

For VSync comparisons:

- Briefly test Disabled to identify sensitivity to presentation pacing; tearing makes it unsuitable as a clean smoothness comparison.
- Try Mailbox only as a separate supported-backend experiment; it can increase rendering work.
- Do not apply a below-refresh FPS cap to a fixed-refresh display by default. That strategy belongs to confirmed VRR operation.
- Keep the existing `canvas_items` stretch baseline. 3D TAA settings will not solve CanvasItem rotation timing.

## Wrap handling and manual visual fallback

The ±PI assignment is **unlikely** to be the cause: orientations immediately before and after the boundary are adjacent. Current upstream 2D interpolation uses `Transform2D.interpolate_with()`; that source is supporting evidence, not verification of Garret’s exact 4.7.2 binary. [Godot interpolation source](https://github.com/godotengine/godot/blob/master/core/math/transform_interpolator.cpp)

Do not reset interpolation on each wrap—that would introduce a discontinuity.

A manual fallback is worth considering **only if clean presentation timing and a minimal reproduction isolate built-in interpolation**. Its essential operation is:

```gdscript
# Inside a proposed visual-only Node2D class.
# Built-in interpolation is OFF on this visual branch.
var previous_angle: float = 0.0
var current_angle: float = 0.0


func accept_physics_snapshot(angle: float) -> void:
	previous_angle = current_angle
	current_angle = angle


func _process(_delta: float) -> void:
	rotation = wrapf(
		lerpf(
			previous_angle,
			current_angle,
			Engine.get_physics_interpolation_fraction()
		),
		-PI,
		PI
	)
```

Requirements for any approved fallback:

- Send a snapshot **every physics tick**, including stationary ticks.
- Initialize/reset both angles together.
- Keep Carousel, gameplay slots, and collision/pass calculations physics-driven.
- Place visual proxies on a separate sibling branch with built-in interpolation disabled; include the Horse visuals so they remain aligned.
- Keep enemies under `World/EnemyLayer`.
- Do not interpolate wrapped scalar angles with ordinary `lerpf`, or independently integrate gameplay rotation in `_process()`.

This adds maintenance cost and retains the same timing fraction. It cannot repair dropped presentation frames.

## Focused GdUnit4 cases

These test rotation correctness, **not monitor smoothness**. Numeric literals below are fixed test fixtures, not gameplay tunables. Assertions follow GdUnit4’s typed API. [GdUnit4 assertions](https://godot-gdunit-labs.github.io/gdUnit4/latest/testing/assert/)

```gdscript
class_name RotationDiagnosisTest
extends GdUnitTestSuite

const EPSILON: float = 0.00001

var _emissions: int = 0


func test_wrap_midpoint_preserves_orientation() -> void:
	var before: Transform2D = Transform2D(
		deg_to_rad(179.0), Vector2.ZERO
	)
	var after: Transform2D = Transform2D(
		deg_to_rad(-179.0), Vector2.ZERO
	)
	var midpoint: Transform2D = before.interpolate_with(after, 0.5)

	assert_float(absf(midpoint.get_rotation())).is_equal_approx(
		PI, EPSILON
	)
	assert_bool(midpoint.x.x < 0.0).is_true()


func test_constant_rotation_at_both_tick_rates() -> void:
	for hz: int in [60, 120]:
		var carousel: Carousel = Carousel.new()
		_emissions = 0
		carousel.rotation_advanced.connect(_count_rotation)

		var duration_seconds: int = 2
		var speed: float = deg_to_rad(225.0)
		var ticks: int = hz * duration_seconds

		for tick: int in range(ticks):
			carousel.advance_rotation(1.0 / float(hz), speed)

		var expected: float = speed * float(duration_seconds)
		assert_float(carousel.get_unwrapped_angle()).is_equal_approx(
			expected, EPSILON
		)
		assert_float(carousel.rotation).is_equal_approx(
			wrapf(expected, -PI, PI), EPSILON
		)
		assert_int(_emissions).is_equal(ticks)
		carousel.free()


func _count_rotation(_previous: float, _step: float) -> void:
	_emissions += 1
```

If manual interpolation is proposed, add stationary-tick, reset, and changing-speed snapshot tests. If 120 Hz becomes permanent, run existing simulation/pass-count tests and `tools\check.bat` after each implementation change.

## Open questions / uncertain

- Which monitor, actual rendering FPS, and GPU were involved in the remaining jolts?
- Are jolts tied to clicks, booth passage, saves, resizing, or a fixed orientation?
- Are there interpolation overrides or transform writers in the omitted Horse/scene files?
- Was the original frame probe measuring raw wall time or `_process(delta)`?
- The supplied material includes three files and summarized rules, but not the full `CLAUDE.md` or GDD. This memo leaves pending design decisions unresolved. No commands, project edits, or tests were run.

### Ordered five-minute checklist

1. **0:00–1:00:** Disable Embed Game. Run entirely on the external 60 Hz display, fixed window size, no clicks after boost settles.
2. **1:00–2:00:** Compare windowed with exclusive fullscreen on that same display.
3. **2:00–3:00:** Repeat on the laptop’s 120 Hz panel. Note whether the whole Horse pauses or only spoke edges shimmer.
4. **3:00–4:00:** On the clearer baseline display, compare 60 and 120 physics Hz with interpolation on, VSync Enabled, and Max FPS `0`.
5. **4:00–5:00:** Restore the better baseline and repeat with the editor closed if an independent launch is available. Record the exact monitor/settings combination; if jolts remain, capture the buffered probe before changing rotation code.