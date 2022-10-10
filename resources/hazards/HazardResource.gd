extends Resource
class_name HazardResource

export (int) var speed_idle = 30
export (int) var speed_angered = 75
export (int) var outrun_distance = 300

export (float) var sight_angle = 45.0
export (float) var sight_rotate_speed = 270.0
export (float) var sight_length = 150.0

export (float) var idle_time = 5.0
export (float) var idle_rand = 0.3
export (float) var wander_min_radius = 30.0
export (float) var wander_max_radius = 60.0
export (float) var max_wander_outside_biome = 50.0

export (Array, Enums.Season) var exists_in_seasons
