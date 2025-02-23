extends Node

# Global Access singleton holding a key:value database of any relevant story
# variables and white/red checks for Ink access.

## Whether set_var makes new dictionaries or throws error
@export var allow_set_var_to_create_new_dictionaries: bool = false
## Whether checks marked as passed will always succeed
@export var always_pass_passed_checks: bool = false
## The function used to generate random numbers
@export var roll_func: Callable = randi_range.bind(1,6)
## The amount of dice to roll
@export var die_count: int = 2

enum {WHITE, RED}

signal check_done(check)

var last_roll: Array

var Player_Stats_Flags: Dictionary = {
	"MIND": 4,
	"BODY": 4,
	"HEART": 4,
	"CHECKS": {
		"EASY_WHITE_CHECK": {
			"TYPE": WHITE,
			"STAT": "MIND",
			"GOAL": 8,
			"BONUSES": {
				"HAS_ITEM": 2 # Change this in ink script to add or remove the bonus
			},
			"LAST_ATTEMPT": 0, # bonuses + stat, if higher allow try
			"PASSED": false # if check has already been passed
		},
		"HARD_WHITE_CHECK": {
			"TYPE": WHITE,
			"STAT": "HEART",
			"GOAL": 14,
			"BONUSES": {
			},
			"LAST_ATTEMPT": 0,
			"PASSED": false
		},
		"IMPOSSIBLE_WHITE_CHECK": {
			"TYPE": WHITE,
			"STAT": "BODY",
			"GOAL": 10,
			"BONUSES": {
				"CROWBAR?": -20
			},
			"LAST_ATTEMPT": -INF,
			"PASSED": false
		},
		"EASY_RED_CHECK": {
			"TYPE": RED,
			"STAT": "MIND",
			"GOAL": 6,
			"BONUSES": {
				"HAS_ITEM": 0
			},
			"LAST_ATTEMPT": 0,
			"PASSED": false
		},
		"MEDIUM_RED_CHECK": {
			"TYPE": RED,
			"STAT": "HEART",
			"GOAL": 12,
			"BONUSES": {
				"HAS_ITEM": 0
			},
			"LAST_ATTEMPT": 0,
			"PASSED": false
		},
	}
}

## Methods for accessing and setting variables using text strings within the
## global access database. Used for ink scripts to allow changing and retrieving
## of variables from the scripting language.

func get_var(var_name: String):
	var_name = var_name.to_upper()
	var arr=Array(var_name.rsplit("."))
	var result = _get_var_recursive(Player_Stats_Flags,arr)
	if typeof(result)==typeof({}) and result == {}:
		push_warning("get_var call for %s failed. Returning false." % var_name)
		return false
	return result

func _get_var_recursive(dict,arr):
	if not arr:
		return(dict)
	return(_get_var_recursive(dict.get(arr.pop_front(),{}),arr))

func set_var(var_name, value):
	var_name = var_name.to_upper()
	var arr=Array(var_name.rsplit("."))
	_set_var_recursive(Player_Stats_Flags,arr,value)

func _set_var_recursive(dict,arr,value):
	if len(arr)==1:
		dict[arr[0]]=value
		return(0)
	if not dict.get(arr[0],false):
		if allow_set_var_to_create_new_dictionaries:
			dict[arr[0]]={}
			push_warning("Key '%s' did not exist in Global Access dictionary. Creating new entries. You can disable this behaviour in Global Access." % arr[0])
		else:
			assert(false,"Key '%s' does not exist in Global Access dictionary." % arr[0])
	return(_set_var_recursive(dict.get(arr.pop_front()),arr,value))

## Helper functions for white and red checks

## Returns information about check with name 'check', or
## Returns empty dict if check doesn't exist and pushes error
func get_check_info(check: String) -> Dictionary:
	var result = get_var("CHECKS.%s" % check)
	assert(result,"Check named %s not found/doesn't exist." % check)
	return result

func tally_check_bonuses(check: String) -> int:
	var check_info = get_check_info(check)
	if not check_info:
		push_error("Check named %s not found/doesn't exist." % check)
		return false
	var bonus_total = 0
	for i in check_info["BONUSES"]:
		bonus_total+=check_info["BONUSES"][i]
	return bonus_total

## Returns true if check can be attempted. Checks if current stat+bonus total
## is higher than last attempt, or if Red, if it has ever been attempted at all
## If check doesn't exist, returns false and pushes error
func can_do_check(check: String) -> bool:
	var check_info = get_check_info(check)
	if not check_info:
		push_error("Check named %s not found/doesn't exist." % check)
		return false
	if check_info["TYPE"]==RED:
		if check_info["LAST_ATTEMPT"]==0:
			return true
		else:
			return false
	# If check isn't Red, assume White
	if check_info["TYPE"]!=WHITE: push_warning("Check %s type isn't white or red, assuming white." % check)
	if check_info["LAST_ATTEMPT"] >= get_var(check_info["STAT"])+tally_check_bonuses(check): # if current stat is not higher than stored stat
		return false
	return true

## Returns result of check. Stores last dice roll.
## If check doesn't exist, returns false and pushes error
func do_check(check: String) -> bool:
	var check_info = get_check_info(check)
	if not check_info:
		push_error("Check named %s not found/doesn't exist." % check)
		return false
	if always_pass_passed_checks and check_info["PASSED"]:
		check_done.emit(check)
		return true
	var dice=[]
	for i in die_count:
		dice.append(roll_func.call())
	last_roll=dice
	var dice_sum=0
	for i in dice:
		dice_sum+=i
	var total=dice_sum+get_var(check_info["STAT"])+tally_check_bonuses(check)
	if total >= check_info["GOAL"]:
		set_var("CHECKS.%s.PASSED" % check,true)
		check_done.emit(check)
		return true
	if check_info["TYPE"]==RED:
		set_var("CHECKS.%s.LAST_ATTEMPT" % check, 1)
		check_done.emit(check)
		return false
	set_var("CHECKS.%s.LAST_ATTEMPT" % check, get_var(check_info["STAT"])+tally_check_bonuses(check))
	check_done.emit(check)
	return false

func _ready() -> void:
	randomize()
	#print(get_check_info("TEST_WHITE_CHECK"))
	#print(can_do_check("TEST_WHITE_CHECK"))
	#print(do_check("TEST_WHITE_CHECK"))
	#print(last_roll)
	#print(get_check_info("TEST_WHITE_CHECK"))
	#print(get_check_info("TEST_RED_CHECK"))
	#print(can_do_check("TEST_RED_CHECK"))
	#print(do_check("TEST_RED_CHECK"))
	#print(last_roll)
	#print(get_check_info("TEST_RED_CHECK"))
	#print(can_do_check("TEST_RED_CHECK"))
	#print(self.Player_Stats_Flags.WHITE_CHECKS.TEST_WHITE_CHECK.STAT)
	#set_var("WHITE_CHECKS.TEST_WHITE_CHECK.STAT","MIND")
	#print(get_var("WHITE_CHECKS.TEST_WHITE_CHECK.STAT"))
