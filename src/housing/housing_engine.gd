extends RefCounted
class_name PortAlderHousingEngine

const HOUSING_PACKAGE: String = "port_alder_housing_system"

var _registry: Node
var _simulation: RefCounted


func _init(content_registry: Node, simulation_engine: RefCounted) -> void:
	_registry = content_registry
	_simulation = simulation_engine


func sync_housing(state: Dictionary) -> Dictionary:
	var working: Dictionary = state.duplicate(true)
	_ensure_runtime_shape(working)
	var unlocked_apps: Array = working["player"]["phone"].get("unlocked_apps", [])
	if "housing" not in unlocked_apps:
		unlocked_apps.append("housing")
	var unlocked: Array = working["world_state"].get("unlocked_locations", [])
	for location_id: String in ["port_alder_realty"]:
		if location_id not in unlocked:
			unlocked.append(location_id)
	return _success(working)


func list_listings(state: Dictionary) -> Array:
	var entries: Array = []
	for listing_value: Variant in _registry.get_all("housing_listings"):
		if not listing_value is Dictionary:
			continue
		var listing: Dictionary = listing_value
		var listing_id: String = str(listing.get("id", ""))
		entries.append({
			"listing": listing,
			"qualification": qualification_report(state, listing_id),
			"contract": _contract_for(state, listing_id).duplicate(true),
			"acquired": not _contract_for(state, listing_id).is_empty(),
			"current_residence": str(state["player"]["housing"].get("active_listing_id", "")) == listing_id,
		})
	return entries


func qualification_report(state: Dictionary, listing_id: String) -> Dictionary:
	var listing_value: Variant = _registry.get_content("housing_listings", listing_id)
	if not listing_value is Dictionary:
		return {"known": false, "qualified": false, "failures": PackedStringArray(["Unknown housing listing."])}
	var listing: Dictionary = listing_value
	var requirements: Dictionary = listing.get("requirements", {})
	var failures: PackedStringArray = []
	var monthly_income: float = _monthly_income(state)
	var credit_score: int = int(state["player"]["economy"].get("credit_score", 0))
	var liquid_funds: float = _liquid_funds(state)
	var upfront_cost: float = _upfront_cost(listing)
	if bool(requirements.get("enrolled", false)) and not bool(state["player"]["education"].get("enrolled", false)):
		failures.append("Active Westshore enrollment is required for this student residence.")
	var minimum_credit: int = int(requirements.get("minimum_credit_score", 0))
	if credit_score < minimum_credit:
		failures.append("Credit score %d/%d." % [credit_score, minimum_credit])
	var minimum_income: float = float(requirements.get("minimum_monthly_income", 0.0))
	if monthly_income < minimum_income:
		failures.append("Documented monthly income $%.2f/$%.2f." % [monthly_income, minimum_income])
	if liquid_funds < upfront_cost:
		failures.append("Available cash $%.2f/$%.2f upfront." % [liquid_funds, upfront_cost])
	if not _contract_for(state, listing_id).is_empty():
		failures.append("This property is already in your housing portfolio.")
	return {
		"known": true,
		"qualified": failures.is_empty(),
		"failures": failures,
		"credit_score": credit_score,
		"minimum_credit_score": minimum_credit,
		"monthly_income": monthly_income,
		"minimum_monthly_income": minimum_income,
		"liquid_funds": liquid_funds,
		"upfront_cost": upfront_cost,
		"monthly_cost": _monthly_cost(listing),
	}


func acquire(state: Dictionary, listing_id: String) -> Dictionary:
	var synced: Dictionary = sync_housing(state)
	if not synced.get("ok", false):
		return synced
	var working: Dictionary = synced["state"]
	var listing_value: Variant = _registry.get_content("housing_listings", listing_id)
	if not listing_value is Dictionary:
		return _failure("Unknown housing listing: %s" % listing_id)
	var listing: Dictionary = listing_value
	var report: Dictionary = qualification_report(working, listing_id)
	if not bool(report.get("qualified", false)):
		var failures: PackedStringArray = PackedStringArray(report.get("failures", []))
		return _failure(failures[0] if not failures.is_empty() else "Housing requirements are not met.")
	var upfront_cost: float = float(report["upfront_cost"])
	var charge_result: Dictionary = _charge_across_accounts(
		working,
		upfront_cost,
		"housing.acquire:%s" % listing_id,
		"Housing acquisition — %s" % listing.get("name", listing_id)
	)
	if not charge_result.get("ok", false):
		return charge_result
	working = charge_result["state"]
	var contract_number: int = working["player"]["housing"].get("contracts", []).size() + 1
	var contract_id: String = "housing-%s-%03d" % [listing_id, contract_number]
	var tenure: String = str(listing.get("tenure", "rental"))
	var purchase_price: float = float(listing.get("purchase_price", 0.0))
	var down_payment: float = purchase_price * float(listing.get("down_payment_percent", 0.0)) / 100.0
	var contract: Dictionary = {
		"id": contract_id,
		"listing_id": listing_id,
		"property_name": listing.get("name", listing_id),
		"location_id": listing.get("location_id", ""),
		"tenure": tenure,
		"status": "active",
		"acquired_on": _date_string(working["clock"]),
		"acquired_at": _timestamp(working),
		"next_due_date": _first_of_next_month(working["clock"]),
		"monthly_charge": _monthly_cost(listing),
		"base_rent": float(listing.get("monthly_rent", 0.0)),
		"utilities": float(listing.get("monthly_utilities", 0.0)),
		"condo_fee": float(listing.get("monthly_condo_fee", 0.0)),
		"mortgage_payment": float(listing.get("monthly_mortgage", 0.0)),
		"security_deposit": float(listing.get("security_deposit", 0.0)),
		"purchase_price": purchase_price,
		"down_payment": down_payment,
		"mortgage_balance": maxf(purchase_price - down_payment, 0.0),
		"mortgage_interest_percent": float(listing.get("mortgage_interest_percent", 0.0)),
		"mortgage_term_years": int(listing.get("mortgage_term_years", 0)),
		"upfront_paid": upfront_cost,
		"outstanding_balance": 0.0,
		"payment_history": [],
	}
	var result: Dictionary = _simulation.apply_operation(working, "housing.acquire", {
		"listing_id": listing_id,
		"contract": contract,
	}, "housing.acquire:%s" % listing_id)
	if not result.get("ok", false):
		return result
	return _success(result["state"], {
		"listing": listing,
		"contract": contract,
		"upfront_cost": upfront_cost,
		"payment_splits": charge_result.get("data", {}).get("splits", []),
	})


func move_to(state: Dictionary, listing_id: String) -> Dictionary:
	var synced: Dictionary = sync_housing(state)
	if not synced.get("ok", false):
		return synced
	var working: Dictionary = synced["state"]
	var listing_value: Variant = _registry.get_content("housing_listings", listing_id)
	if not listing_value is Dictionary:
		return _failure("Unknown housing listing: %s" % listing_id)
	var listing: Dictionary = listing_value
	var contract: Dictionary = _contract_for(working, listing_id)
	if contract.is_empty():
		return _failure("Acquire this residence before moving into it.")
	if str(working["player"]["housing"].get("active_listing_id", "")) == listing_id:
		return _failure("You already live at this residence.")
	var time_result: Dictionary = _simulation.apply_operation(working, "time.advance", {
		"blocks": int(_housing_rules().get("move_duration_blocks", 1)),
	}, "housing.move:%s" % listing_id)
	if not time_result.get("ok", false):
		return time_result
	working = time_result["state"]
	var residence: String = str(listing.get("location_id", ""))
	var room_path: String = "%s.%s" % [residence, listing.get("residence_room", "")]
	var move_record: Dictionary = {
		"id": "move-%04d" % (working["player"]["housing"].get("move_history", []).size() + 1),
		"from": working["player"]["housing"].get("residence", "hale_home"),
		"to": residence,
		"listing_id": listing_id,
		"contract_id": contract.get("id", ""),
		"moved_on": _date_string(working["clock"]),
		"moved_at": _timestamp(working),
	}
	var household: Dictionary = {
		"household_id": "player_household_%s" % listing_id,
		"members": ["player"],
		"shared_inventory": {},
		"rules": {"mutual_privacy": true, "guest_notice_required": false, "overnight_notice_required": false},
		"contribution_score": 0,
	}
	var result: Dictionary = _simulation.apply_operation(working, "housing.move", {
		"listing_id": listing_id,
		"contract_id": contract.get("id", ""),
		"residence": residence,
		"room": room_path,
		"household": household,
		"tenure": listing.get("tenure", "rental"),
		"monthly_rent": listing.get("monthly_rent", 0.0),
		"monthly_housing_cost": _monthly_cost(listing),
		"monthly_utilities": listing.get("monthly_utilities", 0.0),
		"guest_permissions": "player_controls",
		"assigned_chores": [],
		"storage_access": _storage_paths(listing),
		"move_record": move_record,
	}, "housing.move:%s" % listing_id)
	if not result.get("ok", false):
		return result
	return _success(result["state"], {"listing": listing, "move_record": move_record, "destination": room_path})


func return_to_family_home(state: Dictionary) -> Dictionary:
	var synced: Dictionary = sync_housing(state)
	if not synced.get("ok", false):
		return synced
	var working: Dictionary = synced["state"]
	if str(working["player"]["housing"].get("residence", "")) == "hale_home":
		return _failure("You already live at the Hale family home.")
	var time_result: Dictionary = _simulation.apply_operation(working, "time.advance", {
		"blocks": int(_housing_rules().get("move_duration_blocks", 1)),
	}, "housing.move:hale_home")
	if not time_result.get("ok", false):
		return time_result
	working = time_result["state"]
	var household: Variant = working["player"]["housing"].get("family_household_snapshot")
	if not household is Dictionary:
		household = {
			"household_id": "hale_household",
			"members": ["player", "elena_reyes_hale", "daniel_hale", "lily_hale"],
			"shared_inventory": {},
			"rules": {"mutual_privacy": false, "guest_notice_required": true, "overnight_notice_required": true},
			"contribution_score": 0,
		}
	var family_housing: Variant = working["player"]["housing"].get("family_housing_snapshot")
	if not family_housing is Dictionary:
		family_housing = {"monthly_rent": 0.0, "monthly_housing_cost": 0.0, "monthly_utilities": 0.0, "guest_permissions": "ask_household"}
	var move_record: Dictionary = {
		"id": "move-%04d" % (working["player"]["housing"].get("move_history", []).size() + 1),
		"from": working["player"]["housing"].get("residence", ""),
		"to": "hale_home",
		"listing_id": null,
		"contract_id": null,
		"moved_on": _date_string(working["clock"]),
		"moved_at": _timestamp(working),
	}
	var result: Dictionary = _simulation.apply_operation(working, "housing.move", {
		"listing_id": "family_home",
		"contract_id": null,
		"residence": "hale_home",
		"room": "hale_home.player_bedroom",
		"household": household,
		"tenure": "family_home",
		"monthly_rent": family_housing.get("monthly_rent", 0.0),
		"monthly_housing_cost": family_housing.get("monthly_housing_cost", family_housing.get("monthly_rent", 0.0)),
		"monthly_utilities": family_housing.get("monthly_utilities", 0.0),
		"guest_permissions": family_housing.get("guest_permissions", "ask_household"),
		"rent_first_due": family_housing.get("rent_first_due", "Y1-09-01"),
		"assigned_chores": family_housing.get("assigned_chores", []),
		"storage_access": {
			"wardrobe_storage": "hale_home.player_bedroom",
			"bathroom_storage": "hale_home.family_bathroom",
			"kitchen_storage": "hale_home.kitchen",
			"garage_storage": "hale_home.garage",
		},
		"move_record": move_record,
	}, "housing.move:hale_home")
	if not result.get("ok", false):
		return result
	return _success(result["state"], {"move_record": move_record, "destination": "hale_home.player_bedroom"})


func _charge_across_accounts(state: Dictionary, amount: float, source: String, description: String) -> Dictionary:
	var remaining: float = amount
	var working: Dictionary = state
	var splits: Array = []
	for account_value: Variant in _housing_rules().get("payment_priority", ["checking", "savings", "wallet_cash"]):
		var account: String = str(account_value)
		var available: float = maxf(float(working["player"]["economy"]["accounts"].get(account, 0.0)), 0.0)
		var split: float = minf(available, remaining)
		if split <= 0.0:
			continue
		var safe_source: String = source.replace(":", "_").replace(".", "_")
		var result: Dictionary = _simulation.apply_operation(working, "economy.transaction", {
			"id": "housing-upfront-%s-%s-%03d" % [safe_source, account, splits.size() + 1],
			"account": account,
			"amount": -split,
			"type": "housing_acquisition",
			"category": "housing",
			"description": description,
		}, source)
		if not result.get("ok", false):
			return result
		working = result["state"]
		splits.append({"account": account, "amount": split})
		remaining -= split
		if remaining <= 0.005:
			break
	if remaining > 0.005:
		return _failure("Available cash cannot cover the housing upfront cost.")
	return _success(working, {"splits": splits, "amount": amount})


func _ensure_runtime_shape(state: Dictionary) -> void:
	var housing: Dictionary = state["player"]["housing"]
	for array_key: String in ["contracts", "leases", "owned_properties", "move_history", "payment_history"]:
		if not housing.get(array_key) is Array:
			housing[array_key] = []
	if not housing.has("tenure"):
		housing["tenure"] = "family_home" if str(housing.get("residence", "hale_home")) == "hale_home" else "rental"
	if not housing.has("active_listing_id"):
		housing["active_listing_id"] = null
	if not housing.has("monthly_housing_cost"):
		housing["monthly_housing_cost"] = float(housing.get("monthly_rent", 0.0))
	if not housing.has("monthly_utilities"):
		housing["monthly_utilities"] = 0.0
	if not housing.has("family_household_snapshot"):
		housing["family_household_snapshot"] = null
	if not housing.has("family_housing_snapshot"):
		housing["family_housing_snapshot"] = null


func _contract_for(state: Dictionary, listing_id: String) -> Dictionary:
	for contract_value: Variant in state.get("player", {}).get("housing", {}).get("contracts", []):
		if contract_value is Dictionary and str(contract_value.get("listing_id", "")) == listing_id and str(contract_value.get("status", "active")) == "active":
			return contract_value
	return {}


func _monthly_income(state: Dictionary) -> float:
	var total: float = 0.0
	for job_value: Variant in state["player"]["employment"].get("active_jobs", []):
		if not job_value is Dictionary or str(job_value.get("status", "active")) != "active":
			continue
		total += float(job_value.get("hourly_pay", 0.0)) * float(job_value.get("weekly_hours", 0.0)) * 52.0 / 12.0
	return snappedf(total, 0.01)


func _liquid_funds(state: Dictionary) -> float:
	var accounts: Dictionary = state["player"]["economy"].get("accounts", {})
	return float(accounts.get("wallet_cash", 0.0)) + float(accounts.get("checking", 0.0)) + float(accounts.get("savings", 0.0))


func _upfront_cost(listing: Dictionary) -> float:
	if str(listing.get("tenure", "rental")) == "purchase":
		var price: float = float(listing.get("purchase_price", 0.0))
		return snappedf(price * (float(listing.get("down_payment_percent", 0.0)) + float(listing.get("closing_cost_percent", 0.0))) / 100.0, 0.01)
	return snappedf(float(listing.get("monthly_rent", 0.0)) + float(listing.get("security_deposit", 0.0)) + float(listing.get("application_fee", 0.0)), 0.01)


func _monthly_cost(listing: Dictionary) -> float:
	if str(listing.get("tenure", "rental")) == "purchase":
		return snappedf(float(listing.get("monthly_mortgage", 0.0)) + float(listing.get("monthly_condo_fee", 0.0)) + float(listing.get("monthly_utilities", 0.0)), 0.01)
	return snappedf(float(listing.get("monthly_rent", 0.0)) + float(listing.get("monthly_utilities", 0.0)), 0.01)


func _storage_paths(listing: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var location_id: String = str(listing.get("location_id", ""))
	for container_id: Variant in listing.get("storage_access", {}):
		result[str(container_id)] = "%s.%s" % [location_id, listing["storage_access"][container_id]]
	return result


func _housing_rules() -> Dictionary:
	var package: Variant = _registry.get_package(HOUSING_PACKAGE)
	return package.get("market_rules", {}) if package is Dictionary else {}


func _first_of_next_month(clock: Dictionary) -> String:
	var year: int = int(clock.get("year", 1))
	var month: int = int(clock.get("month", 1)) + 1
	if month > 12:
		month = 1
		year += 1
	return "Y%d-%02d-01" % [year, month]


func _date_string(clock: Dictionary) -> String:
	return "Y%d-%02d-%02d" % [int(clock.get("year", 1)), int(clock.get("month", 1)), int(clock.get("day", 1))]


func _timestamp(state: Dictionary) -> String:
	return "%s:%s+%03d" % [_date_string(state["clock"]), str(state["clock"].get("block", "morning")), int(state["clock"].get("minute_within_block", 0))]


func _success(state: Dictionary, data: Dictionary = {}) -> Dictionary:
	return {"ok": true, "state": state, "data": data, "errors": PackedStringArray()}


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
