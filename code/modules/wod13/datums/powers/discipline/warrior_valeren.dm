/datum/discipline/valeren_warrior
	name = "Warrior Valeren"
	desc = "Use your third eye in warding and delivering retribution."
	icon_state = "valeren"
	clan_restricted = TRUE
	power_type = /datum/discipline_power/valeren_warrior

/datum/discipline_power/valeren_warrior
	name = "Valeren power name"
	desc = "Valeren power description"

	activate_sound = 'code/modules/wod13/sounds/valeren.ogg'

//SENSE DEATH
/datum/discipline_power/valeren_warrior/sense_death
	name = "Sense Death"
	desc = "Detect at a glance the extent of your foe's defenses, as well as their vitae reserves."

	level = 1
	vitae_cost = 0
	check_flags = DISC_CHECK_CONSCIOUS | DISC_CHECK_CAPABLE
	target_type = TARGET_HUMAN
	range = 7

	cooldown_length = 5 SECONDS

/datum/discipline_power/valeren_warrior/sense_death/activate(mob/living/carbon/human/target)
	. = ..()
	to_chat(owner, "<b>[target]</b> has <b>[num2text(target.bloodpool)]/[target.maxbloodpool]</b> blood points.")
	if(iskindred(target))
		for(var/datum/action/discipline/D in target.actions)
			if(D.discipline.name == "Fortitude")
				to_chat(owner, "<b>[target]</b> has a Fortitude rating of [D.discipline.level]")

//MORPHEAN BLOW
/datum/discipline_power/valeren_warrior/morphean_blow
	name = "Morphean Blow"
	desc = "Blunt the sensation of your own wounds, drive foes into slumber."

	level = 2
	check_flags = DISC_CHECK_CONSCIOUS | DISC_CHECK_CAPABLE | DISC_CHECK_LYING | DISC_CHECK_FREE_HAND
	target_type = TARGET_SELF | TARGET_LIVING
	range = 1

	aggravating = TRUE
	hostile = TRUE

	cooldown_length = 20 SECONDS

/datum/discipline_power/valeren_warrior/morphean_blow/activate(mob/living/target)
	. = ..()
	if(target == owner)
		ADD_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, TRAIT_GENERIC)
		sleep(600)
		REMOVE_TRAIT(owner, TRAIT_IGNOREDAMAGESLOWDOWN, TRAIT_GENERIC)
	else
		target.add_confusion(5)
		target.drowsyness += 4

//BURNING TOUCH
/datum/discipline_power/valeren_warrior/burning_touch
	name = "Burning Touch"
	desc = "Inflict grievous pain on a target for as long as you touch them."

	level = 3
	check_flags = DISC_CHECK_CONSCIOUS | DISC_CHECK_CAPABLE | DISC_CHECK_LYING | DISC_CHECK_FREE_HAND
	target_type = TARGET_LIVING
	range = 1

	aggravating = TRUE
	hostile = TRUE

	cooldown_length = 10 SECONDS

/datum/discipline_power/valeren_warrior/burning_touch/activate(mob/living/carbon/target)
	. = ..()
	target.grabbedby(owner)
	target.grippedby(owner, instant = TRUE)
	target.apply_status_effect(STATUS_EFFECT_BURNING_TOUCH, owner)

//ARMOR OF CAINE'S FURY
/datum/discipline_power/valeren_warrior/armor_of_caines_fury
	name = "Armor of Caine's Fury"
	desc = "Flare open your third eye, shrouding yourself in a protective crimson halo."

	level = 4
	check_flags = DISC_CHECK_CONSCIOUS | DISC_CHECK_CAPABLE
	vitae_cost = 2

	violates_masquerade = TRUE

	cancelable = TRUE
	duration_length = 1 SCENES //Unreliable protection, doesn't protect against burn/aggravated, but lasts for scene.
	cooldown_length = 30 SECONDS
	var/lastmypower

/datum/discipline_power/valeren_warrior/armor_of_caines_fury/activate()
	. = ..()
	var/fortitudelevel
	var/totaldice
	var/datum/species/kindred = owner.dna.species
	if(ispath(kindred, /datum/species/kindred))
		for(var/datum/discipline/fortitude/D in kindred) //An easier way to fetch this would be really nice.
			fortitudelevel = D.level
	totaldice = (owner.get_total_physique() + fortitudelevel)
	var/mypower = SSroll.storyteller_roll(totaldice, difficulty = 7, mobs_to_show_output = owner, numerical = TRUE)
	mypower = clamp(mypower, 1, 5)
	owner.physiology.armor.melee += (15*mypower)
	owner.physiology.armor.bullet += (15*mypower)
	animate(owner, color = "#b86262", time = 1 SECONDS, loop = 1)
	lastmypower = mypower

/datum/discipline_power/valeren_warrior/armor_of_caines_fury/deactivate()
	. = ..()
	playsound(owner.loc, 'sound/magic/voidblink.ogg', 50, FALSE)
	owner.physiology.armor.melee -= (15*lastmypower)
	owner.physiology.armor.bullet -= (15*lastmypower)
	animate(owner, color = initial(owner.color), time = 1 SECONDS, loop = 1)

//SAMIEL'S VENGEANCE
/datum/discipline_power/valeren_warrior/samiels_vengeance
	name = "Samiel's Vengeance"
	desc = "Open your third eye and let it guide your weapon, striking with unerring accuracy and lethality."
	level = 5
	check_flags = DISC_CHECK_CONSCIOUS | DISC_CHECK_CAPABLE | DISC_CHECK_IMMOBILE
	vitae_cost = 3 //Basically can't miss, tripled damage on attack, hence same cost as tabletop.
	target_type = TARGET_LIVING
	range = 1

	aggravating = TRUE
	hostile = TRUE

	cooldown_length = 15 SECONDS

/datum/discipline_power/valeren_warrior/samiels_vengeance/can_activate(atom/target, alert = FALSE)
	. = ..()
	var/obj/item/I = owner.get_active_held_item()
	if(!I || I.force < 5)
		if(alert)
			to_chat(owner, span_warning("[src] can only be used with a weapon in hand!"))
		return FALSE


/datum/discipline_power/valeren_warrior/samiels_vengeance/activate(mob/living/carbon/target)
	. = ..()
	var/obj/item/I = owner.get_active_held_item()
	owner.dna.species.meleemod += 2 //3x damage, additive.
	I.armour_penetration += 40
	owner.visible_message(span_bolddanger("[owner]'s third eye flashes open, delivering a masterful blow to [target] with their [I]!"))
	playsound(target.loc, I.hitsound, 100, FALSE)
	target.attacked_by(I, owner)
	owner.dna.species.meleemod -= 2
	I.armour_penetration -= 40
