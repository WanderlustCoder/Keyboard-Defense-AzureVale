class_name BiomeGenerator
extends RefCounted
## Noise-based biome/terrain generator using FastNoiseLite.
## Creates natural continent-style terrain with coherent biome regions.

# Terrain type constants (duplicated from SimMap to avoid circular dependency)
const TERRAIN_PLAINS := "plains"
const TERRAIN_FOREST := "forest"
const TERRAIN_MOUNTAIN := "mountain"
const TERRAIN_WATER := "water"

# =============================================================================
# NOISE CONFIGURATION
# =============================================================================

# Noise layers for continent-style generation
var _continent_noise: FastNoiseLite
var _moisture_noise: FastNoiseLite
var _temperature_noise: FastNoiseLite

# Noise scale controls (lower = larger features)
# Tuned for 64x64+ maps to produce 3-4 distinct terrain regions
const CONTINENT_SCALE := 0.04      # Landmass shapes (~25 tile features)
const MOISTURE_SCALE := 0.08       # Moisture variation (~12 tile features)
const TEMPERATURE_SCALE := 0.05    # Temperature gradients (~20 tile features)

# =============================================================================
# BIOME THRESHOLDS
# =============================================================================

# Elevation thresholds (from continent noise)
const WATER_THRESHOLD := -0.25     # Below this is water
const MOUNTAIN_THRESHOLD := 0.45   # Above this is mountain

# Moisture threshold for forest
const FOREST_MOISTURE_THRESHOLD := 0.15


# =============================================================================
# FACTORY
# =============================================================================

## Create a new biome generator with a specific seed
static func create(seed_value: int) -> BiomeGenerator:
	var gen := BiomeGenerator.new()
	gen._init_noise(seed_value)
	return gen


# =============================================================================
# INITIALIZATION
# =============================================================================

func _init_noise(seed_value: int) -> void:
	# Continent noise - determines land vs water and elevation
	_continent_noise = FastNoiseLite.new()
	_continent_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_continent_noise.seed = seed_value
	_continent_noise.frequency = CONTINENT_SCALE
	_continent_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_continent_noise.fractal_octaves = 4
	_continent_noise.fractal_lacunarity = 2.0
	_continent_noise.fractal_gain = 0.5

	# Moisture noise - determines forest density
	_moisture_noise = FastNoiseLite.new()
	_moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_moisture_noise.seed = seed_value + 1000
	_moisture_noise.frequency = MOISTURE_SCALE
	_moisture_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_moisture_noise.fractal_octaves = 3
	_moisture_noise.fractal_lacunarity = 2.0
	_moisture_noise.fractal_gain = 0.5

	# Temperature noise - affects biome selection
	_temperature_noise = FastNoiseLite.new()
	_temperature_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_temperature_noise.seed = seed_value + 2000
	_temperature_noise.frequency = TEMPERATURE_SCALE
	_temperature_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_temperature_noise.fractal_octaves = 2


# =============================================================================
# TERRAIN GENERATION
# =============================================================================

## Get the terrain type at a specific position
## This is the main function called by SimMap to generate terrain
func get_terrain_at(x: int, y: int, map_w: int, map_h: int, base_pos: Vector2i) -> String:
	# Calculate distance from center for edge falloff
	var center_x: float = float(map_w) / 2.0
	var center_y: float = float(map_h) / 2.0
	var dist_from_center: float = sqrt(pow(x - center_x, 2) + pow(y - center_y, 2))
	var max_dist: float = sqrt(pow(center_x, 2) + pow(center_y, 2))

	# Edge falloff - creates island/continent shape
	# Land probability drops off toward edges, but only at the very outer edge
	# 0.9 factor means falloff only affects outer ~10% of map radius
	var edge_factor: float = dist_from_center / (max_dist * 0.9)
	var edge_falloff: float = 1.0 - clampf(edge_factor, 0.0, 1.0)
	edge_falloff = ease(edge_falloff, 0.5)  # Gentler falloff curve for more land

	# Sample noise values
	var continent: float = _continent_noise.get_noise_2d(float(x), float(y))
	var moisture: float = _moisture_noise.get_noise_2d(float(x), float(y))
	var temperature: float = _temperature_noise.get_noise_2d(float(x), float(y))

	# Apply edge falloff to continent value
	var elevation: float = continent * edge_falloff

	# Guarantee land near castle (important for gameplay)
	var dist_to_base: float = sqrt(pow(x - base_pos.x, 2) + pow(y - base_pos.y, 2))
	if dist_to_base <= 6.0:
		# Force minimum elevation near castle
		var castle_boost: float = 1.0 - (dist_to_base / 6.0)
		elevation = maxf(elevation, 0.15 + castle_boost * 0.3)
		# Also ensure not water
		if elevation < WATER_THRESHOLD + 0.1:
			elevation = WATER_THRESHOLD + 0.15

	# Map elevation and climate to terrain types
	return _elevation_to_terrain(elevation, moisture, temperature)


## Convert elevation and climate values to terrain type
func _elevation_to_terrain(elevation: float, moisture: float, temperature: float) -> String:
	# Deep water
	if elevation < WATER_THRESHOLD:
		return TERRAIN_WATER

	# Mountains at high elevation
	if elevation > MOUNTAIN_THRESHOLD:
		return TERRAIN_MOUNTAIN

	# Mid elevations: forest vs plains based on moisture
	# Higher moisture = more likely to be forest
	# Temperature also affects it slightly (cold = more forest)
	var forest_chance: float = moisture + (temperature * -0.1)

	if forest_chance > FOREST_MOISTURE_THRESHOLD:
		return TERRAIN_FOREST

	return TERRAIN_PLAINS


# =============================================================================
# PREVIEW / DEBUG
# =============================================================================

## Get raw elevation value at position (for debugging/preview)
func get_elevation_at(x: int, y: int, map_w: int, map_h: int) -> float:
	var center_x: float = float(map_w) / 2.0
	var center_y: float = float(map_h) / 2.0
	var dist_from_center: float = sqrt(pow(x - center_x, 2) + pow(y - center_y, 2))
	var max_dist: float = sqrt(pow(center_x, 2) + pow(center_y, 2))

	var edge_factor: float = dist_from_center / (max_dist * 0.75)
	var edge_falloff: float = 1.0 - clampf(edge_factor, 0.0, 1.0)
	edge_falloff = ease(edge_falloff, 0.7)

	var continent: float = _continent_noise.get_noise_2d(float(x), float(y))
	return continent * edge_falloff


## Get raw moisture value at position (for debugging/preview)
func get_moisture_at(x: int, y: int) -> float:
	return _moisture_noise.get_noise_2d(float(x), float(y))


## Generate a simple ASCII preview of the map
func preview_ascii(map_w: int, map_h: int, base_pos: Vector2i) -> String:
	var result := ""
	for y in range(map_h):
		for x in range(map_w):
			if x == base_pos.x and y == base_pos.y:
				result += "C"  # Castle
			else:
				var terrain := get_terrain_at(x, y, map_w, map_h, base_pos)
				match terrain:
					TERRAIN_PLAINS:
						result += "."
					TERRAIN_FOREST:
						result += "f"
					TERRAIN_MOUNTAIN:
						result += "M"
					TERRAIN_WATER:
						result += "~"
					_:
						result += "?"
		result += "\n"
	return result
