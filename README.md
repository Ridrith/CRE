# CRE
Conflict Engine addon for the Iron Circle guild in WoW.

Conflict Resolution Engine (CRE)
A lightweight World of Warcraft addon for tabletop-style dice rolling with attribute modifiers.

Features
Custom Dice Rolling: Roll any dice from D2 to D100
Attribute System: Seven attributes (Might, Finesse, Endurance, Resolve, Faith, Magic, Luck) with values 0-10
Color-Coded Results: Visual feedback based on roll quality
Party Chat Integration: Results automatically shared with party members
Persistent Settings: Attribute values saved between sessions
Commands
Basic Commands
/cre help - Show all available commands
/cre show - Display all current attribute values
/cre reset - Reset all attributes to 0
Attribute Management
/cre set <attribute> <value> - Set an attribute (0-10)
/cre get <attribute> - Display specific attribute value
Rolling Dice
/roll d20 might - Roll D20 + Might attribute
/roll d6 - Roll D6 without attribute modifier
/creroll d100 luck - Alternative roll command
Attributes
Might: Physical strength and power
Finesse: Dexterity and precision
Endurance: Stamina and resilience
Resolve: Mental fortitude and willpower
Faith: Spiritual connection and belief
Magic: Arcane knowledge and power
Luck: Fortune and chance
Color Coding
Red: Critical results (1s, natural max, or very poor totals)
Green: Excellent results (high rolls/totals)
Yellow: Average results
Orange: Below average results
Cyan: Attribute values
White: Total values
Installation
Extract the addon to your World of Warcraft\_retail_\Interface\AddOns\ directory
Restart World of Warcraft or reload UI (/reload)
The addon will automatically load when you log in
Usage Notes
Party Requirement: Dice rolls only work when you're in a party
Attribute Range: All attributes range from 0-10
Dice Range: Supports D2 through D100
Persistence: Your attribute settings are saved automatically
