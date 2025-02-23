extends Object

class_name FeldLayer

## == Feld Layer for Godot Ink ==
## Takes an Ink story, a character database. Uses a set of functions to relay
## between a UI and Ink while adding extra features that make use of state
## that may not be present within Ink's systems.
## Uses a FeldString class to send strings with metadata to a UI, allowing
## the UI to format the text and display as needed.

var story: InkStory
var characters: CharacterDatabase
var character_dict: Dictionary

enum STATES {TEXT, CHOICE, END}

var state = STATES.TEXT

signal choice_made(choice: FeldString)
signal story_ended

var end_emitted = false

var current_choices: Array = []

var settings: Dictionary = {
	"formatting": true, ## Whether to format lines to include passive check text and character names
	"include_passive_check_text": true,
	"include_character_name": true,
	"unavailable_red_checks_not_visible": true, ## If true, mark visible as false for a disabled red check
	"allow_disabled_choices": false, ## If true, allow choose_choice to use disabled choices
}

func _init(inkstory=InkStory.new(),chardb=CharacterDatabase.new()):
	characters=chardb
	reset_story(inkstory)

## Resets the story to "s"

func reset_story(s) -> void:
	story = s
	story.ResetState()
	story.BindExternalFunction("get_var",GlobalAccess.get_var)
	story.BindExternalFunction("set_var",GlobalAccess.set_var)
	story.BindExternalFunction("do_check",GlobalAccess.do_check)
	for i in characters.characters:
		character_dict[i.name]=i

## Call before calling continue_story, use the state returned to inform UI
## what the player may do next. Returns an enum state.

func update_state():
	if story.GetCanContinue():
		state=STATES.TEXT
	elif story.GetCurrentChoices():
		state=STATES.CHOICE
	else:
		state=STATES.END
		if not end_emitted: story_ended.emit()
		end_emitted = true
	return state

## Call to receive the next line of text in a FeldString..

func continue_story():
	if story.GetCanContinue():
		# Get next line
		var text = story.Continue()
		var tags = story.GetCurrentTags()
		# Check tags and insert them into metadata
		var meta = {"visible":true}
		var x=0
		while x < len(tags):
			match tags[x]:
				"PassiveCheck":
					x+=1
					var args = tags[x].rsplit(" ")
					meta["passive_check_passed"]=true
					var fail = true if args[0] == "Fail" else false
					var variable = args[1]
					var goal = int(args[2]) 
					if fail and GlobalAccess.get_var(variable) >= goal :
						meta.visible=false
						meta["passive_check_passed"]=false
					if not fail and (GlobalAccess.get_var(variable) < goal):
						meta.visible=false
						meta["passive_check_passed"]=false
					meta["passive_check"]=true
					meta["passive_check_variable"]=variable
					meta["passive_check_goal"]=goal
					meta["passive_check_fail"]=fail
				"Character":
					x+=1
					var character_name=tags[x]
					if character_dict.has(character_name):
						meta["character"]=character_dict[character_name]
						meta["character_color"]=character_dict[character_name].color
						meta["character_name"]=character_dict[character_name].name
						if character_dict[character_name].portrait:
							meta["character_portrait"]=character_dict[character_name].portrait
					else:
						push_warning("Character name '%s' not found in Character Dictionary" % character_name)
				"Signal":
					x+=1
					var s = tags[x]
					var code = emit_signal(s)
					if code == ERR_UNAVAILABLE:
						push_warning("Ink script called for signal %s and signal is unavailable." % s)
			x+=1
		# Format if necessary, return string
		if not settings["formatting"]: return FeldString.new(text,meta)
		return FeldString.new(format_text(text, meta),meta)
	else:
		push_warning("continue_story called but unable to continue.")

## Formats and returns an array of FeldString choices.
func get_choices():
	var choices = story.GetCurrentChoices()
	if not choices:
		push_warning("get_choices called but no choices are available.")
		return
	var f_choices = []
	for choice: InkChoice in choices:
		var f_choice = FeldString.new(choice.GetText(), {"visible":true, "enabled":true, "_choice_index":choice.GetIndex()})
		var x=0
		var tags=choice.GetTags()
		while x < len(tags):
			match tags[x]:
				"Check":
					x+=1
					var check_name = tags[x]
					var check_info = GlobalAccess.get_check_info(tags[x])
					var new_dict = {
						"check": check_name,
						"check_type": check_info["TYPE"],
						"check_stat": check_info["STAT"],
						"check_goal": check_info["GOAL"],
						"check_bonuses": check_info["BONUSES"],
						"check_passed": check_info["PASSED"],
						"check_can_attempt": true
					}
					if not GlobalAccess.can_do_check(check_name):
						new_dict["check_can_attempt"] = false
						f_choice.meta["enabled"] = false
						if settings["unavailable_red_checks_not_visible"] and check_info["TYPE"]==GlobalAccess.RED:
							f_choice.meta["visible"] = false
					f_choice.meta.merge(new_dict)
			x+=1
		f_choices.append(f_choice)
	# Move invisible choices to the end of the array - makes the available choices a continuous range
	for i in f_choices.size():
		if not f_choices[i].meta["visible"]:
			f_choices.append(f_choices.pop_at(i))
	current_choices=f_choices
	return f_choices

## Chooses a choice. Emits a "choice_made" signal.
## Also clears current choices array.
func choose_choice(option: int) -> void:
	if not current_choices:
		push_warning("choose_choice called with no available choices.")
		return
	var choice = current_choices[option]
	story.ChooseChoiceIndex(choice.meta["_choice_index"])
	current_choices=[]
	choice_made.emit(choice)

## Formats text based on settings - not very customizeable but would like to change that
func format_text(text, meta):
	var passive_tag = ""
	var name_tag = ""
	var prepended = false
	# Passive checks
	if settings["include_passive_check_text"] and meta.get("passive_check_passed"):
		prepended = true
		var passtext = "Failed" if meta["passive_check_fail"] else "Passed"
		passive_tag = "[color=gray][%s (%s) - %s][/color] " % [meta["passive_check_variable"], meta["passive_check_goal"], passtext]
	# Character checks
	if settings["include_character_name"] and meta.has("character"):
		prepended = true
		name_tag = "[color=%s]%s[/color]" % [meta.get("character_color").to_html(),meta.get("character_name")]
		if not settings["include_passive_check_text"]: name_tag = name_tag+": "
	var seperator = ": " if prepended else ""
	if passive_tag and name_tag:
		name_tag = name_tag + " "
	var formatted = "%s%s%s%s" % [name_tag,passive_tag,seperator,text]
	return formatted
	
