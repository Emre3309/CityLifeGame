extends RefCounted

const ROLES := {"citizen":"Vatandaş", "governor":"Vali", "police_chief":"Emniyet müdürü", "gang_leader":"Ağ lideri", "gang_member":"Ağ üyesi"}
const EDUCATION := {"primary_school":"İlkokul", "high_school_graduate":"Lise mezunu", "high_school_dropout":"Lise yarıda", "university_enrolled":"Üniversiteye kayıtlı", "university_graduate":"Üniversite mezunu", "police_training":"Polis eğitimi"}

static func role(id: String) -> String:
	return ROLES.get(id, "Bilinmeyen görev")

static func education(id: String) -> String:
	return EDUCATION.get(id, "Bilinmeyen eğitim")
