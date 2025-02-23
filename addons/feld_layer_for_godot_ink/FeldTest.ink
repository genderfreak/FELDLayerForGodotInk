EXTERNAL do_check(tag)
EXTERNAL get_var(var_name)
EXTERNAL set_var(var_name,value)
-> Start
=== Start ===
Passive, white, and red checks test.
Passive mind check, 2. Shows a line of dialogue if mind is above or at 2.
Passed. # PassiveCheck # Pass Mind 2 # Character # Mind
Passive body check, 7. Shows a line of dialogue, whether body is above/at or below 7.
Passed. # PassiveCheck # Pass Body 7 # Character # Body
Failed. # PassiveCheck # Fail Body 7 # Character # Body
Passive heart check, 6. Shows a line of dialogue only when heart is below 6.
Failed. # PassiveCheck # Fail Heart 6 # Character # Heart
This choice contains a white and a red check.
+ Do easy white check. # Check # EASY_WHITE_CHECK
    { do_check("EASY_WHITE_CHECK"): -> CheckPass }
    -> CheckFail
+ Do hard white check. # Check # HARD_WHITE_CHECK
    { do_check("HARD_WHITE_CHECK"): -> CheckPass }
    -> CheckFail
+ Do impossible white check. # Check # IMPOSSIBLE_WHITE_CHECK
    { do_check("IMPOSSIBLE_WHITE_CHECK"): -> CheckPass }
    -> CheckFail
+ Do easy red check. # Check # EASY_RED_CHECK
    { do_check("EASY_RED_CHECK"): -> CheckPass }
    -> CheckFail
+ Do medium red check. # Check # MEDIUM_RED_CHECK
    { do_check("MEDIUM_RED_CHECK"): -> CheckPass }
    -> CheckFail
+ Do no check.
    ->Start

= CheckPass
Check passed.
->Start

= CheckFail
Check failed.
->Start
