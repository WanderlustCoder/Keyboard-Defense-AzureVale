extends PanelContainer
class_name LyraDialogue
## Dialogue box with Lyra portrait - ONLY used by BattleTutorial.gd
## NOTE: KingdomDefense mode uses game/dialogue_box.gd instead!
## If fixing Lyra's portrait in Kingdom Defense, edit game/dialogue_box.gd

const AssetLoader = preload("res://game/asset_loader.gd")

signal dialogue_finished
signal dialogue_advanced

@export var typewriter_speed: float = 0.03
@export var auto_advance_delay: float = 0.0

var _full_text: String = ""
var _visible_chars: int = 0
var _is_typing: bool = false
var _can_advance: bool = false
var _dialogue_queue: Array[Dictionary] = []
var _auto_advance_pending: bool = false
var _asset_loader: AssetLoader = null

@onready var portrait: TextureRect = $Content/PortraitFrame/Portrait
@onready var name_label: Label = $Content/TextBox/NameLabel
@onready var dialogue_label: RichTextLabel = $Content/TextBox/DialogueLabel
@onready var continue_hint: Label = $Content/TextBox/ContinueHint
@onready var audio_manager = get_node_or_null("/root/AudioManager")

func _ready() -> void:
	visible = false
	continue_hint.visible = false
	_asset_loader = AssetLoader.new()
	_asset_loader._load_manifest()
	_load_lyra_portrait()
	# Ensure portrait is visible
	portrait.visible = true

func _load_lyra_portrait() -> void:
	# Try asset loader first
	if _asset_loader != null:
		var tex := _asset_loader.get_texture("portrait_lyra")
		if tex != null:
			portrait.texture = tex
			return

	# Try direct load
	if ResourceLoader.exists("res://assets/art/src-svg/portraits/portrait_lyra_framed.svg"):
		var tex := load("res://assets/art/src-svg/portraits/portrait_lyra_framed.svg") as Texture2D
		if tex != null:
			portrait.texture = tex
			return

	# Final fallback: create procedural portrait
	portrait.texture = _create_lyra_portrait()

func _create_lyra_portrait() -> ImageTexture:
	## Creates Elder Lyra's portrait procedurally (64x64 detailed pixel art with frame)
	## Iteration 4: Complete refinement - matches portrait_lyra_framed.svg
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)

	# Frame colors
	var frame_outer := Color("#1a1a2e")
	var frame_gold := Color("#d4ac0d")
	var frame_gold_light := Color("#f4d03f")
	var frame_gold_dark := Color("#9a7b0a")
	var frame_inner := Color("#2c1810")

	# Background colors
	var bg_dark := Color("#1a0a2e")
	var bg_mid := Color("#201535")
	var bg_mid2 := Color("#281a42")
	var bg_accent := Color("#352350")
	var bg_glow1 := Color("#402a5a")
	var bg_glow2 := Color("#4a3570")
	var bg_glow3 := Color("#5a4580")

	# Hair colors - cooler silvers
	var hair_shadow := Color("#5a6575")
	var hair_base := Color("#6a7585")
	var hair_dark := Color("#7a8595")
	var hair_mid := Color("#8a95a5")
	var hair_light := Color("#9aa5b5")
	var hair_lighter := Color("#aab5c5")
	var hair_bright := Color("#bac5d0")
	var hair_brightest := Color("#d0dae5")
	var hair_shine := Color("#e8f0f8")

	# Skin colors
	var skin_shadow := Color("#ddd0c5")
	var skin_base := Color("#e5d5c5")
	var skin_contour := Color("#e8dcd0")
	var skin := Color("#f5e8db")
	var skin_soft := Color("#f0e3d5")
	var skin_highlight := Color("#faf3eb")

	# Blush colors
	var blush := Color("#f5dcd5")
	var blush_deep := Color("#f0d0c8")
	var inner_corner_pink := Color("#f5dcd5")

	# Eye colors
	var eye_white := Color("#fafafa")
	var eyelid := Color("#8878a0")
	var eyelid_lower := Color("#a098b0")
	var lash := Color("#504860")
	var iris_deepest := Color("#5b2878")
	var iris_outer := Color("#7b3898")
	var iris_mid := Color("#9548b8")
	var iris_shine := Color("#c8a0d8")
	var pupil := Color("#1a1525")

	# Brow colors
	var brow := Color("#8a95a5")

	# Wisdom line colors
	var wisdom_line := Color("#e0d5c8")

	# Nose colors
	var nose_shadow := Color("#ead8cc")
	var nostril := Color("#d0c5b8")

	# Lip colors
	var lip_upper := Color("#c08888")
	var lip_upper_light := Color("#d09898")
	var lip := Color("#d8a0a0")
	var lip_mid := Color("#e0b0b0")
	var lip_light := Color("#e8c0c0")
	var lip_highlight := Color("#f0d0d0")

	# Robe colors
	var robe_deepest := Color("#3a1848")
	var robe_dark := Color("#4a2058")
	var robe_mid2 := Color("#5a2868")
	var robe_mid := Color("#6a3078")
	var robe_light := Color("#7a3888")
	var robe_lighter := Color("#8a4098")
	var robe_highlight := Color("#9a48a8")
	var robe_brightest := Color("#aa58b8")
	var trim_darkest := Color("#9a7b0a")
	var trim_dark := Color("#b8960b")
	var trim := Color("#d4ac0d")
	var trim_light := Color("#f4d03f")

	# Gem colors
	var gem_dark := Color("#1a5276")
	var gem := Color("#2980b9")
	var gem_light := Color("#5dade2")
	var gem_sparkle := Color("#85c1e9")

	# Magic colors
	var magic := Color("#9a48a8")
	var magic_light := Color("#d8c0e8")
	var magic_sparkle := Color("#aa58b8")

	# === OUTER FRAME ===
	img.fill(frame_outer)
	_fill_rect(img, 1, 1, 62, 62, frame_gold_dark)
	_fill_rect(img, 2, 2, 60, 60, frame_gold)
	_fill_rect(img, 3, 3, 58, 58, frame_gold_light)
	_fill_rect(img, 2, 2, 60, 1, frame_gold_light)
	_fill_rect(img, 2, 2, 1, 60, frame_gold_light)
	_fill_rect(img, 3, 61, 60, 1, frame_gold_dark)
	_fill_rect(img, 61, 3, 1, 58, frame_gold_dark)

	# Corner ornaments with purple gems
	# Top-left
	_fill_rect(img, 1, 1, 5, 5, frame_gold_light)
	_fill_rect(img, 2, 2, 3, 3, frame_gold)
	_fill_rect(img, 2, 2, 2, 2, robe_light)
	_fill_rect(img, 2, 2, 1, 1, magic_light)
	# Top-right
	_fill_rect(img, 58, 1, 5, 5, frame_gold_light)
	_fill_rect(img, 59, 2, 3, 3, frame_gold)
	_fill_rect(img, 60, 2, 2, 2, robe_light)
	_fill_rect(img, 61, 2, 1, 1, magic_light)
	# Bottom-left
	_fill_rect(img, 1, 58, 5, 5, frame_gold_light)
	_fill_rect(img, 2, 59, 3, 3, frame_gold)
	_fill_rect(img, 2, 60, 2, 2, robe_light)
	_fill_rect(img, 2, 61, 1, 1, magic_light)
	# Bottom-right
	_fill_rect(img, 58, 58, 5, 5, frame_gold_light)
	_fill_rect(img, 59, 59, 3, 3, frame_gold)
	_fill_rect(img, 60, 60, 2, 2, robe_light)
	_fill_rect(img, 61, 61, 1, 1, magic_light)

	# Inner border
	_fill_rect(img, 4, 4, 56, 56, frame_inner)

	# === BACKGROUND ===
	_fill_rect(img, 5, 5, 54, 54, bg_dark)
	_fill_rect(img, 5, 5, 54, 30, bg_mid)
	_fill_rect(img, 5, 5, 54, 20, bg_mid2)
	_fill_rect(img, 5, 5, 54, 10, bg_accent)

	# Halo glow behind head
	_fill_rect(img, 18, 8, 28, 18, bg_accent)
	_fill_rect(img, 20, 10, 24, 14, bg_glow1)
	_fill_rect(img, 23, 12, 18, 10, bg_glow2)
	_fill_rect(img, 27, 14, 10, 6, bg_glow3)

	# === HAIR - Curly silver, past shoulders ===
	# Left hair mass - base
	_fill_rect(img, 10, 12, 10, 38, hair_base)
	_fill_rect(img, 11, 13, 8, 36, hair_dark)
	_fill_rect(img, 12, 14, 6, 34, hair_mid)

	# Left curls - wave pattern
	_fill_rect(img, 8, 16, 3, 5, hair_dark)
	_fill_rect(img, 9, 17, 2, 3, hair_mid)
	_fill_rect(img, 8, 24, 3, 5, hair_dark)
	_fill_rect(img, 9, 25, 2, 3, hair_mid)
	_fill_rect(img, 8, 32, 3, 5, hair_dark)
	_fill_rect(img, 9, 33, 2, 3, hair_mid)
	_fill_rect(img, 8, 40, 3, 6, hair_dark)
	_fill_rect(img, 9, 41, 2, 4, hair_mid)

	# Left inner curl highlights
	_fill_rect(img, 13, 18, 3, 4, hair_light)
	_fill_rect(img, 14, 19, 2, 2, hair_lighter)
	_fill_rect(img, 13, 26, 3, 4, hair_light)
	_fill_rect(img, 14, 27, 2, 2, hair_lighter)
	_fill_rect(img, 13, 34, 3, 4, hair_light)
	_fill_rect(img, 14, 35, 2, 2, hair_lighter)

	# Left shimmer highlights
	_fill_rect(img, 10, 17, 2, 1, hair_shine)
	_fill_rect(img, 12, 25, 2, 1, hair_shine)
	_fill_rect(img, 10, 33, 2, 1, hair_shine)
	_fill_rect(img, 12, 41, 2, 1, hair_shine)

	# Left tips - curly ends past shoulders
	_fill_rect(img, 9, 46, 8, 4, hair_dark)
	_fill_rect(img, 10, 47, 6, 3, hair_mid)
	_fill_rect(img, 11, 48, 4, 2, hair_light)
	_fill_rect(img, 8, 48, 2, 4, hair_dark)
	_fill_rect(img, 9, 49, 2, 3, hair_mid)
	_fill_rect(img, 12, 50, 3, 2, hair_mid)
	_fill_rect(img, 13, 51, 2, 1, hair_light)

	# Right hair mass - base
	_fill_rect(img, 44, 12, 10, 38, hair_base)
	_fill_rect(img, 45, 13, 8, 36, hair_dark)
	_fill_rect(img, 46, 14, 6, 34, hair_mid)

	# Right curls - wave pattern
	_fill_rect(img, 53, 16, 3, 5, hair_dark)
	_fill_rect(img, 53, 17, 2, 3, hair_mid)
	_fill_rect(img, 53, 24, 3, 5, hair_dark)
	_fill_rect(img, 53, 25, 2, 3, hair_mid)
	_fill_rect(img, 53, 32, 3, 5, hair_dark)
	_fill_rect(img, 53, 33, 2, 3, hair_mid)
	_fill_rect(img, 53, 40, 3, 6, hair_dark)
	_fill_rect(img, 53, 41, 2, 4, hair_mid)

	# Right inner curl highlights
	_fill_rect(img, 48, 18, 3, 4, hair_light)
	_fill_rect(img, 48, 19, 2, 2, hair_lighter)
	_fill_rect(img, 48, 26, 3, 4, hair_light)
	_fill_rect(img, 48, 27, 2, 2, hair_lighter)
	_fill_rect(img, 48, 34, 3, 4, hair_light)
	_fill_rect(img, 48, 35, 2, 2, hair_lighter)

	# Right shimmer highlights
	_fill_rect(img, 52, 17, 2, 1, hair_shine)
	_fill_rect(img, 50, 25, 2, 1, hair_shine)
	_fill_rect(img, 52, 33, 2, 1, hair_shine)
	_fill_rect(img, 50, 41, 2, 1, hair_shine)

	# Right tips - curly ends past shoulders
	_fill_rect(img, 47, 46, 8, 4, hair_dark)
	_fill_rect(img, 48, 47, 6, 3, hair_mid)
	_fill_rect(img, 49, 48, 4, 2, hair_light)
	_fill_rect(img, 54, 48, 2, 4, hair_dark)
	_fill_rect(img, 53, 49, 2, 3, hair_mid)
	_fill_rect(img, 49, 50, 3, 2, hair_mid)
	_fill_rect(img, 49, 51, 2, 1, hair_light)

	# Top hair - with subtle wave
	_fill_rect(img, 18, 7, 28, 10, hair_base)
	_fill_rect(img, 20, 8, 24, 8, hair_dark)
	_fill_rect(img, 22, 9, 20, 6, hair_mid)
	_fill_rect(img, 25, 10, 14, 4, hair_light)
	_fill_rect(img, 28, 11, 8, 2, hair_lighter)

	# Top highlights
	_fill_rect(img, 25, 9, 4, 1, hair_shine)
	_fill_rect(img, 35, 10, 3, 1, hair_shine)

	# Hair part
	_fill_rect(img, 31, 8, 2, 4, hair_shadow)
	_fill_rect(img, 31, 12, 2, 1, hair_mid)

	# Face-framing curls
	_fill_rect(img, 19, 14, 2, 7, hair_light)
	_fill_rect(img, 20, 15, 1, 5, hair_lighter)
	_fill_rect(img, 18, 18, 2, 3, hair_mid)
	_fill_rect(img, 43, 14, 2, 7, hair_light)
	_fill_rect(img, 43, 15, 1, 5, hair_lighter)
	_fill_rect(img, 44, 18, 2, 3, hair_mid)
	# Fill gaps between curls and face (above and below ears)
	_fill_rect(img, 20, 21, 1, 3, hair_mid)   # Left, above ear
	_fill_rect(img, 20, 28, 1, 16, hair_mid)  # Left, below ear to robe
	_fill_rect(img, 43, 21, 1, 3, hair_mid)   # Right, above ear
	_fill_rect(img, 43, 28, 1, 16, hair_mid)  # Right, below ear to robe

	# === FACE ===
	# Base face shape
	_fill_rect(img, 21, 13, 22, 24, skin_base)

	# Forehead corners (hair overlap)
	_fill_rect(img, 21, 13, 3, 3, hair_mid)
	_fill_rect(img, 40, 13, 3, 3, hair_mid)
	_fill_rect(img, 22, 14, 2, 2, hair_light)
	_fill_rect(img, 40, 14, 2, 2, hair_light)
	_fill_rect(img, 23, 15, 1, 1, hair_lighter)
	_fill_rect(img, 40, 15, 1, 1, hair_lighter)

	# Jaw taper - extends down to meet collar
	_fill_rect(img, 21, 33, 4, 5, hair_mid)
	_fill_rect(img, 39, 33, 4, 5, hair_mid)
	_fill_rect(img, 22, 33, 3, 4, hair_light)
	_fill_rect(img, 39, 33, 3, 4, hair_light)
	_fill_rect(img, 23, 34, 2, 2, hair_lighter)
	_fill_rect(img, 39, 34, 2, 2, hair_lighter)
	_fill_rect(img, 21, 37, 5, 7, hair_mid)
	_fill_rect(img, 38, 37, 5, 7, hair_mid)
	_fill_rect(img, 22, 38, 4, 6, hair_light)
	_fill_rect(img, 38, 38, 4, 6, hair_light)

	# Main skin
	_fill_rect(img, 23, 15, 18, 22, skin)
	_fill_rect(img, 22, 17, 1, 16, skin_soft)
	_fill_rect(img, 41, 17, 1, 16, skin_soft)

	# Face highlight
	_fill_rect(img, 26, 17, 12, 12, skin_highlight)
	_fill_rect(img, 28, 16, 8, 2, skin_highlight)

	# Temple shadows
	_fill_rect(img, 23, 17, 2, 5, skin_contour)
	_fill_rect(img, 39, 17, 2, 5, skin_contour)

	# Cheek contour
	_fill_rect(img, 23, 24, 2, 6, skin_contour)
	_fill_rect(img, 39, 24, 2, 6, skin_contour)

	# Cheekbone highlights
	_fill_rect(img, 25, 25, 2, 2, skin_highlight)
	_fill_rect(img, 37, 25, 2, 2, skin_highlight)

	# Blush
	_fill_rect(img, 24, 27, 4, 3, blush)
	_fill_rect(img, 36, 27, 4, 3, blush)
	_fill_rect(img, 25, 28, 2, 1, blush_deep)
	_fill_rect(img, 37, 28, 2, 1, blush_deep)

	# Chin - wider, more natural taper
	_fill_rect(img, 24, 35, 16, 2, skin_soft)
	_fill_rect(img, 25, 37, 14, 2, skin_soft)
	_fill_rect(img, 26, 39, 12, 2, skin_soft)
	_fill_rect(img, 27, 39, 10, 2, skin)
	_fill_rect(img, 28, 40, 8, 1, skin)
	_fill_rect(img, 30, 40, 4, 1, skin_highlight)

	# Jaw shadow - subtle
	_fill_rect(img, 25, 34, 2, 2, skin_shadow)
	_fill_rect(img, 37, 34, 2, 2, skin_shadow)

	# === NECK ===
	# Tapered neck - narrower at bottom
	_fill_rect(img, 26, 41, 12, 2, skin_soft)  # Widened to cover dark edges
	_fill_rect(img, 27, 41, 10, 2, skin)
	_fill_rect(img, 28, 41, 8, 1, skin)
	_fill_rect(img, 29, 41, 6, 1, skin_highlight)

	# === EARS ===
	# Left ear - small, partially hidden by hair
	_fill_rect(img, 20, 24, 2, 4, skin_soft)
	_fill_rect(img, 20, 25, 1, 2, skin_contour)
	# Right ear
	_fill_rect(img, 42, 24, 2, 4, skin_soft)
	_fill_rect(img, 43, 25, 1, 2, skin_contour)

	# Earrings - simple elegant drops
	_fill_rect(img, 20, 28, 1, 1, trim)
	_fill_rect(img, 20, 29, 1, 1, gem_light)
	_fill_rect(img, 43, 28, 1, 1, trim)
	_fill_rect(img, 43, 29, 1, 1, gem_light)

	# === EYES ===
	# Subtle eye shadow (purple tint for magical look)
	_fill_rect(img, 24, 20, 7, 2, eyelid_lower)
	_fill_rect(img, 33, 20, 7, 2, eyelid_lower)

	# Left eye white - slightly larger
	_fill_rect(img, 24, 22, 7, 5, eye_white)
	# Left eye corners - softer blend
	_fill_rect(img, 24, 22, 1, 1, skin_soft)
	_fill_rect(img, 30, 22, 1, 1, skin_soft)
	_fill_rect(img, 24, 26, 1, 1, skin_soft)
	_fill_rect(img, 30, 26, 1, 1, skin_soft)
	_fill_rect(img, 24, 23, 1, 1, inner_corner_pink)
	_fill_rect(img, 24, 24, 1, 1, inner_corner_pink)
	_fill_rect(img, 24, 25, 1, 1, inner_corner_pink)
	# Left iris - larger with more depth
	_fill_rect(img, 25, 22, 5, 5, iris_deepest)
	_fill_rect(img, 25, 22, 4, 4, iris_outer)
	_fill_rect(img, 26, 23, 3, 3, iris_mid)
	_fill_rect(img, 26, 23, 2, 2, iris_outer)
	# Left pupil - with depth
	_fill_rect(img, 27, 24, 2, 2, pupil)
	_fill_rect(img, 27, 24, 1, 1, Color("#0d0a12"))
	# Left iris ring highlight
	_fill_rect(img, 25, 23, 1, 2, iris_shine)
	_fill_rect(img, 29, 24, 1, 2, iris_mid)
	# Left eye sparkles - multiple catchlights
	_fill_rect(img, 25, 22, 2, 1, eye_white)
	_fill_rect(img, 26, 23, 1, 1, eye_white)
	_fill_rect(img, 28, 25, 1, 1, iris_shine)
	_fill_rect(img, 29, 23, 1, 1, iris_shine)
	# Left eyelid - more depth
	_fill_rect(img, 24, 21, 7, 1, eyelid)
	_fill_rect(img, 25, 21, 5, 1, Color("#706088"))
	_fill_rect(img, 26, 22, 3, 1, eyelid)
	# Left lower lid - subtle
	_fill_rect(img, 25, 27, 5, 1, eyelid_lower)
	_fill_rect(img, 26, 27, 3, 1, skin_contour)
	# Left lashes - fuller, varied
	_fill_rect(img, 24, 20, 1, 1, lash)
	_fill_rect(img, 25, 20, 1, 1, lash)
	_fill_rect(img, 26, 21, 1, 1, lash)
	_fill_rect(img, 27, 20, 1, 1, lash)
	_fill_rect(img, 28, 21, 1, 1, lash)
	_fill_rect(img, 29, 20, 1, 1, lash)
	_fill_rect(img, 30, 20, 1, 1, lash)

	# Right eye white - slightly larger
	_fill_rect(img, 33, 22, 7, 5, eye_white)
	# Right eye corners - softer blend
	_fill_rect(img, 33, 22, 1, 1, skin_soft)
	_fill_rect(img, 39, 22, 1, 1, skin_soft)
	_fill_rect(img, 33, 26, 1, 1, skin_soft)
	_fill_rect(img, 39, 26, 1, 1, skin_soft)
	_fill_rect(img, 39, 23, 1, 1, inner_corner_pink)
	_fill_rect(img, 39, 24, 1, 1, inner_corner_pink)
	_fill_rect(img, 39, 25, 1, 1, inner_corner_pink)
	# Right iris - larger with more depth
	_fill_rect(img, 34, 22, 5, 5, iris_deepest)
	_fill_rect(img, 35, 22, 4, 4, iris_outer)
	_fill_rect(img, 35, 23, 3, 3, iris_mid)
	_fill_rect(img, 36, 23, 2, 2, iris_outer)
	# Right pupil - with depth
	_fill_rect(img, 36, 24, 2, 2, pupil)
	_fill_rect(img, 37, 24, 1, 1, Color("#0d0a12"))
	# Right iris ring highlight
	_fill_rect(img, 38, 23, 1, 2, iris_shine)
	_fill_rect(img, 34, 24, 1, 2, iris_mid)
	# Right eye sparkles - multiple catchlights
	_fill_rect(img, 37, 22, 2, 1, eye_white)
	_fill_rect(img, 37, 23, 1, 1, eye_white)
	_fill_rect(img, 35, 25, 1, 1, iris_shine)
	_fill_rect(img, 34, 23, 1, 1, iris_shine)
	# Right eyelid - more depth
	_fill_rect(img, 33, 21, 7, 1, eyelid)
	_fill_rect(img, 34, 21, 5, 1, Color("#706088"))
	_fill_rect(img, 35, 22, 3, 1, eyelid)
	# Right lower lid - subtle
	_fill_rect(img, 34, 27, 5, 1, eyelid_lower)
	_fill_rect(img, 35, 27, 3, 1, skin_contour)
	# Right lashes - fuller, varied
	_fill_rect(img, 33, 20, 1, 1, lash)
	_fill_rect(img, 34, 20, 1, 1, lash)
	_fill_rect(img, 35, 21, 1, 1, lash)
	_fill_rect(img, 36, 20, 1, 1, lash)
	_fill_rect(img, 37, 21, 1, 1, lash)
	_fill_rect(img, 38, 20, 1, 1, lash)
	_fill_rect(img, 39, 20, 1, 1, lash)

	# === EYEBROWS ===
	# Very thin, delicate silver brows
	_fill_rect(img, 25, 19, 4, 1, brow)
	_fill_rect(img, 35, 19, 4, 1, brow)

	# === WISDOM LINES ===
	# Crow's feet - gentle, wise
	_fill_rect(img, 22, 23, 1, 1, wisdom_line)
	_fill_rect(img, 22, 25, 1, 1, wisdom_line)
	_fill_rect(img, 21, 24, 1, 1, wisdom_line)
	_fill_rect(img, 41, 23, 1, 1, wisdom_line)
	_fill_rect(img, 41, 25, 1, 1, wisdom_line)
	_fill_rect(img, 42, 24, 1, 1, wisdom_line)

	# === NOSE ===
	# Bridge - elegant and refined
	_fill_rect(img, 31, 27, 2, 2, skin_soft)
	_fill_rect(img, 31, 27, 1, 2, skin_highlight)  # Bridge highlight
	_fill_rect(img, 32, 27, 1, 2, nose_shadow)     # Bridge shadow

	# Mid nose
	_fill_rect(img, 30, 29, 4, 2, skin_soft)
	_fill_rect(img, 31, 29, 2, 2, skin)
	_fill_rect(img, 31, 29, 1, 2, skin_highlight)  # Center highlight
	_fill_rect(img, 33, 29, 1, 2, nose_shadow)     # Right shadow

	# Nose tip - rounded
	_fill_rect(img, 29, 31, 6, 1, skin_soft)
	_fill_rect(img, 30, 31, 4, 1, skin)
	_fill_rect(img, 31, 31, 2, 1, skin_highlight)  # Tip highlight
	_fill_rect(img, 29, 31, 1, 1, skin_contour)    # Left edge
	_fill_rect(img, 34, 31, 1, 1, skin_contour)    # Right edge

	# Nostrils - subtle
	_fill_rect(img, 29, 32, 2, 1, nose_shadow)
	_fill_rect(img, 33, 32, 2, 1, nose_shadow)
	_fill_rect(img, 30, 32, 1, 1, nostril)         # Left nostril
	_fill_rect(img, 33, 32, 1, 1, nostril)         # Right nostril

	# Under nose shadow
	_fill_rect(img, 30, 32, 4, 1, skin_shadow)

	# === LIPS ===
	# Upper lip - thin, elegant
	_fill_rect(img, 29, 33, 6, 1, lip_upper)
	_fill_rect(img, 30, 33, 4, 1, lip)
	_fill_rect(img, 31, 33, 2, 1, lip_upper_light)

	# Lower lip - thin
	_fill_rect(img, 29, 34, 6, 1, lip)
	_fill_rect(img, 30, 34, 4, 1, lip_mid)
	_fill_rect(img, 31, 34, 2, 1, lip_highlight)

	# Lip corners
	_fill_rect(img, 28, 33, 1, 1, skin_contour)
	_fill_rect(img, 35, 33, 1, 1, skin_contour)

	# === ROBE ===
	# Main body with rich fabric layers
	_fill_rect(img, 12, 44, 40, 16, robe_dark)
	_fill_rect(img, 14, 45, 36, 14, robe_mid2)
	_fill_rect(img, 16, 46, 32, 12, robe_mid)
	_fill_rect(img, 20, 48, 24, 8, robe_light)

	# Shoulders - natural sloped shape
	# Left shoulder - slopes down from neck
	_fill_rect(img, 16, 44, 8, 3, robe_mid)
	_fill_rect(img, 14, 45, 4, 4, robe_mid2)
	_fill_rect(img, 12, 47, 4, 5, robe_dark)
	_fill_rect(img, 10, 49, 4, 6, robe_dark)
	_fill_rect(img, 8, 51, 4, 6, robe_deepest)
	# Left shoulder highlight
	_fill_rect(img, 17, 44, 5, 2, robe_light)
	_fill_rect(img, 15, 46, 3, 2, robe_mid)

	# Right shoulder - slopes down from neck
	_fill_rect(img, 40, 44, 8, 3, robe_mid)
	_fill_rect(img, 46, 45, 4, 4, robe_mid2)
	_fill_rect(img, 48, 47, 4, 5, robe_dark)
	_fill_rect(img, 50, 49, 4, 6, robe_dark)
	_fill_rect(img, 52, 51, 4, 6, robe_deepest)
	# Right shoulder highlight
	_fill_rect(img, 42, 44, 5, 2, robe_light)
	_fill_rect(img, 46, 46, 3, 2, robe_mid)

	# V-neck collar - narrow at y=43 to match neck, wider below
	_fill_rect(img, 24, 44, 16, 5, robe_light)
	_fill_rect(img, 25, 44, 14, 4, robe_lighter)
	_fill_rect(img, 27, 43, 10, 5, skin_contour)
	_fill_rect(img, 28, 43, 8, 4, skin_soft)
	_fill_rect(img, 29, 43, 6, 2, skin)

	# Collar gold trim - V-shape (starts at y=44, below neck)
	_fill_rect(img, 24, 44, 2, 5, trim_dark)
	_fill_rect(img, 38, 44, 2, 5, trim_dark)
	_fill_rect(img, 25, 45, 1, 4, trim)
	_fill_rect(img, 38, 45, 1, 4, trim)
	_fill_rect(img, 26, 46, 1, 3, trim_dark)
	_fill_rect(img, 37, 46, 1, 3, trim_dark)
	_fill_rect(img, 25, 44, 1, 1, trim_light)
	_fill_rect(img, 38, 44, 1, 1, trim_light)

	# Center panel with embroidered pattern
	_fill_rect(img, 28, 49, 8, 8, robe_lighter)
	_fill_rect(img, 29, 50, 6, 6, robe_highlight)
	_fill_rect(img, 30, 51, 4, 4, robe_brightest)
	# Embroidery details
	_fill_rect(img, 31, 50, 2, 1, trim)
	_fill_rect(img, 30, 52, 1, 2, trim_dark)
	_fill_rect(img, 33, 52, 1, 2, trim_dark)
	_fill_rect(img, 31, 54, 2, 1, trim)

	# Side panels - fabric folds
	_fill_rect(img, 17, 50, 3, 6, robe_deepest)
	_fill_rect(img, 18, 51, 2, 4, robe_dark)
	_fill_rect(img, 44, 50, 3, 6, robe_deepest)
	_fill_rect(img, 44, 51, 2, 4, robe_dark)

	# Drape folds - more natural
	_fill_rect(img, 21, 52, 2, 5, robe_deepest)
	_fill_rect(img, 22, 53, 1, 3, robe_dark)
	_fill_rect(img, 35, 53, 2, 4, robe_deepest)
	_fill_rect(img, 36, 54, 1, 2, robe_dark)
	_fill_rect(img, 41, 52, 2, 5, robe_deepest)
	_fill_rect(img, 41, 53, 1, 3, robe_dark)

	# Bottom hem - decorative border
	_fill_rect(img, 12, 58, 40, 2, trim_darkest)
	_fill_rect(img, 14, 58, 36, 1, trim_dark)
	_fill_rect(img, 16, 58, 32, 1, trim)
	# Hem pattern dots
	_fill_rect(img, 18, 58, 1, 1, trim_light)
	_fill_rect(img, 24, 58, 1, 1, trim_light)
	_fill_rect(img, 30, 58, 1, 1, trim_light)
	_fill_rect(img, 36, 58, 1, 1, trim_light)
	_fill_rect(img, 42, 58, 1, 1, trim_light)

	# === NECKLACE ===
	# Chain sits on collar, curves down to pendant
	# Left chain - on collar
	_fill_rect(img, 26, 43, 1, 1, trim_dark)  # Extend chain to cover dark edge
	_fill_rect(img, 27, 44, 1, 1, trim_dark)
	_fill_rect(img, 28, 44, 1, 1, trim)
	_fill_rect(img, 29, 45, 1, 1, trim_dark)
	_fill_rect(img, 30, 45, 1, 1, trim)
	_fill_rect(img, 30, 46, 1, 1, trim_light)
	_fill_rect(img, 31, 46, 1, 1, trim)
	# Right chain - on collar
	_fill_rect(img, 37, 43, 1, 1, trim_dark)  # Extend chain to cover dark edge
	_fill_rect(img, 36, 44, 1, 1, trim_dark)
	_fill_rect(img, 35, 44, 1, 1, trim)
	_fill_rect(img, 34, 45, 1, 1, trim_dark)
	_fill_rect(img, 33, 45, 1, 1, trim)
	_fill_rect(img, 33, 46, 1, 1, trim_light)
	_fill_rect(img, 32, 46, 1, 1, trim)
	# Center chain drop to pendant
	_fill_rect(img, 31, 47, 2, 1, trim)
	_fill_rect(img, 31, 47, 1, 1, trim_light)

	# Pendant frame - ornate gold setting
	_fill_rect(img, 29, 48, 6, 7, robe_deepest)  # Shadow behind
	_fill_rect(img, 29, 48, 6, 6, trim_darkest)  # Outer gold frame
	_fill_rect(img, 30, 49, 4, 4, trim_dark)     # Inner gold frame
	_fill_rect(img, 30, 49, 4, 1, trim)          # Top edge highlight
	_fill_rect(img, 30, 49, 1, 4, trim)          # Left edge highlight
	# Filigree corners
	_fill_rect(img, 29, 48, 1, 1, trim_light)    # Top-left
	_fill_rect(img, 34, 48, 1, 1, trim_light)    # Top-right
	_fill_rect(img, 29, 53, 1, 1, trim)          # Bottom-left
	_fill_rect(img, 34, 53, 1, 1, trim)          # Bottom-right

	# Gem - larger 3x3 with depth
	_fill_rect(img, 30, 50, 4, 3, gem_dark)      # Gem base/shadow
	_fill_rect(img, 30, 50, 3, 2, gem)           # Main gem color
	_fill_rect(img, 31, 50, 2, 2, gem_light)     # Inner light
	_fill_rect(img, 31, 50, 1, 1, gem_sparkle)   # Bright sparkle
	_fill_rect(img, 32, 51, 1, 1, gem)           # Depth detail

	# Magical glow around pendant
	_fill_rect(img, 28, 49, 1, 4, magic)
	_fill_rect(img, 35, 49, 1, 4, magic)
	_fill_rect(img, 29, 54, 6, 1, magic)
	_fill_rect(img, 31, 54, 2, 1, magic_light)

	# === SPARKLES ===
	_fill_rect(img, 7, 8, 2, 2, magic)
	_fill_rect(img, 8, 9, 1, 1, magic_light)
	_fill_rect(img, 55, 9, 2, 2, magic)
	_fill_rect(img, 56, 10, 1, 1, magic_light)
	_fill_rect(img, 6, 28, 1, 1, robe_lighter)
	_fill_rect(img, 57, 30, 1, 1, robe_lighter)
	_fill_rect(img, 8, 42, 1, 1, robe_light)
	_fill_rect(img, 55, 44, 1, 1, robe_light)
	_fill_rect(img, 17, 10, 1, 1, magic_sparkle)
	_fill_rect(img, 46, 11, 1, 1, magic_sparkle)

	return ImageTexture.create_from_image(img)

func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, mini(x + w, img.get_width())):
		for py in range(y, mini(y + h, img.get_height())):
			if px >= 0 and py >= 0:
				img.set_pixel(px, py, color)

func _process(delta: float) -> void:
	if not _is_typing:
		return

	_visible_chars += int(delta / typewriter_speed) + 1
	if _visible_chars >= _full_text.length():
		_visible_chars = _full_text.length()
		_is_typing = false
		_can_advance = true
		continue_hint.visible = true
		if auto_advance_delay > 0.0:
			_auto_advance_pending = true
			await get_tree().create_timer(auto_advance_delay).timeout
			if _auto_advance_pending and visible:
				_advance()
			_auto_advance_pending = false
	dialogue_label.visible_characters = _visible_chars

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		if _is_typing:
			# Skip to end of current text
			_visible_chars = _full_text.length()
			dialogue_label.visible_characters = _visible_chars
			_is_typing = false
			_can_advance = true
			continue_hint.visible = true
		elif _can_advance:
			_advance()
		accept_event()

func show_dialogue(speaker: String, text: String, portrait_path: String = "") -> void:
	_dialogue_queue.clear()
	_queue_line(speaker, text, portrait_path)
	_show_next()

func queue_dialogue(speaker: String, text: String, portrait_path: String = "") -> void:
	_queue_line(speaker, text, portrait_path)
	if not visible:
		_show_next()

func _queue_line(speaker: String, text: String, portrait_path: String) -> void:
	_dialogue_queue.append({
		"speaker": speaker,
		"text": text,
		"portrait": portrait_path
	})

func _show_next() -> void:
	if _dialogue_queue.is_empty():
		hide_dialogue()
		dialogue_finished.emit()
		return

	var line: Dictionary = _dialogue_queue.pop_front()
	_display_line(line)

func _display_line(line: Dictionary) -> void:
	var speaker: String = str(line.get("speaker", "Lyra"))
	var text: String = str(line.get("text", ""))
	var portrait_path: String = str(line.get("portrait", ""))

	name_label.text = speaker
	_full_text = text
	dialogue_label.text = text
	dialogue_label.visible_characters = 0
	_visible_chars = 0
	_is_typing = true
	_can_advance = false
	continue_hint.visible = false

	# Try to load portrait based on speaker name via asset loader
	var tex: Texture2D = null
	if portrait_path != "" and FileAccess.file_exists(portrait_path):
		tex = load(portrait_path) as Texture2D
	elif _asset_loader != null:
		tex = _asset_loader.get_portrait_texture(speaker)

	if tex != null:
		portrait.texture = tex
	else:
		_load_lyra_portrait()

	# Ensure portrait is visible
	portrait.visible = true
	visible = true

	if audio_manager != null:
		audio_manager.play_sfx(audio_manager.SFX.TUTORIAL_DING, -6.0)
		# Duck background music during dialogue
		audio_manager.start_ducking()

func _advance() -> void:
	_can_advance = false
	dialogue_advanced.emit()
	_show_next()

func hide_dialogue() -> void:
	visible = false
	_dialogue_queue.clear()
	_is_typing = false
	_can_advance = false
	_auto_advance_pending = false
	# Stop audio ducking when dialogue closes
	if audio_manager != null:
		audio_manager.stop_ducking()

func is_active() -> bool:
	return visible

func skip_all() -> void:
	_dialogue_queue.clear()
	hide_dialogue()
	dialogue_finished.emit()
