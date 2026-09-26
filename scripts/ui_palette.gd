class_name UiPalette
extends Resource
## Semantic UI colors. Consumed by build_ui_theme.gd; scenery stays independent.

@export var dev_name: String = "Purple Garden"
@export var primary: Color = Color("70568b")
@export var primary_text: Color = Color("fff4dc")
@export var secondary: Color = Color("286466")
@export var danger: Color = Color("993f4f")
@export var health: Color = Color("79c9ae")
@export var gold: Color = Color("ddb96a")
@export var panel: Color = Color("30283e")
@export var border: Color = Color("b6a3cd")
@export var body: Color = Color("fff4dc")
@export var muted: Color = Color("c6bdd0")
@export var disabled: Color = Color("514958")
@export var disabled_text: Color = Color("c6bdd0")
@export var highlight: Color = Color("f4d995")
@export var ink: Color = Color("292333")
@export var track: Color = Color("211c2b")
@export var tab_idle: Color = Color("493b59")
@export var tab_hover: Color = Color("604b74")
## Darkening preserves cream-text contrast in every state.
@export_range(0.0, 1.0) var hover_darkening: float = 0.08
@export_range(0.0, 1.0) var pressed_darkening: float = 0.16
## Gold buttons with dark text need lighter interaction states instead.
@export var lighten_primary_states: bool = false
