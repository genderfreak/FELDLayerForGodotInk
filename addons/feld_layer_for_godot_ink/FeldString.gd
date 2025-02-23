extends Object

class_name FeldString

## A string with attached metadata describing how to display it.
## Has a 'string': the formatted, ready to use string.
## Has 'meta': dictionary containing relevant information for displaying and
##   handling the line. Snake case.
##   Possible meta tags:
##     visible: bool                  - whether or not to display.
##   Text line only
##     passive_check: bool            - if true, text is barred behind a passive skill check.
##     passive_check_variable: String - variable name passive was checked against
##     passive_check_goal: int        - goal passive was checked against
##     passive_check_true: bool       - if true, text only shows when variable is lower than goal
##     passive_check_passed: bool     - if true, check was passed and WILL BE shown
##     character: Character           - the character Object associated, if any.
##     character_name: String         - the character's name string
##     character_color: Color         - the character's color
##     character_color: Texture2D     - the character's portrait (if any) will be unassigned if not
##   Choice line only
##     enabled: bool                  - whether choice is pickable (hide with visible: false)
##     _choice_index: String          - choice index in the ink story (for internal use)
##     check: String                  - check name, tag in database
##     check_type: int (enum)         - type of check, enum (0: white check 1: red check)
##     check_stat: String             - stat that check tests
##     check_goal: int                - check goal to beat
##     check_can_attempt: bool        - true if check can be attempted
##     check_bonuses: Dictionary      - key: value list of bonuses
##     check_passed: bool             - true if check has been attempted and passed

## To get the text, name.string or str(name)

var string: String = ""
var meta: Dictionary = {}

func _init(p_string,p_meta):
	self.string = p_string
	self.meta = p_meta

func _to_string() -> String:
	return string
