extends RefCounted
class_name PortAlderEconomyEngine

const GameClockScript: GDScript = preload("res://src/simulation/game_clock.gd")

var _registry: Node
var _simulation: RefCounted


func _init(content_registry: Node, simulation_engine: RefCounted) -> void:
	_registry = content_registry
	_simulation = simulation_engine


func sync_economy(state: Dictionary) -> Dictionary:
	var working: Dictionary = state.duplicate(true)
	_ensure_runtime_shape(working)
	_ensure_tuition_state(working)
	var notices: PackedStringArray = []
	var aid_notice: String = _process_financial_aid(working)
	if not aid_notice.is_empty():
		notices.append(aid_notice)
	var current_serial: int = _clock_date_serial(working["clock"])
	var last_serial: int = _date_serial_from_string(str(working["player"]["economy"].get("last_sync_date", _date_string(working["clock"]))))
	if last_serial < 0 or last_serial > current_serial:
		last_serial = current_serial
	for serial: int in range(last_serial, current_serial + 1):
		var date: Dictionary = _parts_from_date_serial(serial)
		var date_string: String = _date_string_from_parts(date)
		if str(date["weekday"]) == "monday":
			var allowance_result: Dictionary = _process_allowance(working, date_string)
			if not allowance_result.get("ok", false):
				return allowance_result
			working = allowance_result["state"]
			if not str(allowance_result.get("data", {}).get("notice", "")).is_empty():
				notices.append(str(allowance_result["data"]["notice"]))
			_create_weekly_summary(working, serial - 7, serial - 1)
		var rent_result: Dictionary = _process_rent(working, date_string)
		if not rent_result.get("ok", false):
			return rent_result
		working = rent_result["state"]
		if not str(rent_result.get("data", {}).get("notice", "")).is_empty():
			notices.append(str(rent_result["data"]["notice"]))
		var housing_result: Dictionary = _process_housing_contracts(working, date_string)
		if not housing_result.get("ok", false):
			return housing_result
		working = housing_result["state"]
		for housing_notice: Variant in housing_result.get("data", {}).get("notices", []):
			notices.append(str(housing_notice))
		var card_result: Dictionary = _process_credit_card_minimum(working, date_string)
		if not card_result.get("ok", false):
			return card_result
		working = card_result["state"]
		if not str(card_result.get("data", {}).get("notice", "")).is_empty():
			notices.append(str(card_result["data"]["notice"]))
		var interest_result: Dictionary = _process_student_loan_interest(working, date_string)
		if not interest_result.get("ok", false):
			return interest_result
		working = interest_result["state"]
	working["player"]["economy"]["last_sync_date"] = _date_string(working["clock"])
	return _success(working, {"notices": notices})


func current_budget_summary(state: Dictionary) -> Dictionary:
	var current_serial: int = _clock_date_serial(state["clock"])
	var weekday_index: int = GameClockScript.WEEKDAYS.find(str(state["clock"].get("weekday", "monday")))
	return _budget_summary_for_range(state, current_serial - maxi(0, weekday_index), current_serial, false)


func list_stores(state: Dictionary) -> Array:
	var stores: Array = []
	for value: Variant in _registry.get_all("stores"):
		if not value is Dictionary:
			continue
		var store: Dictionary = value
		stores.append({
			"store": store,
			"open": _store_open(state, store),
			"discount_percent": _store_discount_percent(state, store),
			"item_count": store.get("stock", []).size(),
		})
	return stores


func store_listing(state: Dictionary, store_id: String) -> Dictionary:
	var value: Variant = _registry.get_content("stores", store_id)
	if not value is Dictionary:
		return {}
	var store: Dictionary = value
	var items: Array = []
	for item_id_value: Variant in store.get("stock", []):
		var item: Variant = _registry.get_content("items", str(item_id_value))
		if not item is Dictionary:
			continue
		items.append({"item": item, "price": _price_quote(state, store, item, 1)})
	return {
		"store": store,
		"open": _store_open(state, store),
		"discount_percent": _store_discount_percent(state, store),
		"items": items,
	}


func purchase(state: Dictionary, store_id: String, item_id: String, quantity: int = 1) -> Dictionary:
	if quantity < 1 or quantity > 10:
		return _failure("Purchase quantity must be between 1 and 10.")
	var store_value: Variant = _registry.get_content("stores", store_id)
	var item_value: Variant = _registry.get_content("items", item_id)
	if not store_value is Dictionary or not item_value is Dictionary:
		return _failure("Unknown store or item.")
	var store: Dictionary = store_value
	var item: Dictionary = item_value
	if item_id not in store.get("stock", []):
		return _failure("%s does not stock this item." % store.get("name", store_id))
	if not _store_open(state, store):
		return _failure("%s is currently closed." % store.get("name", store_id))
	var quote: Dictionary = _price_quote(state, store, item, quantity)
	var destination: String = _purchase_container(item)
	var item_state: Dictionary = {"cleanliness": 100, "condition": 100} if str(item.get("category", "")) == "clothing" else {}
	var result: Dictionary = _simulation.apply_operation(state, "inventory.add", {
		"container_id": destination, "item_id": item_id, "quantity": quantity, "item_state": item_state,
	}, "shopping.purchase:%s" % store_id)
	if not result.get("ok", false):
		return result
	var working: Dictionary = result["state"]
	var receipt_id: String = "receipt-%s-%05d" % [store_id, working["player"]["economy"].get("receipts", []).size() + 1]
	result = _spend_from_accounts(
		working,
		float(quote["total"]),
		_economy_rules().get("purchase_rules", {}).get("payment_priority", ["wallet_cash", "checking", "credit_card"]),
		"shopping.purchase:%s" % store_id,
		"purchase",
		"purchase",
		"%s — %s ×%d" % [store.get("name", store_id), item.get("name", item_id), quantity],
		receipt_id
	)
	if not result.get("ok", false):
		return result
	working = result["state"]
	var receipt: Dictionary = {
		"id": receipt_id,
		"date": _date_string(working["clock"]),
		"timestamp": _timestamp(working),
		"store_id": store_id,
		"store_name": store.get("name", store_id),
		"items": [{"item_id": item_id, "name": item.get("name", item_id), "quantity": quantity, "unit_price": quote["unit_price"]}],
		"subtotal": quote["subtotal"],
		"discount_percent": quote["discount_percent"],
		"discount": quote["discount"],
		"tax": quote["tax"],
		"total": quote["total"],
		"payment_splits": result.get("data", {}).get("splits", []).duplicate(true),
		"return_eligible": true,
	}
	working["player"]["economy"]["receipts"].append(receipt)
	return _success(working, {"receipt": receipt, "item": item, "container_id": destination})


func pay_tuition(state: Dictionary, requested_amount: float) -> Dictionary:
	var synced: Dictionary = sync_economy(state)
	if not synced.get("ok", false):
		return synced
	var working: Dictionary = synced["state"]
	var balance: float = float(working["player"]["education"].get("tuition_balance", 0.0))
	if balance <= 0.0:
		return _failure("There is no outstanding tuition balance.")
	var amount: float = minf(balance, requested_amount if requested_amount > 0.0 else balance)
	var payment_id: String = "tuition-payment-%05d" % (working["player"]["economy"]["ledger"].size() + 1)
	var result: Dictionary = _spend_from_accounts(working, amount, ["wallet_cash", "checking", "savings"], "money.tuition", "tuition", "tuition", "Westshore tuition payment", payment_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	working["player"]["education"]["tuition_balance"] = _round_money(balance - amount)
	if float(working["player"]["education"]["tuition_balance"]) <= 0.0:
		working["player"]["education"]["tuition_plan"] = "paid"
	return _success(working, {"amount": amount, "balance": working["player"]["education"]["tuition_balance"]})


func pay_outstanding_rent(state: Dictionary) -> Dictionary:
	var synced: Dictionary = sync_economy(state)
	if not synced.get("ok", false):
		return synced
	var working: Dictionary = synced["state"]
	var balance: float = float(working["player"]["housing"].get("rent_balance", 0.0))
	if balance <= 0.0:
		return _failure("There is no outstanding rent balance.")
	var payment_id: String = "housing-balance-payment-%05d" % (working["player"]["economy"]["ledger"].size() + 1)
	var result: Dictionary = _spend_from_accounts(working, balance, ["wallet_cash", "checking", "savings", "credit_card"], "money.rent", "rent", "housing", "Outstanding housing payment", payment_id)
	if not result.get("ok", false):
		return result
	working = result["state"]
	working["player"]["housing"]["rent_balance"] = 0.0
	for contract_value: Variant in working["player"]["housing"].get("contracts", []):
		if contract_value is Dictionary:
			contract_value["outstanding_balance"] = 0.0
	working["player"]["housing"]["payment_history"].append({
		"id": payment_id, "date": _date_string(working["clock"]), "amount": balance, "status": "arrears_paid",
	})
	return _success(working, {"amount": balance})


func pay_credit_card(state: Dictionary, requested_amount: float) -> Dictionary:
	var synced: Dictionary = sync_economy(state)
	if not synced.get("ok", false):
		return synced
	var working: Dictionary = synced["state"]
	var card_balance: float = float(working["player"]["economy"]["accounts"].get("credit_card", 0.0))
	var debt: float = maxf(0.0, -card_balance)
	if debt <= 0.0:
		return _failure("The credit card has no balance due.")
	var amount: float = minf(debt, requested_amount if requested_amount > 0.0 else debt)
	if float(working["player"]["economy"]["accounts"].get("checking", 0.0)) < amount:
		return _failure("Checking does not have enough money for that card payment.")
	var payment_id: String = "card-payment-%05d" % (working["player"]["economy"]["ledger"].size() + 1)
	var result: Dictionary = _simulation.apply_operation(working, "economy.transaction", {
		"id": "%s-checking" % payment_id, "timestamp": _timestamp(working), "account": "checking", "amount": -amount,
		"type": "debt_payment", "category": "debt", "description": "Credit card payment",
	}, "money.credit_card")
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _simulation.apply_operation(working, "economy.transaction", {
		"id": "%s-card" % payment_id, "timestamp": _timestamp(working), "account": "credit_card", "amount": amount,
		"type": "debt_payment", "category": "debt", "description": "Credit card payment received",
	}, "money.credit_card")
	if not result.get("ok", false):
		return result
	working = result["state"]
	working["player"]["economy"]["credit_score"] = mini(850, int(working["player"]["economy"].get("credit_score", 650)) + 2)
	return _success(working, {"amount": amount, "remaining": debt - amount})


func _process_allowance(state: Dictionary, due_date: String) -> Dictionary:
	if _recurring_record_exists(state, "school_allowance", due_date) or not bool(state["player"]["education"].get("enrolled", false)):
		return _success(state)
	var enrollment_date: String = str(state["player"]["education"].get("enrollment_date", ""))
	if not enrollment_date.is_empty() and _date_serial_from_string(due_date) < _date_serial_from_string(enrollment_date):
		return _success(state)
	var amount: float = float(state["player"]["flags"].get("weekly_school_allowance", 0.0))
	if amount <= 0.0:
		return _success(state)
	var result: Dictionary = _simulation.apply_operation(state, "economy.transaction", {
		"id": "allowance-%s" % due_date.replace("-", ""), "timestamp": _timestamp(state), "account": "checking", "amount": amount,
		"type": "gift", "category": "allowance", "description": "Weekly family school allowance", "due_date": due_date, "date": due_date,
	}, "economy.recurring:school_allowance")
	if not result.get("ok", false):
		return result
	var working: Dictionary = result["state"]
	result = _record_recurring(working, "school_allowance", due_date, amount, "paid")
	if not result.get("ok", false):
		return result
	return _success(result["state"], {"notice": "Family allowance: $%.2f deposited to checking." % amount})


func _process_rent(state: Dictionary, due_date: String) -> Dictionary:
	if str(state["player"]["housing"].get("tenure", "family_home")) != "family_home":
		return _success(state)
	var first_due: String = str(state["player"]["housing"].get("rent_first_due", "Y1-09-01"))
	if _date_serial_from_string(due_date) < _date_serial_from_string(first_due) or int(_date_parts(due_date)["day"]) != int(_date_parts(first_due)["day"]):
		return _success(state)
	if _recurring_record_exists(state, "parental_rent", due_date) or bool(state["player"]["education"].get("enrolled", false)):
		return _success(state)
	var amount: float = float(state["player"]["housing"].get("monthly_rent", 0.0))
	if amount <= 0.0:
		return _success(state)
	var payment: Dictionary = _spend_from_accounts(state, amount, ["wallet_cash", "checking"], "economy.recurring:parental_rent", "rent", "rent", "Hale household rent", "rent-%s" % due_date.replace("-", ""), due_date)
	if payment.get("ok", false):
		var paid_state: Dictionary = payment["state"]
		var paid_record: Dictionary = _record_recurring(paid_state, "parental_rent", due_date, amount, "paid")
		return _success(paid_record["state"], {"notice": "Monthly household rent of $%.2f was paid." % amount}) if paid_record.get("ok", false) else paid_record
	var working: Dictionary = state.duplicate(true)
	working["player"]["housing"]["rent_balance"] = float(working["player"]["housing"].get("rent_balance", 0.0)) + amount
	var result: Dictionary = _simulation.apply_operation(working, "relationship.adjust_meter", {
		"character_id": "elena_reyes_hale", "meter": "resentment", "amount": 3, "reason": "missed_household_rent",
	}, "economy.recurring:parental_rent")
	if not result.get("ok", false):
		return result
	working = result["state"]
	result = _simulation.apply_operation(working, "relationship.adjust_meter", {
		"character_id": "elena_reyes_hale", "meter": "trust", "amount": -2, "reason": "missed_household_rent",
	}, "economy.recurring:parental_rent")
	if not result.get("ok", false):
		return result
	result = _record_recurring(result["state"], "parental_rent", due_date, amount, "missed")
	if not result.get("ok", false):
		return result
	return _success(result["state"], {"notice": "Rent was missed. $%.2f is outstanding and Elena's trust fell." % amount})


func _process_housing_contracts(state: Dictionary, due_date: String) -> Dictionary:
	var working: Dictionary = state
	var notices: PackedStringArray = []
	for contract_index: int in working["player"]["housing"].get("contracts", []).size():
		var contract_value: Variant = working["player"]["housing"]["contracts"][contract_index]
		if not contract_value is Dictionary:
			continue
		var contract: Dictionary = contract_value
		if not contract.get("payment_history") is Array:
			contract["payment_history"] = []
		if str(contract.get("status", "active")) != "active" or str(contract.get("next_due_date", "")) != due_date:
			continue
		var contract_id: String = str(contract.get("id", "housing-contract"))
		var rule_id: String = "housing_contract:%s" % contract_id
		if _recurring_record_exists(working, rule_id, due_date):
			continue
		var amount: float = _round_money(float(contract.get("monthly_charge", 0.0)))
		if amount <= 0.0:
			contract["next_due_date"] = _next_month_date(due_date)
			continue
		var payment: Dictionary = _spend_from_accounts(
			working, amount, ["checking", "savings", "wallet_cash"],
			"economy.recurring:%s" % rule_id, "housing_payment", "housing",
			"Monthly housing — %s" % contract.get("property_name", "Residence"),
			"housing-%s-%s" % [contract_id, due_date.replace("-", "")], due_date
		)
		var history_entry: Dictionary = {
			"id": "payment-%s-%s" % [contract_id, due_date.replace("-", "")],
			"contract_id": contract_id, "listing_id": contract.get("listing_id", ""),
			"due_date": due_date, "processed_at": _timestamp(working), "amount": amount,
		}
		if payment.get("ok", false):
			working = payment["state"]
			contract = working["player"]["housing"]["contracts"][contract_index]
			history_entry["status"] = "paid"
			contract["outstanding_balance"] = maxf(float(contract.get("outstanding_balance", 0.0)), 0.0)
			if str(contract.get("tenure", "rental")) == "purchase":
				var balance: float = float(contract.get("mortgage_balance", 0.0))
				var interest: float = _round_money(balance * float(contract.get("mortgage_interest_percent", 0.0)) / 1200.0)
				var principal: float = minf(balance, maxf(0.0, float(contract.get("mortgage_payment", 0.0)) - interest))
				contract["mortgage_balance"] = _round_money(balance - principal)
				history_entry["mortgage_interest"] = interest
				history_entry["mortgage_principal"] = principal
				_sync_owned_property_balance(working, contract_id, float(contract["mortgage_balance"]))
			notices.append("%s housing payment of $%.2f was paid." % [contract.get("property_name", "Monthly"), amount])
		else:
			working = working.duplicate(true)
			contract = working["player"]["housing"]["contracts"][contract_index]
			history_entry["status"] = "missed"
			contract["outstanding_balance"] = _round_money(float(contract.get("outstanding_balance", 0.0)) + amount)
			working["player"]["housing"]["rent_balance"] = _round_money(float(working["player"]["housing"].get("rent_balance", 0.0)) + amount)
			working["player"]["economy"]["credit_score"] = maxi(300, int(working["player"]["economy"].get("credit_score", 650)) - int(_housing_rules().get("missed_payment_credit_penalty", 8)))
			notices.append("%s housing payment was missed; $%.2f is outstanding." % [contract.get("property_name", "Monthly"), amount])
		contract["next_due_date"] = _next_month_date(due_date)
		contract["payment_history"].append(history_entry.duplicate(true))
		working["player"]["housing"]["payment_history"].append(history_entry)
		var recurring: Dictionary = _record_recurring(working, rule_id, due_date, amount, str(history_entry["status"]))
		if not recurring.get("ok", false):
			return recurring
		working = recurring["state"]
	return _success(working, {"notices": notices})


func _sync_owned_property_balance(state: Dictionary, contract_id: String, balance: float) -> void:
	for property_value: Variant in state["player"]["housing"].get("owned_properties", []):
		if property_value is Dictionary and str(property_value.get("contract_id", "")) == contract_id:
			property_value["mortgage_balance"] = balance
			return


func _process_credit_card_minimum(state: Dictionary, due_date: String) -> Dictionary:
	if int(_date_parts(due_date)["day"]) != 15 or _recurring_record_exists(state, "credit_card_payment", due_date):
		return _success(state)
	var debt: float = maxf(0.0, -float(state["player"]["economy"]["accounts"].get("credit_card", 0.0)))
	if debt <= 0.0:
		return _success(state)
	var account: Dictionary = _find_by_id(_economy_rules().get("accounts", []), "credit_card")
	var amount: float = minf(debt, maxf(debt * float(account.get("minimum_payment_percent", 3.0)) / 100.0, 25.0))
	if float(state["player"]["economy"]["accounts"].get("checking", 0.0)) < amount:
		var missed: Dictionary = state.duplicate(true)
		missed["player"]["economy"]["credit_score"] = maxi(300, int(missed["player"]["economy"].get("credit_score", 650)) - 25)
		var missed_result: Dictionary = _record_recurring(missed, "credit_card_payment", due_date, amount, "missed")
		return _success(missed_result["state"], {"notice": "Credit-card minimum was missed; credit score fell."}) if missed_result.get("ok", false) else missed_result
	var result: Dictionary = _simulation.apply_operation(state, "economy.transaction", {
		"id": "card-minimum-checking-%s" % due_date.replace("-", ""), "timestamp": _timestamp(state), "account": "checking", "amount": -amount,
		"type": "debt_payment", "category": "debt", "description": "Credit card minimum payment", "date": due_date,
	}, "economy.recurring:credit_card_payment")
	if not result.get("ok", false):
		return result
	var working: Dictionary = result["state"]
	result = _simulation.apply_operation(working, "economy.transaction", {
		"id": "card-minimum-card-%s" % due_date.replace("-", ""), "timestamp": _timestamp(working), "account": "credit_card", "amount": amount,
		"type": "debt_payment", "category": "debt", "description": "Credit card minimum received", "date": due_date,
	}, "economy.recurring:credit_card_payment")
	if not result.get("ok", false):
		return result
	working = result["state"]
	working["player"]["economy"]["credit_score"] = mini(850, int(working["player"]["economy"].get("credit_score", 650)) + 3)
	result = _record_recurring(working, "credit_card_payment", due_date, amount, "paid")
	return _success(result["state"], {"notice": "Credit-card minimum of $%.2f was paid." % amount}) if result.get("ok", false) else result


func _process_student_loan_interest(state: Dictionary, due_date: String) -> Dictionary:
	if int(_date_parts(due_date)["day"]) != 1 or _recurring_record_exists(state, "student_loan_interest", due_date):
		return _success(state)
	var working: Dictionary = state.duplicate(true)
	var total_interest: float = 0.0
	for debt_value: Variant in working["player"]["economy"].get("debts", []):
		if not debt_value is Dictionary or str(debt_value.get("type", "")) != "student_loan":
			continue
		var debt: Dictionary = debt_value
		var interest: float = _round_money(float(debt.get("balance", 0.0)) * 0.045 / 12.0)
		debt["balance"] = _round_money(float(debt.get("balance", 0.0)) + interest)
		total_interest += interest
	if total_interest <= 0.0:
		return _success(state)
	working["player"]["education"]["student_debt"] = _round_money(float(working["player"]["education"].get("student_debt", 0.0)) + total_interest)
	var result: Dictionary = _record_recurring(working, "student_loan_interest", due_date, total_interest, "accrued")
	return result


func _record_recurring(state: Dictionary, rule_id: String, due_date: String, amount: float, status: String) -> Dictionary:
	return _simulation.apply_operation(state, "economy.process_recurring", {"record": {
		"id": "%s-%s" % [rule_id, due_date.replace("-", "")], "rule_id": rule_id, "due_date": due_date,
		"processed_at": _timestamp(state), "amount": _round_money(amount), "status": status,
	}}, "economy.recurring:%s" % rule_id)


func _spend_from_accounts(state: Dictionary, amount: float, priorities: Array, source: String, transaction_type: String, category: String, description: String, transaction_id: String, transaction_date: String = "") -> Dictionary:
	var remaining: float = _round_money(amount)
	var available: float = 0.0
	for account_id_value: Variant in priorities:
		available += _account_spending_capacity(state, str(account_id_value))
	if available + 0.001 < remaining:
		return _failure("Available payment methods cannot cover $%.2f." % amount)
	var working: Dictionary = state
	var splits: Array = []
	for account_id_value: Variant in priorities:
		if remaining <= 0.001:
			break
		var account_id: String = str(account_id_value)
		var debit: float = minf(_account_spending_capacity(working, account_id), remaining)
		if debit <= 0.0:
			continue
		debit = _round_money(debit)
		var result: Dictionary = _simulation.apply_operation(working, "economy.transaction", {
			"id": "%s-%s" % [transaction_id, account_id], "timestamp": _timestamp(working), "account": account_id, "amount": -debit,
			"type": transaction_type, "category": category, "description": description, "receipt_id": transaction_id,
			"date": transaction_date if not transaction_date.is_empty() else _date_string(working["clock"]),
		}, source)
		if not result.get("ok", false):
			return result
		working = result["state"]
		splits.append({"account": account_id, "amount": debit})
		remaining = _round_money(remaining - debit)
	return _success(working, {"splits": splits})


func _account_spending_capacity(state: Dictionary, account_id: String) -> float:
	var balance: float = float(state["player"]["economy"]["accounts"].get(account_id, 0.0))
	var definition: Dictionary = _find_by_id(_economy_rules().get("accounts", []), account_id)
	if str(definition.get("type", "")) == "credit":
		return maxf(0.0, float(definition.get("credit_limit", 0.0)) + balance)
	return maxf(0.0, balance)


func _price_quote(state: Dictionary, store: Dictionary, item: Dictionary, quantity: int) -> Dictionary:
	var unit_price: float = _round_money(float(item.get("base_price", 0.0)) * float(store.get("price_multiplier", 1.0)))
	var subtotal: float = _round_money(unit_price * quantity)
	var discount_percent: float = _store_discount_percent(state, store)
	var discount: float = _round_money(subtotal * discount_percent / 100.0)
	var taxable: float = subtotal - discount
	var tax_rate: float = 0.0 if _tax_exempt(item) else float(_economy_rules().get("purchase_rules", {}).get("sales_tax_rate", 0.0))
	var tax: float = _round_money(taxable * tax_rate)
	return {"unit_price": unit_price, "subtotal": subtotal, "discount_percent": discount_percent, "discount": discount, "tax": tax, "total": _round_money(taxable + tax)}


func _store_discount_percent(state: Dictionary, store: Dictionary) -> float:
	var total: float = 0.0
	for discount: Variant in _registry.get_package("port_alder_initial_stores").get("discounts", []):
		if not discount is Dictionary:
			continue
		if str(discount.get("id", "")) == "westshore_student" and bool(state["player"]["education"].get("enrolled", false)) and str(store.get("id", "")) in discount.get("eligible_stores", []):
			total += float(discount.get("percent", 0.0))
		elif str(discount.get("id", "")) == "employee_discount" and _player_works_at_store(state, store):
			total += float(discount.get("percent", 0.0))
	return minf(total, 50.0)


func _player_works_at_store(state: Dictionary, store: Dictionary) -> bool:
	var store_location: String = str(store.get("location", "")).get_slice(".", 0)
	for job: Variant in state["player"]["employment"].get("active_jobs", []):
		if job is Dictionary and str(job.get("status", "active")) == "active" and str(job.get("location", "")).get_slice(".", 0) == store_location:
			return true
	return false


func _store_open(state: Dictionary, store: Dictionary) -> bool:
	return str(state["clock"].get("weekday", "")) in store.get("open_days", []) and str(state["clock"].get("block", "")) in store.get("open_blocks", [])


func _tax_exempt(item: Dictionary) -> bool:
	var category: String = str(item.get("category", ""))
	var item_id: String = str(item.get("id", ""))
	if category == "food":
		return true
	if category == "drink" and item_id not in ["drink_beer_can", "drink_wine_bottle", "drink_spirits_bottle", "drink_soda"]:
		return true
	return bool(item.get("prescription", false))


func _purchase_container(item: Dictionary) -> String:
	match str(item.get("category", "")):
		"clothing":
			return "wardrobe_storage"
		"food", "drink":
			return "kitchen_storage"
		"hygiene", "medicine":
			return "bathroom_storage"
		"household":
			return "garage_storage"
		_:
			return "carried_inventory"


func _ensure_runtime_shape(state: Dictionary) -> void:
	var economy: Dictionary = state["player"]["economy"]
	for array_key: String in ["recurring_transactions", "ledger", "receipts", "weekly_summaries"]:
		if not economy.has(array_key):
			economy[array_key] = []
	if not economy.has("last_sync_date"):
		economy["last_sync_date"] = _date_string(state["clock"])
	if not state["player"]["housing"].has("rent_balance"):
		state["player"]["housing"]["rent_balance"] = 0.0
	for array_key: String in ["contracts", "leases", "owned_properties", "move_history", "payment_history"]:
		if not state["player"]["housing"].get(array_key) is Array:
			state["player"]["housing"][array_key] = []
	if bool(state["player"]["education"].get("enrolled", false)) and str(state["player"]["education"].get("enrollment_date", "")).is_empty():
		state["player"]["education"]["enrollment_date"] = _date_string(state["clock"])


func _ensure_tuition_state(state: Dictionary) -> void:
	var education: Dictionary = state["player"]["education"]
	var tuition: Dictionary = _registry.get_package("westshore_education_system").get("institution", {}).get("tuition", {})
	var load_id: String = str(education.get("load", education.get("course_load", "")))
	var charge: float = float(tuition.get("part_time_per_semester", 2200.0)) if load_id == "part_time" else float(tuition.get("full_time_per_semester", 4000.0))
	if not education.has("tuition_charge") or float(education.get("tuition_charge", 0.0)) <= 0.0:
		education["tuition_charge"] = charge if not str(education.get("tuition_plan", "")).is_empty() else 0.0
	if not education.has("tuition_balance"):
		education["tuition_balance"] = 0.0
	var plan: String = str(education.get("tuition_plan", ""))
	if plan in ["paid", "student_loan", "aid_paid"]:
		education["tuition_balance"] = 0.0
	elif plan == "aid_pending" and float(education.get("tuition_balance", 0.0)) <= 0.0:
		education["tuition_balance"] = charge


func _process_financial_aid(state: Dictionary) -> String:
	var education: Dictionary = state["player"]["education"]
	if str(education.get("tuition_plan", "")) != "aid_pending" or not bool(state["player"]["flags"].get("education.financial_aid_resolved", false)) or education.has("financial_aid_award"):
		return ""
	var awards: Dictionary = _registry.get_package("westshore_education_system").get("institution", {}).get("tuition", {}).get("aid_awards_by_background", {})
	var background: String = str(state["player"]["economy"].get("financial_background", "standard_background"))
	var award: float = minf(float(education.get("tuition_balance", 0.0)), float(awards.get(background, 0.0)))
	education["financial_aid_award"] = award
	education["tuition_balance"] = _round_money(float(education.get("tuition_balance", 0.0)) - award)
	education["tuition_plan"] = "aid_paid" if float(education["tuition_balance"]) <= 0.0 else "aid_awarded"
	return "Financial aid awarded $%.2f; $%.2f tuition remains." % [award, education["tuition_balance"]]


func _create_weekly_summary(state: Dictionary, start_serial: int, end_serial: int) -> void:
	if end_serial < 0:
		return
	var summary: Dictionary = _budget_summary_for_range(state, start_serial, end_serial, true)
	for existing: Variant in state["player"]["economy"].get("weekly_summaries", []):
		if existing is Dictionary and str(existing.get("id", "")) == str(summary.get("id", "")):
			return
	state["player"]["economy"]["weekly_summaries"].append(summary)


func _budget_summary_for_range(state: Dictionary, start_serial: int, end_serial: int, closed: bool) -> Dictionary:
	var totals: Dictionary = {"gross_income": 0.0, "net_income": 0.0, "allowance": 0.0, "purchases": 0.0, "transportation": 0.0, "healthcare": 0.0, "tuition": 0.0, "rent": 0.0, "debt": 0.0}
	var net_changes: float = 0.0
	for entry: Variant in state["player"]["economy"].get("ledger", []):
		if not entry is Dictionary:
			continue
		var serial: int = _date_serial_from_string(str(entry.get("date", "")))
		if serial < start_serial or serial > end_serial:
			continue
		var amount: float = float(entry.get("amount", 0.0))
		net_changes += amount
		var category: String = str(entry.get("category", ""))
		if amount > 0.0:
			if category == "employment":
				totals["net_income"] += amount
			elif category == "allowance":
				totals["allowance"] += amount
		elif category == "purchase":
			totals["purchases"] += -amount
		elif category == "transportation":
			totals["transportation"] += -amount
		elif category == "healthcare":
			totals["healthcare"] += -amount
		elif category == "tuition":
			totals["tuition"] += -amount
		elif category == "rent":
			totals["rent"] += -amount
		elif category == "debt":
			totals["debt"] += -amount
	for pay: Variant in state["player"]["employment"].get("payroll_history", []):
		if pay is Dictionary:
			var serial: int = _date_serial_from_string(str(pay.get("pay_date", "")))
			if serial >= start_serial and serial <= end_serial:
				totals["gross_income"] += float(pay.get("gross", 0.0)) + float(pay.get("tips", 0.0))
	# Reconstruct the balance at the period boundary when a closed week is
	# generated during catch-up processing. The live account total can already
	# include transactions dated after this summary's end date.
	var ending_balance: float = _net_account_balance(state)
	for entry: Variant in state["player"]["economy"].get("ledger", []):
		if entry is Dictionary and _date_serial_from_string(str(entry.get("date", ""))) > end_serial:
			ending_balance -= float(entry.get("amount", 0.0))
	var summary: Dictionary = {
		"id": "budget-%s-%s" % [_date_string_from_parts(_parts_from_date_serial(start_serial)).replace("-", ""), _date_string_from_parts(_parts_from_date_serial(end_serial)).replace("-", "")],
		"start_date": _date_string_from_parts(_parts_from_date_serial(start_serial)),
		"end_date": _date_string_from_parts(_parts_from_date_serial(end_serial)),
		"closed": closed,
		"starting_balance": _round_money(ending_balance - net_changes),
		"ending_balance": _round_money(ending_balance),
	}
	for key: Variant in totals:
		summary[key] = _round_money(float(totals[key]))
	summary["total_spending"] = _round_money(float(totals["purchases"]) + float(totals["transportation"]) + float(totals["healthcare"]) + float(totals["tuition"]) + float(totals["rent"]) + float(totals["debt"]))
	return summary


func _net_account_balance(state: Dictionary) -> float:
	var total: float = 0.0
	for value: Variant in state["player"]["economy"].get("accounts", {}).values():
		total += float(value)
	return total


func _recurring_record_exists(state: Dictionary, rule_id: String, due_date: String) -> bool:
	for record: Variant in state["player"]["economy"].get("recurring_transactions", []):
		if record is Dictionary and str(record.get("rule_id", "")) == rule_id and str(record.get("due_date", "")) == due_date:
			return true
	return false


func _economy_rules() -> Dictionary:
	return _registry.get_package("port_alder_economy_system")


func _housing_rules() -> Dictionary:
	var package: Variant = _registry.get_package("port_alder_housing_system")
	return package.get("market_rules", {}) if package is Dictionary else {}


func _find_by_id(entries: Array, content_id: String) -> Dictionary:
	for entry: Variant in entries:
		if entry is Dictionary and str(entry.get("id", "")) == content_id:
			return entry
	return {}


func _timestamp(state: Dictionary) -> String:
	return "Y%d-%02d-%02d:%s+%03d" % [state["clock"]["year"], state["clock"]["month"], state["clock"]["day"], state["clock"]["block"], state["clock"]["minute_within_block"]]


func _date_string(clock: Dictionary) -> String:
	return "Y%d-%02d-%02d" % [clock["year"], clock["month"], clock["day"]]


func _date_string_from_parts(date: Dictionary) -> String:
	return "Y%d-%02d-%02d" % [date["year"], date["month"], date["day"]]


func _clock_date_serial(clock: Dictionary) -> int:
	return _date_serial_days(int(clock["year"]), int(clock["month"]), int(clock["day"]))


func _date_serial_from_string(date: String) -> int:
	var parts: PackedStringArray = date.trim_prefix("Y").split("-")
	if parts.size() != 3:
		return -1
	return _date_serial_days(int(parts[0]), int(parts[1]), int(parts[2]))


func _date_parts(date: String) -> Dictionary:
	return _parts_from_date_serial(_date_serial_from_string(date))


func _next_month_date(date: String) -> String:
	var parts: Dictionary = _date_parts(date)
	var month: int = int(parts["month"]) + 1
	var year: int = int(parts["year"])
	if month > 12:
		month = 1
		year += 1
	return "Y%d-%02d-01" % [year, month]


func _date_serial_days(year: int, month: int, day: int) -> int:
	var days: int = 0
	for previous_year: int in range(1, year):
		days += 366 if previous_year % 4 == 0 else 365
	for previous_month: int in range(1, month):
		days += _days_in_month(previous_month, year)
	return days + day - 1


func _parts_from_date_serial(serial: int) -> Dictionary:
	var safe_serial: int = maxi(0, serial)
	var remaining: int = safe_serial
	var year: int = 1
	while remaining >= (366 if year % 4 == 0 else 365):
		remaining -= 366 if year % 4 == 0 else 365
		year += 1
	var month: int = 1
	while remaining >= _days_in_month(month, year):
		remaining -= _days_in_month(month, year)
		month += 1
	return {"year": year, "month": month, "day": remaining + 1, "weekday": _weekday_for_serial(safe_serial)}


func _weekday_for_serial(serial: int) -> String:
	var opening_serial: int = _date_serial_days(1, 8, 20)
	var opening_index: int = GameClockScript.WEEKDAYS.find("tuesday")
	return GameClockScript.WEEKDAYS[posmod(opening_index + serial - opening_serial, GameClockScript.WEEKDAYS.size())]


func _days_in_month(month: int, year: int) -> int:
	if month in [4, 6, 9, 11]:
		return 30
	if month == 2:
		return 29 if year % 4 == 0 else 28
	return 31


func _round_money(value: float) -> float:
	return round(value * 100.0) / 100.0


func _success(state: Dictionary, data: Dictionary = {}) -> Dictionary:
	return {"ok": true, "state": state, "data": data, "errors": PackedStringArray()}


func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
