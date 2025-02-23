extends Control

var feld_layer: FeldLayer

@onready var textbox = $VBoxContainer/RichTextLabel
@onready var vbox = $VBoxContainer

@export var story: InkStory
@export var character_db: CharacterDatabase = preload("res://addons/feld_layer_for_godot_ink/Characters/character_db.tres")

var end_reached = false
var choices_printed = false

func _ready() -> void:
	feld_layer = FeldLayer.new(story, character_db)
	GlobalAccess.check_done.connect(_check_done)
	do_continue() # Always start the story when ready.

func _unhandled_input(event) -> void:
	# Advance story when space key is pressed.
	if event.is_action_pressed("dialogue_advance"):
		do_continue()

# Continues the story based on current state.
func do_continue() -> void:
	var state=feld_layer.update_state()
	match state:
		feld_layer.STATES.TEXT:
			var next_line = feld_layer.continue_story()
			if next_line.meta.visible:
				textbox.text = textbox.text + str(next_line)
			else:
				print("Text not shown: %s. Recursing." % str(next_line))
				do_continue()
		feld_layer.STATES.CHOICE:
			if choices_printed: return
			var count=1
			for c: FeldString in feld_layer.get_choices():
				if not c.meta["visible"]: continue
				var button=Button.new()
				var text = str(c)
				if c.meta.get("check_type", -1)>=0:
					var check_info = GlobalAccess.get_check_info(c.meta["check"])
					match check_info["TYPE"]:
						GlobalAccess.WHITE:
							text = "[%s - %s] %s" % [check_info["STAT"],check_info["GOAL"],str(c)]
						GlobalAccess.RED:
							text = "[%s - %s (ONE SHOT)] %s" % [check_info["STAT"],check_info["GOAL"],str(c)]
				button.text="%s. %s\n" % [count,text]
				button.pressed.connect(do_choose.bind(count))
				button.shortcut = make_choice_shortcut(count)
				if not c.meta["enabled"]:
					button.disabled=true
				vbox.add_child(button)
				count +=1
			choices_printed = true
		feld_layer.STATES.END:
			if not end_reached:
				textbox.text = textbox.text + "END"
				end_reached = true
				var button=Button.new()
				button.text="Close"
				button.pressed.connect(close)
				vbox.add_child(button)

# Tell FeldLayer what choice to make.
func do_choose(option):
	option-=1
	feld_layer.choose_choice(option)
	for i in vbox.get_children():
		if i is Button:
			i.queue_free()
	choices_printed = false
	do_continue()

#func _choice_made(choice):
	#pass

func _check_done(check):
	var bonus_total=GlobalAccess.tally_check_bonuses(check)
	check = GlobalAccess.get_check_info(check)
	var pass_text = "passed" if check["PASSED"] else "failed"
	var dice_text = ""
	if GlobalAccess.last_roll.size()==1:
		dice_text = str(GlobalAccess.last_roll[0])
	else:
		print(GlobalAccess.last_roll.size())
		for i in GlobalAccess.last_roll.size():
			if i == GlobalAccess.last_roll.size()-1:
				dice_text+=" and a "
			dice_text+=str(GlobalAccess.last_roll[i])
			if i < GlobalAccess.last_roll.size()-2:
				dice_text+=", "
	
	var dice_sum=0
	for i in GlobalAccess.last_roll:
		dice_sum+=i
	var total = dice_sum+bonus_total+GlobalAccess.get_var(check["STAT"])
	var text = "[color=gray][i](Check %s. Goal was %s, you rolled a %s, plus your %s stat %s and a bonus total of %s, totalling %s)[/i][/color]\n"%[pass_text, check["GOAL"],dice_text,check["STAT"].capitalize(),GlobalAccess.get_var(check["STAT"]),bonus_total,total]
	textbox.text=textbox.text+text
	

# Close UI.
func close():
	textbox.clear()
	self.visible=false

# Creates a shortcut object with numbered dialog option keys.
func make_choice_shortcut(option):
	var shortcut = Shortcut.new()
	var event = InputEventAction.new()
	event.action = "dialogue_option_%s" % option
	shortcut.events.append(event)
	return shortcut
