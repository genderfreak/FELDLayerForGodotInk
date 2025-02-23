# FELD Layer for Godot Ink

FELD Layer is a middleman between Godot Ink and your game's UI meant to ease the creation of games
inspired by Disco Elysium.

Currently, this includes functionality replicating character names and the various checks seen in the game.


![screenshot of minimal UI running in godot](./screenshot.png)

You can email me @ genderfr3ak@gmail.com if you have any questions.

## Installation

This project requires [Godot Ink](https://github.com/paulloz/godot-ink) and Godot Mono. See their
respective installation and usage guides.

## Usage

This project functions as a middleman between Godot Ink and your user interface. An example of the
bare minimum UI is minimum_ui.tscn. FELDLayer provides a set of functions mirroring Godot Ink's
functions for story progression and decision making, whilst adding metadata to the strings returned by
Godot Ink.

### Characters

Characters are marked up in Ink files with Ink tags. Character information is in a database, made up of
Character objects. In the Characters folder is a CharacterDatabase resource and 3 example characters.

To add a character to the database, create a Character resource, and add it to the CharacterDatabase
resource.

To mark a line as being said by a character, you add 2 tags in the format ``# Character # Name``, where
name is the Character object's ``name`` property.


### Variables

All variables that your Ink needs to access must be stored in the GlobalAccess singleton's dictionary
``Player_Stats_Flags``. The script file comes filled with the stats used by the example file. This
dictionary can be modified by your Godot game scripts, or by your Ink files by bound functions. Binding these
functions is done by Ink's ``EXTERNAL`` keyword, like so - ``EXTERNAL get_var(var_name)``.

Functions you should bind in your Ink script for full functionality are:

	EXTERNAL do_check(tag)
	EXTERNAL get_var(var_name)
	EXTERNAL set_var(var_name,value)

get_var will get a var from the GlobalAccess dictionary, and will resolve nested dictionaries
by using periods between references. For example, calling ``get_var("CHECKS.EASY_WHITE_CHECK.GOAL")``
in your Ink script would return 8. set_var functions in the same way.

### Passive Checks

Passive checks are similar. To mark a line as a passive check, add 2 tags as ``# PassiveCheck # Pass/Fail Stat Goal``,
for example ``# PassiveCheck # Pass Mind 2`` would mark the line as visible if the variable "Mind" was greater than
or equal to 2. A reverse check can be marked as "Fail" to only show if the variable is lower than the goal. For
example, ``# PassiveCheck # Fail Body 7`` will show the line only if the variable "Body" is lower than 7.

### Active Checks

Checks are composed of 2 parts, the tagged choice, and the path divert. This is an
example of a white check:

	+ Do easy white check. # Check # EASY_WHITE_CHECK
		{ do_check("EASY_WHITE_CHECK"): -> CheckPass }
		-> CheckFail

First, we have the choice marked by a ``+``, and then tagged as a check. To tag a choice as a check,
tag it like so: ``# Check # CHECK_NAME``. CHECK_NAME here is the key that identifies the dictionary
in GlobalAccess's "CHECKS" dictionary.

Then, in your Ink script, divert the story based on the boolean result of do_check. do_check takes the
identifying key of the check, then performs a white/red check based on the TYPE in the check's properties.
do_check returns true if the check was passed, and saves certain properties to memory, such as
if the check was passed, if it was failed and what stats the player had when they failed, and
also saves the result of the dice roll to last_roll in GlobalAccess.

See global_access.gd for examples on how to create different types of checks.

### Other stuff

minimum_ui.tscn expects certain InputMap actions in order to add shortcuts and advance dialogue.
You can bind these by using the override.cfg in the root directory of this project.
