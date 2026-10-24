class_name PlatformerConfig3D
extends RefCounted

# Kacheln & Weltgeometrie in 3D-Metern (1 Block = 1.0 Unit)
const TILE_SIZE: float = 1.0
const LEVEL_HEIGHT_ROWS: int = 14
const PLAYER_WIDTH: float = 0.8
const PLAYER_HEIGHT: float = 0.9
const PLAYER_DEPTH: float = 0.8

# Kinematik & Physik (+Y zeigt in 3D nach oben!)
const GRAVITY: float = 28.0
const MAX_RUN_SPEED: float = 8.5
const ACCELERATION: float = 44.0
const FRICTION: float = 14.0
const AIR_CONTROL: float = 0.75
# Sprungimpuls: h_max = 16.2^2 / (2 * 28) = 4.68 Blöcke (überwindet 3- und 4-Block-Röhren)
const JUMP_FORCE: float = 16.2
const VARIABLE_JUMP_CUT: float = 0.5

# Game Feel Puffer
const COYOTE_TIME_SEC: float = 0.12
const JUMP_BUFFER_SEC: float = 0.12

# Level-Grenzen & Startpunkt
const START_X: float = 2.5
const START_Y: float = 1.5
const DEATH_Y: float = -3.0

# Kamera
const CAMERA_Z: float = 16.0
const CAMERA_HEIGHT_OFFSET: float = 2.5
const CAMERA_LEAD_X: float = 4.0
const CAMERA_LERP_SPEED: float = 5.0
