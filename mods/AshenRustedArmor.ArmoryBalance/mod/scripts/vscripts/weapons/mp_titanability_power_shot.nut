//		Declarations
global function MpTitanAbilityPowerShot_Init

global function OnWeaponPrimaryAttack_power_shot
#if SERVER
global function OnWeaponNpcPrimaryAttack_power_shot
#endif

//	Init
void function MpTitanAbilityPowerShot_Init() {
	#if SERVER
	AddDamageCallbackSourceID( eDamageSourceId.mp_titanweapon_predator_cannon, PowerShot_DamagedEntity )
	RegisterSignal( "PowerShotCleanup" )
	#endif
}

//	     :::       ::: ::::::::::     :::     :::::::::   ::::::::  ::::    :::
//	    :+:       :+: :+:          :+: :+:   :+:    :+: :+:    :+: :+:+:   :+:
//	   +:+       +:+ +:+         +:+   +:+  +:+    +:+ +:+    +:+ :+:+:+  +:+
//	  +#+  +:+  +#+ +#++:++#   +#++:++#++: +#++:++#+  +#+    +:+ +#+ +:+ +#+
//	 +#+ +#+#+ +#+ +#+        +#+     +#+ +#+        +#+    +#+ +#+  +#+#+#
//	 #+#+# #+#+#  #+#        #+#     #+# #+#        #+#    #+# #+#   #+#+#
//	 ###   ###   ########## ###     ### ###         ########  ###    ####

int function OnWeaponPrimaryAttack_power_shot( entity weapon, WeaponPrimaryAttackParams attackParams ) {
	return PlayerOrNPC_FirePowerShot( weapon, attackParams, true )
}

#if SERVER
int function OnWeaponNpcPrimaryAttack_power_shot( entity weapon, WeaponPrimaryAttackParams attackParams ) {
	return PlayerOrNPC_FirePowerShot( weapon, attackParams, false )
}
#endif

int function PlayerOrNPC_FirePowerShot( entity weapon, WeaponPrimaryAttackParams attackParams, bool playerFired ) {
	//		Sanity checks
	//	Owner must be valid & committing
	entity owner = weapon.GetWeaponOwner()
	if ( owner.ContextAction_IsActive() || (playerFired && owner.PlayerMelee_GetState() != PLAYER_MELEE_STATE_NONE) )
		return 0

	//	Prevent power shot during ammo swap
	array<entity> weapons = GetPrimaryWeapons( owner )
	entity minigun = weapons[0]
	if ( !IsValid( minigun ) || minigun.IsReloading() || owner.e.ammoSwapPlaying == true )
		return 0

	//	Prevent power shot during reload
	int milestone = minigun.GetReloadMilestoneIndex()
	if ( milestone != 0 )
		return 0

	//	Prevent firing without the mod?
	if ( minigun.HasMod( "PowerShot_Common" ) )
		return 0

	//	Prevent power shot without ammo
	int rounds = minigun.GetWeaponPrimaryClipCount()
	if ( rounds == 0 )
		return 0

	#if SERVER
	//		Player functionality
	//	Force players to commit
	if( "forceCommit" in minigun.s ) {
		minigun.s.forceCommit = playerFired
	} else { minigun.s.forceCommit <- playerFired }

	if ( playerFired ) {
		owner.SetTitanDisembarkEnabled( false )
		owner.SetMeleeDisabled()
		PlayerUsedOffhand( owner, weapon )

		minigun.SetForcedADS()
	}

	//	Retrieve mods
	array<string> mods = minigun.GetMods()
	if( "normalShotMods" in minigun.s ) {
		minigun.s.normalShotMods = mods
	} else { minigun.s.normalShotMods <- mods }

	string powerShotName = "PowerShot_LRB_Shot"
	if ( mods.contains("CQB_ModeSwap") ) {
		mods.fastremovebyvalue("CQB_ModeSwap")
		powerShotName = "PowerShot_CQB_Slug"

		//	Not sure what to replace this with
		if ( mods.contains("fd_longrange_helper") )
			mods.append("fd_LongRangePowerShot")
	} else if ( mods.contains("fd_closerange_helper") )
		mods.append( "fd_CloseRangePowerShot" )

	mods.append( "PowerShot_Common" )
	mods.append( powerShotName )
	minigun.SetMods( mods )

	//	Cleanup thread
	thread PowerShotThreadedCleanup( owner, minigun )
	#endif

	//	Handle ammo
	return weapon.GetAmmoPerShot()
}

//	       :::::::::: :::    ::: ::::    :::  :::::::: ::::::::::: ::::::::::: ::::::::  ::::    :::  ::::::::
//	      :+:        :+:    :+: :+:+:   :+: :+:    :+:    :+:         :+:    :+:    :+: :+:+:   :+: :+:    :+:
//	     +:+        +:+    +:+ :+:+:+  +:+ +:+           +:+         +:+    +:+    +:+ :+:+:+  +:+ +:+
//	    :#::+::#   +#+    +:+ +#+ +:+ +#+ +#+           +#+         +#+    +#+    +:+ +#+ +:+ +#+ +#++:++#++
//	   +#+        +#+    +#+ +#+  +#+#+# +#+           +#+         +#+    +#+    +#+ +#+  +#+#+#        +#+
//	  #+#        #+#    #+# #+#   #+#+# #+#    #+#    #+#         #+#    #+#    #+# #+#   #+#+# #+#    #+#
//	 ###         ########  ###    ####  ########     ###     ########### ########  ###    ####  ########

#if SERVER
void function PowerShotThreadedCleanup( entity owner, entity weapon ) {
	//		Sanity checks
	//	Owner validity check
	if( !IsValid(owner) )
		return

	//	Weapon validity check
	if( !IsValid(weapon) )
		return

	//	weapon.s table check
	Assert( "forceCommit" in weapon.s )
	Assert( "normalShotMods" in weapon.s )

	//		Retrieve info
	bool forceCommit = expect bool(weapon.s.forceCommit)
	array<string> mods = expect array<string>(weapon.s.normalShotMods)

	//		Ending functionality
	OnThreadEnd( function() : ( owner, weapon, forceCommit, mods ) {
			//	Clear status
			if (IsValid(owner) && forceCommit) {
				owner.ClearMeleeDisabled()
				owner.SetTitanDisembarkEnabled( true )
			}

			if( IsValid(weapon) ) {
				weapon.ClearForcedADS()
				weapon.s.forceCommit = false

				weapon.SetMods(mods)
			}
	}	)

	//		Threading
	//	Termination signals
	owner.EndSignal("OnDeath")
	owner.EndSignal("TitanEjectionStarted")

	weapon.EndSignal( "OnDestroy" )
    weapon.EndSignal( "PowerShotCleanup" )

	WaitForever()
}

void function PowerShot_DamagedEntity( entity victim, var damageInfo ) {
	int scriptDamageType = DamageInfo_GetCustomDamageType( damageInfo )

	if ( scriptDamageType & DF_KNOCK_BACK && !IsHumanSized( victim ) ) {
		entity attacker = DamageInfo_GetAttacker( damageInfo )

		float distance = Distance( victim.GetOrigin(), attacker.GetOrigin() )
		vector pushback = Normalize( victim.GetOrigin() - attacker.GetOrigin() )
		pushback *= 500 * 1.0 - StatusEffect_Get( victim, eStatusEffect.pushback_dampen ) * GraphCapped( distance, 0, 1200, 1.0, 0.25 )

		PushPlayerAway( victim, pushback )
	}
}
#endif