extends Node


# @onready var TILE_ARRAY: World = %World

var player_position = Vector3.ZERO

var during_cutscene: bool = true

var rng = RandomNumberGenerator.new()

const SCENE_UIDS = {
	"minion" : "uid://dn1q8rllncccr",
	"meteor" : "uid://x7qtbsv67m5x",
	"mask" : "uid://dh886bvnkfnsm",
	"game" : "uid://cfeq0enektf7b"
}
