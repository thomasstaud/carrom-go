class_name Board
extends Node2D

@export var size: Vector2i
# placement bounds
@export var x_black: float
@export var x_white: float
@export var y_min: float
@export var y_max: float
# shooting bounds
# TODO: increase bounds by stone radius
@export var bounds: Vector4
