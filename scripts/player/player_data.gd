extends Resource
class_name PlayerData


@export var title: String = ""
@export var strength: int = 0
@export var constitution: int = 0
@export var insight: int = 0
@export var agility: int = 0
@export var speech: int = 0
@export var free_points: int = 20


# clear all attributes
func reset():
	title = ""
	strength = 0
	constitution = 0
	insight = 0
	agility = 0
	speech = 0
	free_points = 20


func apply_preset(preset_data: PlayerData):
	strength += preset_data.strength
	constitution += preset_data.constitution
	insight += preset_data.insight
	agility += preset_data.agility
	speech += preset_data.speech
	free_points += preset_data.free_points


func total_spent() -> int:
	return strength + constitution + insight + agility + speech
	
