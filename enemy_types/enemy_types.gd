extends Resource

class_name EnemyType

@export var sprites: SpriteFrames

@export var max_health: int = 10
@export var move_range: int = 2

@export var attacks: Array[TurnAction] = [preload('res://actions/basic_attack.tres')]
