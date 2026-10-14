class_name ColonyRest
extends RefCounted
## Rest points per game hour; keep the existing /300 saved remainder unit.
const RESTED: int = 900
const TIRED: int = 300
const PREFERRED_TIRED: int = 600
const BED: int = 75
const BEDROLL: int = 60
const GROUND: int = 45

static func awake_rate(tick: int) -> int:
	# 37.5/hour exactly across two ticks: a bed's 600-point recovery takes
	# eight hours, and spending those 600 points awake takes sixteen hours.
	return 37+posmod(tick,2)

static func recovery_rate(kind: String) -> int:
	return BED if kind=="bed" else BEDROLL if kind=="bedroll" else GROUND

static func wants_sleep(person: Dictionary, tick: int, preparing: bool = false) -> bool:
	var hour: int=((tick%7200)/300+(12 if person.shift=="Night shift" else 0))%24
	return person.rest<=(500 if preparing else TIRED) or ((hour>=22 or hour<6) and person.rest<=PREFERRED_TIRED)
