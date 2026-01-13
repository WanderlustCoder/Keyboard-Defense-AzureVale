class_name SimDiplomacy
extends RefCounted
## Diplomatic actions and their effects.
## Handles trade agreements, pacts, tributes, alliances, and war.

const SimFactions = preload("res://sim/factions.gd")

# =============================================================================
# DIPLOMATIC ACTION CHECKS
# =============================================================================

## Check if we can propose a trade agreement
static func can_propose_trade(state, faction_id: String) -> Dictionary:
	var result := {"ok": false, "reason": ""}

	if SimFactions.has_trade_agreement(state, faction_id):
		result.reason = "Already have trade agreement"
		return result

	if SimFactions.is_at_war(state, faction_id):
		result.reason = "Cannot trade during war"
		return result

	var relation := SimFactions.get_relation(state, faction_id)
	if relation < SimFactions.RELATION_UNFRIENDLY:
		result.reason = "Relations too poor"
		return result

	result.ok = true
	return result


## Check if we can propose a non-aggression pact
static func can_propose_pact(state, faction_id: String) -> Dictionary:
	var result := {"ok": false, "reason": ""}

	if SimFactions.has_non_aggression_pact(state, faction_id):
		result.reason = "Already have pact"
		return result

	if SimFactions.is_at_war(state, faction_id):
		result.reason = "Cannot make pact during war"
		return result

	var relation := SimFactions.get_relation(state, faction_id)
	if relation < SimFactions.RELATION_NEUTRAL:
		result.reason = "Relations too poor"
		return result

	result.ok = true
	return result


## Check if we can propose an alliance
static func can_propose_alliance(state, faction_id: String) -> Dictionary:
	var result := {"ok": false, "reason": ""}

	if SimFactions.has_alliance(state, faction_id):
		result.reason = "Already allied"
		return result

	if SimFactions.is_at_war(state, faction_id):
		result.reason = "Cannot ally during war"
		return result

	var relation := SimFactions.get_relation(state, faction_id)
	if relation < SimFactions.RELATION_FRIENDLY:
		result.reason = "Relations not friendly enough"
		return result

	# Must have non-aggression pact first
	if not SimFactions.has_non_aggression_pact(state, faction_id):
		result.reason = "Requires non-aggression pact first"
		return result

	result.ok = true
	return result


## Check if we can pay tribute
static func can_pay_tribute(state, faction_id: String) -> Dictionary:
	var result := {"ok": false, "reason": ""}

	var tribute := SimFactions.get_tribute_demand(state, faction_id)
	if state.gold < tribute:
		result.reason = "Not enough gold (%d required)" % tribute
		return result

	result.ok = true
	result.cost = tribute
	return result


## Check if we can declare war
static func can_declare_war(state, faction_id: String) -> Dictionary:
	var result := {"ok": false, "reason": ""}

	if SimFactions.is_at_war(state, faction_id):
		result.reason = "Already at war"
		return result

	if SimFactions.has_alliance(state, faction_id):
		result.reason = "Cannot attack ally"
		return result

	result.ok = true
	return result


## Check if we can offer peace
static func can_offer_peace(state, faction_id: String) -> Dictionary:
	var result := {"ok": false, "reason": ""}

	if not SimFactions.is_at_war(state, faction_id):
		result.reason = "Not at war"
		return result

	# Peace requires payment
	var peace_cost := SimFactions.get_tribute_demand(state, faction_id) * 2
	if state.gold < peace_cost:
		result.reason = "Not enough gold for peace (%d required)" % peace_cost
		return result

	result.ok = true
	result.cost = peace_cost
	return result


## Check if we can send a gift
static func can_send_gift(state, faction_id: String, gift_type: String, amount: int) -> Dictionary:
	var result := {"ok": false, "reason": ""}

	if SimFactions.is_at_war(state, faction_id):
		result.reason = "Cannot send gifts during war"
		return result

	match gift_type:
		"gold":
			if state.gold < amount:
				result.reason = "Not enough gold"
				return result
		"food":
			if int(state.resources.get("food", 0)) < amount:
				result.reason = "Not enough food"
				return result
		"wood":
			if int(state.resources.get("wood", 0)) < amount:
				result.reason = "Not enough wood"
				return result
		"stone":
			if int(state.resources.get("stone", 0)) < amount:
				result.reason = "Not enough stone"
				return result
		_:
			result.reason = "Invalid gift type"
			return result

	result.ok = true
	return result


# =============================================================================
# DIPLOMATIC ACTIONS
# =============================================================================

## Propose a trade agreement
static func propose_trade(state, faction_id: String) -> Dictionary:
	var check := can_propose_trade(state, faction_id)
	if not check.ok:
		return {"success": false, "message": check.reason}

	# AI decides based on personality and relations
	var accepted := _ai_accept_proposal(state, faction_id, "trade")

	if accepted:
		_add_agreement(state, faction_id, "trade")
		SimFactions.change_relation(state, faction_id, SimFactions.RELATION_CHANGE_TRADE)
		return {
			"success": true,
			"message": "%s accepts trade agreement!" % SimFactions.get_faction_name(faction_id)
		}
	else:
		return {
			"success": false,
			"message": "%s declines trade agreement." % SimFactions.get_faction_name(faction_id)
		}


## Propose a non-aggression pact
static func propose_pact(state, faction_id: String) -> Dictionary:
	var check := can_propose_pact(state, faction_id)
	if not check.ok:
		return {"success": false, "message": check.reason}

	var accepted := _ai_accept_proposal(state, faction_id, "pact")

	if accepted:
		_add_agreement(state, faction_id, "non_aggression")
		SimFactions.change_relation(state, faction_id, 5)
		return {
			"success": true,
			"message": "%s agrees to non-aggression pact!" % SimFactions.get_faction_name(faction_id)
		}
	else:
		return {
			"success": false,
			"message": "%s refuses the pact." % SimFactions.get_faction_name(faction_id)
		}


## Propose an alliance
static func propose_alliance(state, faction_id: String) -> Dictionary:
	var check := can_propose_alliance(state, faction_id)
	if not check.ok:
		return {"success": false, "message": check.reason}

	var accepted := _ai_accept_proposal(state, faction_id, "alliance")

	if accepted:
		_add_agreement(state, faction_id, "alliance")
		SimFactions.change_relation(state, faction_id, SimFactions.RELATION_CHANGE_ALLIANCE)
		return {
			"success": true,
			"message": "%s joins your alliance!" % SimFactions.get_faction_name(faction_id)
		}
	else:
		return {
			"success": false,
			"message": "%s declines the alliance." % SimFactions.get_faction_name(faction_id)
		}


## Pay tribute to a faction
static func pay_tribute(state, faction_id: String) -> Dictionary:
	var check := can_pay_tribute(state, faction_id)
	if not check.ok:
		return {"success": false, "message": check.reason}

	var tribute: int = check.cost
	state.gold -= tribute
	SimFactions.change_relation(state, faction_id, SimFactions.RELATION_CHANGE_TRIBUTE)

	return {
		"success": true,
		"message": "Paid %d gold tribute to %s. Relations improved." % [tribute, SimFactions.get_faction_name(faction_id)],
		"gold_spent": tribute
	}


## Declare war on a faction
static func declare_war(state, faction_id: String) -> Dictionary:
	var check := can_declare_war(state, faction_id)
	if not check.ok:
		return {"success": false, "message": check.reason}

	# Break all existing agreements
	_remove_agreement(state, faction_id, "trade")
	_remove_agreement(state, faction_id, "non_aggression")
	_remove_agreement(state, faction_id, "alliance")

	# Add to war list
	_add_agreement(state, faction_id, "war")

	# Major relation hit
	SimFactions.change_relation(state, faction_id, SimFactions.RELATION_CHANGE_WAR_DECLARED)

	return {
		"success": true,
		"message": "War declared on %s!" % SimFactions.get_faction_name(faction_id)
	}


## Offer peace to end war
static func offer_peace(state, faction_id: String) -> Dictionary:
	var check := can_offer_peace(state, faction_id)
	if not check.ok:
		return {"success": false, "message": check.reason}

	# AI considers peace offer
	var relation := SimFactions.get_relation(state, faction_id)
	var accepted := relation > SimFactions.RELATION_HOSTILE or randf() < 0.3

	if accepted:
		var peace_cost: int = check.cost
		state.gold -= peace_cost
		_remove_agreement(state, faction_id, "war")
		SimFactions.change_relation(state, faction_id, 20)  # Slight improvement

		return {
			"success": true,
			"message": "%s accepts peace for %d gold." % [SimFactions.get_faction_name(faction_id), peace_cost],
			"gold_spent": peace_cost
		}
	else:
		return {
			"success": false,
			"message": "%s refuses peace." % SimFactions.get_faction_name(faction_id)
		}


## Send a gift to improve relations
static func send_gift(state, faction_id: String, gift_type: String, amount: int) -> Dictionary:
	var check := can_send_gift(state, faction_id, gift_type, amount)
	if not check.ok:
		return {"success": false, "message": check.reason}

	# Deduct resources
	match gift_type:
		"gold":
			state.gold -= amount
		"food", "wood", "stone":
			state.resources[gift_type] = int(state.resources.get(gift_type, 0)) - amount

	# Calculate relation gain based on gift value
	var relation_gain := int(amount / 10.0)  # 1 relation per 10 units
	relation_gain = clampi(relation_gain, 1, 15)  # Cap at 15

	if gift_type == "gold":
		relation_gain = int(relation_gain * 1.5)  # Gold is more valuable

	SimFactions.change_relation(state, faction_id, relation_gain)

	return {
		"success": true,
		"message": "Sent %d %s to %s. Relations improved by %d." % [
			amount, gift_type, SimFactions.get_faction_name(faction_id), relation_gain
		]
	}


## Break an agreement (with consequences)
static func break_agreement(state, faction_id: String, agreement_type: String) -> Dictionary:
	var agreements: Array = state.faction_agreements.get(agreement_type, [])
	if faction_id not in agreements:
		return {"success": false, "message": "No such agreement"}

	_remove_agreement(state, faction_id, agreement_type)
	SimFactions.change_relation(state, faction_id, SimFactions.RELATION_CHANGE_BROKEN_PACT)

	return {
		"success": true,
		"message": "Broke %s agreement with %s. Relations severely damaged." % [
			agreement_type, SimFactions.get_faction_name(faction_id)
		]
	}


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

## Add an agreement with a faction
static func _add_agreement(state, faction_id: String, agreement_type: String) -> void:
	if not state.faction_agreements.has(agreement_type):
		state.faction_agreements[agreement_type] = []
	if faction_id not in state.faction_agreements[agreement_type]:
		state.faction_agreements[agreement_type].append(faction_id)


## Remove an agreement with a faction
static func _remove_agreement(state, faction_id: String, agreement_type: String) -> void:
	if state.faction_agreements.has(agreement_type):
		var idx := state.faction_agreements[agreement_type].find(faction_id)
		if idx >= 0:
			state.faction_agreements[agreement_type].remove_at(idx)


## AI decision to accept a proposal
static func _ai_accept_proposal(state, faction_id: String, proposal_type: String) -> bool:
	var relation := SimFactions.get_relation(state, faction_id)
	var personality := SimFactions.get_faction_personality(faction_id)

	# Base acceptance chance from relations
	var base_chance := (relation + 100) / 200.0  # 0.0 at -100, 1.0 at +100

	# Modify by personality and proposal type
	match proposal_type:
		"trade":
			if personality == "mercantile":
				base_chance += 0.3
			elif personality == "isolationist":
				base_chance -= 0.2
		"pact":
			if personality == "isolationist":
				base_chance += 0.2
			elif personality == "aggressive":
				base_chance -= 0.1
		"alliance":
			if personality == "aggressive":
				base_chance -= 0.2  # Aggressive factions prefer independence
			base_chance -= 0.1  # Alliances are harder to get

	return randf() < clampf(base_chance, 0.1, 0.9)


# =============================================================================
# FACTION AI ACTIONS
# =============================================================================

## Process faction AI for a day
static func process_faction_turn(state, faction_id: String) -> Array:
	var events: Array = []

	var intent := SimFactions.get_faction_intent(state, faction_id)
	var action: String = intent.get("action", "none")

	match action:
		"declare_war":
			_add_agreement(state, faction_id, "war")
			SimFactions.change_relation(state, faction_id, -30)
			events.append("%s has declared war!" % SimFactions.get_faction_name(faction_id))

		"demand_tribute":
			var tribute := SimFactions.get_tribute_demand(state, faction_id)
			state.pending_diplomacy[faction_id] = {
				"type": "tribute_demand",
				"amount": tribute,
				"expires_day": state.day + 3
			}
			events.append("%s demands %d gold in tribute." % [SimFactions.get_faction_name(faction_id), tribute])

		"offer_trade":
			state.pending_diplomacy[faction_id] = {
				"type": "trade_offer",
				"expires_day": state.day + 5
			}
			events.append("%s offers a trade agreement." % SimFactions.get_faction_name(faction_id))

		"offer_pact":
			state.pending_diplomacy[faction_id] = {
				"type": "pact_offer",
				"expires_day": state.day + 5
			}
			events.append("%s offers a non-aggression pact." % SimFactions.get_faction_name(faction_id))

		"offer_peace":
			state.pending_diplomacy[faction_id] = {
				"type": "peace_offer",
				"expires_day": state.day + 2
			}
			events.append("%s seeks peace." % SimFactions.get_faction_name(faction_id))

	return events


## Accept a pending diplomatic offer
static func accept_pending_offer(state, faction_id: String) -> Dictionary:
	if not state.pending_diplomacy.has(faction_id):
		return {"success": false, "message": "No pending offer"}

	var offer: Dictionary = state.pending_diplomacy[faction_id]
	var offer_type: String = offer.get("type", "")

	state.pending_diplomacy.erase(faction_id)

	match offer_type:
		"trade_offer":
			_add_agreement(state, faction_id, "trade")
			SimFactions.change_relation(state, faction_id, SimFactions.RELATION_CHANGE_TRADE)
			return {"success": true, "message": "Trade agreement established with %s." % SimFactions.get_faction_name(faction_id)}

		"pact_offer":
			_add_agreement(state, faction_id, "non_aggression")
			SimFactions.change_relation(state, faction_id, 5)
			return {"success": true, "message": "Non-aggression pact signed with %s." % SimFactions.get_faction_name(faction_id)}

		"tribute_demand":
			var amount: int = offer.get("amount", 50)
			if state.gold < amount:
				return {"success": false, "message": "Not enough gold"}
			state.gold -= amount
			SimFactions.change_relation(state, faction_id, SimFactions.RELATION_CHANGE_TRIBUTE)
			return {"success": true, "message": "Paid %d gold tribute to %s." % [amount, SimFactions.get_faction_name(faction_id)]}

		"peace_offer":
			_remove_agreement(state, faction_id, "war")
			SimFactions.change_relation(state, faction_id, 10)
			return {"success": true, "message": "Peace achieved with %s." % SimFactions.get_faction_name(faction_id)}

	return {"success": false, "message": "Unknown offer type"}


## Decline a pending diplomatic offer
static func decline_pending_offer(state, faction_id: String) -> Dictionary:
	if not state.pending_diplomacy.has(faction_id):
		return {"success": false, "message": "No pending offer"}

	var offer: Dictionary = state.pending_diplomacy[faction_id]
	var offer_type: String = offer.get("type", "")

	state.pending_diplomacy.erase(faction_id)

	# Consequences for declining
	match offer_type:
		"tribute_demand":
			SimFactions.change_relation(state, faction_id, -15)
			# Aggressive factions may declare war
			if SimFactions.get_faction_personality(faction_id) == "aggressive":
				if randf() < 0.4:
					_add_agreement(state, faction_id, "war")
					return {"success": true, "message": "%s declares war in response!" % SimFactions.get_faction_name(faction_id)}
			return {"success": true, "message": "Declined tribute. Relations worsened."}

		"trade_offer", "pact_offer":
			SimFactions.change_relation(state, faction_id, -5)
			return {"success": true, "message": "Declined offer. Slight relation penalty."}

		"peace_offer":
			return {"success": true, "message": "War continues."}

	return {"success": true, "message": "Offer declined."}


## Get summary of all diplomatic relations
static func get_diplomacy_summary(state) -> Array:
	var summary := []

	for faction_id in SimFactions.get_faction_ids():
		var faction_data := SimFactions.get_faction(faction_id)
		var relation := SimFactions.get_relation(state, faction_id)
		var status := SimFactions.get_relation_status(state, faction_id)

		var agreements := []
		if SimFactions.has_trade_agreement(state, faction_id):
			agreements.append("trade")
		if SimFactions.has_non_aggression_pact(state, faction_id):
			agreements.append("pact")
		if SimFactions.has_alliance(state, faction_id):
			agreements.append("alliance")
		if SimFactions.is_at_war(state, faction_id):
			agreements.append("war")

		var pending = state.pending_diplomacy.get(faction_id, {})

		summary.append({
			"id": faction_id,
			"name": SimFactions.get_faction_name(faction_id),
			"description": str(faction_data.get("description", "")),
			"relation": relation,
			"status": status,
			"agreements": agreements,
			"pending": pending,
			"color": SimFactions.get_faction_color(faction_id),
			"military_strength": SimFactions.get_military_strength(faction_id)
		})

	return summary
