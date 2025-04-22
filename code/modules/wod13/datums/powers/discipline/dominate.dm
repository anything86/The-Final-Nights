/datum/discipline/dominate
	name = "Dominate"
	desc = "Supresses will of your targets and forces them to obey you, if their will is not more powerful than yours."
	icon_state = "dominate"
	power_type = /datum/discipline_power/dominate

/datum/discipline/dominate/post_gain()
	. = ..()
	if(level >= 1)
		var/obj/effect/proc_holder/spell/voice_of_god/voice_of_domination = new(owner)
		owner.mind.AddSpell(voice_of_domination)
		RegisterSignal(owner, COMSIG_MOB_EMOTE, PROC_REF(on_snap))

/datum/discipline/dominate/proc/on_snap(atom/source, datum/emote/emote_args)
	SIGNAL_HANDLER

	INVOKE_ASYNC(src, PROC_REF(handle_snap), source, emote_args)

/datum/discipline/dominate/proc/handle_snap(atom/source, datum/emote/emote_args)
	var/list/emote_list = list("snap", "snap2", "snap3", "whistle")
	if(!emote_list.Find(emote_args.key))
		return
	for(var/mob/living/carbon/human/target in get_hearers_in_view(6, owner))
		var/mob/living/carbon/human/conditioner = target.conditioner?.resolve()
		if(conditioner != owner)
			continue
		switch(emote_args.key)
			if("snap")
				target.SetSleeping(0)
				target.silent = 3
				target.dir = get_dir(target, owner)
				target.emote("me", 1, "faces towards <b>[owner]</b> attentively.", TRUE)
				to_chat(target, span_danger("ATTENTION"))
			if("snap2")
				target.dir = get_dir(target, owner)
				target.Immobilize(50)
				target.emote("me",1,"flinches in response to <b>[owner]'s</b> snapping.", TRUE)
				to_chat(target, span_danger("HALT"))
			if("snap3")
				target.Knockdown(50)
				target.Immobilize(80)
				target.emote("me",1,"'s knees buckle under the weight of their body.",TRUE)
				target.do_jitter_animation(0.1 SECONDS)
				to_chat(target, span_danger("DROP"))
			if("whistle")
				target.apply_status_effect(STATUS_EFFECT_AWE, owner)
				to_chat(target, span_danger("HITHER"))


/datum/discipline_power/dominate
	name = "Dominate power name"
	desc = "Dominate power description"

	activate_sound = 'code/modules/wod13/sounds/dominate.ogg'

/datum/discipline_power/dominate/activate(mob/living/target)
	. = ..()
	var/mob/living/carbon/human/dominate_target
	if(ishuman(target))
		dominate_target = target
		dominate_target.remove_overlay(MUTATIONS_LAYER)
		var/mutable_appearance/dominate_overlay = mutable_appearance('code/modules/wod13/icons.dmi', "dominate", -MUTATIONS_LAYER)
		dominate_overlay.pixel_z = 2
		dominate_target.overlays_standing[MUTATIONS_LAYER] = dominate_overlay
		dominate_target.apply_overlay(MUTATIONS_LAYER)
		addtimer(CALLBACK(dominate_target, TYPE_PROC_REF(/mob/living/carbon/human, post_dominate_checks), dominate_target), 2 SECONDS)
	return TRUE

/datum/discipline_power/dominate/proc/dominate_check(mob/living/carbon/human/owner, mob/living/target, tiebreaker = FALSE) //These checks are common to all applications of Dominate.
	var/mypower = owner.get_total_social()
	var/theirpower = target.get_total_mentality()
	var/mob/living/carbon/human/conditioner = target.conditioner?.resolve()

	if(owner == conditioner)
		return TRUE

	if(target.conditioned)
		theirpower += 3

	if(ishuman(target))
		var/mob/living/carbon/human/human_target = target
		if(human_target.clane?.name == "Gargoyle")
			return TRUE

	if((theirpower >= mypower) && !tiebreaker || (owner.generation > target.generation) || (theirpower > mypower))
		to_chat(owner, span_warning("[target]'s mind is too powerful to dominate!"))
		return FALSE

	return TRUE

/datum/movespeed_modifier/dominate
	multiplicative_slowdown = 5


//COMMAND
/datum/discipline_power/dominate/command
	name = "Command"
	desc = "Speak one word and force others to obey."

	level = 1

	check_flags = DISC_CHECK_CAPABLE|DISC_CHECK_SPEAK|DISC_CHECK_SEE
	target_type = TARGET_LIVING

	multi_activate = TRUE
	cooldown_length = 15 SECONDS
	duration_length = 3 SECONDS
	range = 7
	var/tmp/command_succeeded = FALSE

/datum/discipline_power/dominate/command/pre_activation_checks(mob/living/target)

	// Early success / failure if target is not human or if target is a Gargoyle.
	if(!ishuman(target))
		return FALSE 

	if(ishuman(target))
		var/mob/living/carbon/human/human_target = target
		if(human_target.clane?.name == "Gargoyle")
			command_succeeded = TRUE
			return TRUE

	var/mypower = SSroll.storyteller_roll(owner.get_total_social(), difficulty = 4, mobs_to_show_output = owner, numerical = TRUE)
	var/theirpower = SSroll.storyteller_roll(target.get_total_mentality(), difficulty = 6, mobs_to_show_output = target, numerical = TRUE)

	if(mypower > theirpower && owner.generation <= target.generation)
		command_succeeded = TRUE
	else
		command_succeeded = FALSE

	return TRUE // proceed regardless

/datum/discipline_power/dominate/command/activate(mob/living/target)
	. = ..()

	if(command_succeeded)
		to_chat(owner, span_warning("You've successfully dominated [target]'s mind!"))
		to_chat(target, span_danger("FORGET ABOUT IT"))
		owner.say("FORGET ABOUT IT!!")
		ADD_TRAIT(target, TRAIT_BLIND, "dominate")
	else
		to_chat(owner, span_warning("[target] has resisted your domination!"))
		to_chat(target, span_warning("Your thoughts blur—[owner] tries to bend your will. You resist."))

/datum/discipline_power/dominate/command/deactivate(mob/living/target)
	. = ..()
	REMOVE_TRAIT(target, TRAIT_BLIND, "dominate")

//MESMERIZE
/datum/discipline_power/dominate/mesmerize
	name = "Mesmerize"
	desc = "Plant a suggestion in a target's head and force them to obey it."

	level = 2

	check_flags = DISC_CHECK_CAPABLE|DISC_CHECK_SPEAK|DISC_CHECK_SEE
	target_type = TARGET_LIVING

	multi_activate = TRUE
	cooldown_length = 15 SECONDS
	range = 7
	var/tmp/mesmerize_succeeded = FALSE

/datum/discipline_power/dominate/mesmerize/pre_activation_checks(mob/living/target)

	// Early success / failure if target is not human or if target is a Gargoyle.
	if(!ishuman(target))
		return FALSE 

	if(ishuman(target))
		var/mob/living/carbon/human/human_target = target
		if(human_target.clane?.name == "Gargoyle")
			mesmerize_succeeded = TRUE
			return TRUE

	var/mypower = SSroll.storyteller_roll(owner.get_total_social(), difficulty = 5, mobs_to_show_output = owner, numerical = TRUE)
	var/theirpower = SSroll.storyteller_roll(target.get_total_mentality(), difficulty = 6, mobs_to_show_output = target, numerical = TRUE)

	if(mypower > theirpower && owner.generation <= target.generation)
		mesmerize_succeeded = TRUE
	else
		mesmerize_succeeded = FALSE

	return TRUE // continue either way

/datum/discipline_power/dominate/mesmerize/activate(mob/living/target)
	. = ..()

	if(mesmerize_succeeded)
		target.Immobilize(0.5 SECONDS)
		if(target.body_position == STANDING_UP)
			to_chat(owner, span_warning("You've successfully dominated [target]'s mind!"))
			to_chat(target, span_danger("GET DOWN"))
			target.toggle_resting()
			owner.say("GET DOWN!!")
		else
			to_chat(owner, span_warning("You've successfully dominated [target]'s mind!"))
			to_chat(target, span_danger("STAY DOWN"))
			owner.say("STAY DOWN!!")
	else
		to_chat(owner, span_warning("[target]'s mind has resisted your domination!"))
		to_chat(target, span_warning("Your thoughts blur—[owner] tries to bend your will. You resist."))

//THE FORGETFUL MIND
/datum/discipline_power/dominate/the_forgetful_mind
	name = "The Forgetful Mind"
	desc = "Invade a person's mind and recreate their memories."

	level = 3

	check_flags = DISC_CHECK_CAPABLE|DISC_CHECK_SPEAK|DISC_CHECK_SEE
	target_type = TARGET_LIVING

	multi_activate = TRUE
	cooldown_length = 15 SECONDS
	duration_length = 3 SECONDS
	range = 7
	var/tmp/the_forgetful_mind_succeeded = FALSE

/datum/discipline_power/dominate/the_forgetful_mind/pre_activation_checks(mob/living/target)

	// Early success / failure if target is not human or if target is a Gargoyle.
	if(!ishuman(target))
		return FALSE 

	if(ishuman(target))
		var/mob/living/carbon/human/human_target = target
		if(human_target.clane?.name == "Gargoyle")
			the_forgetful_mind_succeeded = TRUE
			return TRUE

	var/mypower = SSroll.storyteller_roll(owner.get_total_social(), difficulty = 6, mobs_to_show_output = owner, numerical = TRUE)
	var/theirpower = SSroll.storyteller_roll(target.get_total_mentality(), difficulty = 6, mobs_to_show_output = target, numerical = TRUE)

	if(mypower > theirpower && owner.generation <= target.generation)
		the_forgetful_mind_succeeded = TRUE
	else
		the_forgetful_mind_succeeded = FALSE

	return TRUE // proceed to activation regardless

/datum/discipline_power/dominate/the_forgetful_mind/activate(mob/living/target)
	. = ..()

	if(the_forgetful_mind_succeeded)
		to_chat(owner, span_warning("You've successfully dominated [target]'s mind!"))
		to_chat(target, span_danger("THINK TWICE"))
		owner.say("THINK TWICE!!")
		target.add_movespeed_modifier(/datum/movespeed_modifier/dominate)
	else
		to_chat(owner, span_warning("[target]'s mind has resisted your domination!"))
		to_chat(target, span_warning("Your thoughts blur—[owner] tries to bend your will. You resist."))

/datum/discipline_power/dominate/the_forgetful_mind/deactivate(mob/living/target)
	. = ..()
	target.remove_movespeed_modifier(/datum/movespeed_modifier/dominate)

//CONDITIONING
/datum/discipline_power/dominate/conditioning
	name = "Conditioning"
	desc = "Break a person's mind over time and bend them to your will."

	level = 4

	check_flags = DISC_CHECK_CAPABLE|DISC_CHECK_SPEAK|DISC_CHECK_SEE
	target_type = TARGET_LIVING

	multi_activate = TRUE
	cooldown_length = 15 SECONDS
	duration_length = 6 SECONDS
	range = 2
	var/tmp/conditioning_succeeded = FALSE

/datum/discipline_power/dominate/conditioning/pre_activation_checks(mob/living/target)

	var/mob/living/carbon/human/conditioner = target.conditioner?.resolve()
	if(owner == conditioner)
		to_chat(owner, span_warning("[target]'s mind is already under my sway!"))
		return FALSE
	else if(target.conditioned)
		to_chat(owner, span_warning("[target]'s mind appears to already be under someone else's sway!"))
		return FALSE

	// Early success / failure if target is not human or if target is a Gargoyle.
	if(!ishuman(target))
		return FALSE 

	if(ishuman(target))
		var/mob/living/carbon/human/human_target = target
		if(human_target.clane?.name == "Gargoyle")
			conditioning_succeeded = TRUE
			return TRUE

	var/mypower = SSroll.storyteller_roll(owner.get_total_social(), difficulty = 6, mobs_to_show_output = owner, numerical = TRUE)
	var/theirpower = SSroll.storyteller_roll(target.get_total_mentality(), difficulty = 6, mobs_to_show_output = target, numerical = TRUE)

	if(mypower > theirpower && owner.generation <= target.generation)
		conditioning_succeeded = TRUE
	else
		conditioning_succeeded = FALSE

	return TRUE // allow activation to continue either way

/datum/discipline_power/dominate/conditioning/activate(mob/living/target)
	. = ..()

	if(conditioning_succeeded)
		target.dir = get_dir(target, owner)
		to_chat(target, span_danger("LOOK AT ME"))
		owner.say("Look at me.")
		if(do_mob(owner, target, 20 SECONDS))
			target.conditioned = TRUE
			target.conditioner = WEAKREF(owner)
			target.additional_social -= 3
			to_chat(target, span_danger("Your mind is filled with thoughts surrounding [owner]. Their every word and gesture carries weight to you."))
	else
		to_chat(owner, span_warning("[target]'s mind has resisted your domination!"))
		to_chat(target, span_warning("Your thoughts blur—[owner] tries to bend your will. You resist."))

/datum/discipline_power/dominate/conditioning/deactivate(mob/living/target)
	. = ..()

//POSSESSION
/datum/discipline_power/dominate/possession
	name = "Possession"
	desc = "Take full control of your target's mind and body."

	level = 5

	check_flags = DISC_CHECK_CAPABLE|DISC_CHECK_SPEAK|DISC_CHECK_SEE
	target_type = TARGET_HUMAN

	multi_activate = TRUE
	cooldown_length = 15 SECONDS
	range = 7
	var/tmp/possession_succeeded = FALSE


/datum/discipline_power/dominate/possession/pre_activation_checks(mob/living/target)

	// Early success / failure if target is not human or if target is a Gargoyle.
	if(!ishuman(target))
		return FALSE 
		
	if(ishuman(target))
		var/mob/living/carbon/human/human_target = target
		if(human_target.clane?.name == "Gargoyle")
			possession_succeeded = TRUE
			return TRUE

	var/mypower = SSroll.storyteller_roll(owner.get_total_social(), difficulty = 7, mobs_to_show_output = owner, numerical = TRUE)
	var/theirpower = SSroll.storyteller_roll(target.get_total_mentality(), difficulty = 6, mobs_to_show_output = target, numerical = TRUE)

	if(mypower > theirpower && owner.generation <= target.generation)
		possession_succeeded = TRUE
	else
		possession_succeeded = FALSE

	return TRUE // allow activation to continue either way

/datum/discipline_power/dominate/possession/activate(mob/living/carbon/human/target)
	. = ..()

	if(possession_succeeded)
		to_chat(owner, span_warning("You've successfully dominated [target]'s mind!"))
		to_chat(target, span_danger("YOU SHOULD HARM YOURSELF NOW"))
		owner.say("YOU SHOULD HARM YOURSELF NOW!!")

		var/datum/cb = CALLBACK(target, /mob/living/carbon/human/proc/attack_myself_command)
		for(var/i in 1 to 20)
			addtimer(cb, (i - 1) * 1.5 SECONDS)
	else
		to_chat(owner, span_warning("[target]'s mind has resisted your domination!"))
		to_chat(target, span_warning("Your thoughts blur—[owner] tries to bend your will. You resist."))


/mob/living/carbon/human/proc/attack_myself_command()
	if(!CheckFrenzyMove())
		a_intent = INTENT_HARM
		var/obj/item/I = get_active_held_item()
		if(I)
			if(I.force)
				ClickOn(src)
			else
				drop_all_held_items()
				ClickOn(src)
		else
			ClickOn(src)

/mob/living/carbon/human/proc/post_dominate_checks(mob/living/carbon/human/dominate_target)
	if(dominate_target)
		dominate_target.remove_overlay(MUTATIONS_LAYER)
