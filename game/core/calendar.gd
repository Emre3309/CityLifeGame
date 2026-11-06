extends RefCounted

const START_DATE := {"year": 1962, "month": 9, "day": 1}

static func add_days(date: Dictionary, count: int) -> Dictionary:
	var result: Dictionary = date.duplicate()
	var direction := 1 if count > 0 else -1
	for step in range(absi(count)):
		result.day += direction
		if result.day > days_in_month(result.year, result.month):
			result.day = 1
			result.month += 1
			if result.month > 12:
				result.month = 1
				result.year += 1
		elif result.day < 1:
			result.month -= 1
			if result.month < 1:
				result.month = 12
				result.year -= 1
			result.day = days_in_month(result.year, result.month)
	return result

static func days_in_month(year: int, month: int) -> int:
	if month == 2:
		return 29 if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0) else 28
	return 30 if month in [4, 6, 9, 11] else 31

static func age_on(birth: Dictionary, date: Dictionary) -> Dictionary:
	var months: int = (date.year - birth.year) * 12 + date.month - birth.month
	if date.day < birth.day:
		months -= 1
	months = maxi(months, 0)
	return {"years": months / 12, "months": months % 12}

static func date_on(day_index: int) -> Dictionary:
	return add_days(START_DATE, day_index)

static func format_date(date: Dictionary) -> String:
	return "%02d.%02d.%04d" % [date.day, date.month, date.year]
