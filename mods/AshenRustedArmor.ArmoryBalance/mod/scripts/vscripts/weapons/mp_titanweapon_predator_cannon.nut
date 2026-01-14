untyped

//		Init
//	Function declarations
global function MpTitanWeaponpredatorcannon_Init

global function OnWeaponActivate_titanweapon_predator_cannon
global function OnWeaponDeactivate_titanweapon_predator_cannon
global function OnWeaponOwnerChanged_titanweapon_predator_cannon

global function OnWeaponStartZoomIn_titanweapon_predator_cannon
global function OnWeaponStartZoomOut_titanweapon_predator_cannon

global function OnWeaponPrimaryAttack_titanweapon_predator_cannon
#if SERVER
global function OnWeaponNpcPrimaryAttack_titanweapon_predator_cannon
global function OnWeaponNpcPreAttack_titanweapon_predator_cannon
#endif

global function IsPredatorCannonActive

//	Constants
const asset SPIN_FX_1P = $"P_predator_barrel_blur_FP"
const asset SPIN_FX_3P = $"P_predator_barrel_blur"

void function MpTitanWeaponpredatorcannon_Init() {
	PrecacheParticleSystem( SPIN_FX_1P )
	PrecacheParticleSystem( SPIN_FX_3P )

	#if SERVER
	if ( GetCurrentPlaylistVarInt( "aegis_upgrades", 0 ) == 1 )
		AddDamageCallbackSourceID( eDamageSourceId.mp_titanweapon_predator_cannon, PredatorCannon_DamagedTarget )
	#endif
}

//	     :::       ::: ::::::::::     :::     :::::::::   ::::::::  ::::    :::
//	    :+:       :+: :+:          :+: :+:   :+:    :+: :+:    :+: :+:+:   :+:
//	   +:+       +:+ +:+         +:+   +:+  +:+    +:+ +:+    +:+ :+:+:+  +:+
//	  +#+  +:+  +#+ +#++:++#   +#++:++#++: +#++:++#+  +#+    +:+ +#+ +:+ +#+
//	 +#+ +#+#+ +#+ +#+        +#+     +#+ +#+        +#+    +#+ +#+  +#+#+#
//	 #+#+# #+#+#  #+#        #+#     #+# #+#        #+#    #+# #+#   #+#+#
//	 ###   ###   ########## ###     ### ###         ########  ###    ####

//		Activation/deactivation
void function OnWeaponActivate_titanweapon_predator_cannon( entity weapon ) {
	ManageSpinFX( weapon, false )

	if ( !( "initialized" in weapon.s ) ) {
		//	Smart ammo init
		weapon.s.damageValue <- weapon.GetWeaponInfoFileKeyField( "damage_near_value" )
		SmartAmmo_SetAllowUnlockedFiring( weapon, true )
		SmartAmmo_SetUnlockAfterBurst( weapon, false )
		SmartAmmo_SetWarningIndicatorDelay( weapon, 9999.0 )

		//	Power shot/ammo swap functionality change
		weapon.s.forceCommit <- false
		weapon.s.normalShotMods <- []

		//
		weapon.s.initialized <- true
	}

	#if SERVER
	weapon.s.locking = true
	weapon.s.lockStartTime = Time()
	#endif
}

void function OnWeaponDeactivate_titanweapon_predator_cannon( entity weapon ) {
	ManageSpinFX( weapon, false )
}

void function OnWeaponOwnerChanged_titanweapon_predator_cannon( entity weapon, WeaponOwnerChangedParams changeParams ) {
	ManageSpinFX( weapon, false )
}

//		Zooming
void function OnWeaponStartZoomIn_titanweapon_predator_cannon( entity weapon ) {
	ManageSpinFX( weapon, true, false )
}

void function OnWeaponStartZoomOut_titanweapon_predator_cannon( entity weapon ) {
	ManageSpinFX( weapon, true, true )
}

//		Attack handling
var function OnWeaponPrimaryAttack_titanweapon_predator_cannon( entity weapon, WeaponPrimaryAttackParams attackParams ) {
}

int function FireWeaponPlayerAndNPC( entity weapon, WeaponPrimaryAttackParams attackParams, bool playerFired ) {
	//		Sanity checks
	//	Owner validity
	entity owner = weapon.GetWeaponOwner()
	if ( !IsValid(owner) )
		return 0

	//	Full zoom
	if ( playerFired && owner.GetZoomFrac() < 1 ) //&& needsZoom ) { }
		return 0

	//		SFX
	weapon.EmitWeaponNpcSound( LOUD_WEAPON_AI_SOUND_RADIUS_MP, 0.2 )

	//		Normal shot
	bool isPowerShot = weapon.HasMod( "PowerShot_Common" )
	if ( !IsPowerShot ) {
		int damageFlags = weapon.GetWeaponDamageFlags()

		if ( weapon.HasMod( "Smart_Core" ) ) {
			return SmartAmmo_FireWeapon( weapon, attackParams, damageFlags, damageTypes.largeCaliber | DF_STOPS_TITAN_REGEN )
		}

		weapon.FireWeaponBullet( attackParams.pos, attackParams.dir, 1, damageFlags )
		return weapon.GetAmmoPerShot()
	}

	//		Power Shot
	//	Animation
	#if SERVER
	if ( playerFired && IsMultiplayer() ) {
		owner.Anim_PlayGesture( "ACT_SCRIPT_CUSTOM_ATTACK2", 0.2, 0.2, -1.0 )
	} else if ( !playerFired ) {
		string anim = "ACT_RANGE_ATTACK1_SINGLE"
		if ( owner.IsCrouching() )
			anim = "ACT_RANGE_ATTACK1_LOW_SINGLE"
		owner.Anim_ScriptedPlayActivityByName( anim, true, 0.0 )
	}
	#endif

	//	Get SFX
	string sfxFire1P = "Weapon_Predator_Powershot_LongRange_1P" //"Weapon_Predator_Powershot_ShortRange_1P"
	string sfxFire3P = "Weapon_Predator_Powershot_LongRange_1P" //"Weapon_Predator_Powershot_ShortRange_3P"

	if( weapon.HasMod("PowerShot_LRB_Shot") ) {
		//	Pick SFX & mods
		sfxFire1P = "Weapon_Predator_Powershot_ShortRange_1P"
		sfxFire3P = "Weapon_Predator_Powershot_ShortRange_3P"

		//	Projectile creation check
		bool makeProj = (IsServer() || weapon.ShouldPredictProjectiles())
		#if CLIENT
			&& playerFired
		#endif

		if( !makeProj )
			break

		//	Shot shell
		int damageFlags = weapon.GetWeaponDamageFlags()
		entity bolt = weapon.FireWeaponBolt( attackParams.pos, attackDir, boltSpeed, damageFlags, damageFlags, playerFired, index )
		if( bolt ) {
			olt.kv.gravity = -0.1
			#if SERVER
			bolt.e.onlyDamageEntitiesOnce = true
			#endif
		}
	}

	if( weapon.HasMod("PowerShot_CQB_Slug") ) {
		//	Slug shell
		int damageFlags = weapon.GetWeaponDamageFlags()

		if ( weapon.HasMod("fd_CloseRangePowerShot") )
			damageFlags = damageFlags | DF_SKIPS_DOOMED_STATE

		ShotgunBlast( weapon, attackParams.pos, attackParams.dir, 16, damageType, 1.0, 10.0 )
	}

	//	Why??
	if( playerFired ) {
		weapon.EmitWeaponSound_1p3p( sfxFire1P, sfxFire3P )
	} else {
		EmitSoundAtPosition( TEAM_UNASSIGNED, attackParams.pos, sfxFire3P )
	}

	//	Cleanup
	weapon.Signal("PowerShotCleanup")

	//	Ammo cost
	return weapon.GetAmmoPerShot()
}


#if SERVER
var function OnWeaponNpcPrimaryAttack_titanweapon_predator_cannon( entity weapon, WeaponPrimaryAttackParams attackParams ) {
	OnWeaponPrimaryAttack_titanweapon_predator_cannon( weapon, attackParams )
}

void function OnWeaponNpcPreAttack_titanweapon_predator_cannon( entity weapon ) {
	entity owner = weapon.GetWeaponOwner()
	thread PredatorSpinup( owner, weapon )
}
#endif

//	       :::::::::: :::    ::: ::::    :::  :::::::: ::::::::::: ::::::::::: ::::::::  ::::    :::  ::::::::
//	      :+:        :+:    :+: :+:+:   :+: :+:    :+:    :+:         :+:    :+:    :+: :+:+:   :+: :+:    :+:
//	     +:+        +:+    +:+ :+:+:+  +:+ +:+           +:+         +:+    +:+    +:+ :+:+:+  +:+ +:+
//	    :#::+::#   +#+    +:+ +#+ +:+ +#+ +#+           +#+         +#+    +#+    +:+ +#+ +:+ +#+ +#++:++#++
//	   +#+        +#+    +#+ +#+  +#+#+# +#+           +#+         +#+    +#+    +#+ +#+  +#+#+#        +#+
//	  #+#        #+#    #+# #+#   #+#+# #+#    #+#    #+#         #+#    #+#    #+# #+#   #+#+# #+#    #+#
//	 ###         ########  ###    ####  ########     ###     ########### ########  ###    ####  ########

const string SPINUP_SFX_1P = "weapon_predator_windup_1p"
const string SPINUP_SFX_3P = "weapon_predator_windup_3p"
const string SPINDOWN_SFX_1P = "weapon_predator_winddown_1p"
const string SPINDOWN_SFX_3P = "weapon_predator_winddown_3p"

const string MOTOR_SFX_1P = "Weapon_Predator_MotorLoop_1P"
const string MOTOR_SFX_3P = "Weapon_Predator_MotorLoop_3P"

const string ADS_IN_SFX = "wpn_predator_cannon_ads_in_mech_fr00_1p"
const string ADS_OUT_SFX = "wpn_predator_cannon_ads_in_mech_fr00_1p"
void function ManageSpinFX( entity weapon, bool playSeekFX, bool isOut = true  ) {
	//		Data retrieval
	//	Retrieve SFX
	string sfxSpin1P = SPINDOWN_SFX_1P
	string sfxSpin3P = SPINDOWN_SFX_3P

	string sfxSpinSeek = SPINUP_SFX_3P
	string sfxADS = ADS_IN_SFX

	//		Handle weapon-sided FX
	if ( isOut ) {
		//	Choose correct values
		sfxSpin1P = SPINUP_SFX_1P
		sfxSpin3P = SPINUP_SFX_3P

		sfxSpinSeek = SPINDOWN_SFX_3P
		sfxADS = ADS_OUT_SFX

		//	Stop spin FX
		weapon.StopWeaponSound( MOTOR_SFX_1P )
		weapon.StopWeaponSound( MOTOR_SFX_3P )

		weapon.StopWeaponEffect( SPIN_FX_1P, SPIN_FX_3P )
	} else {
		//	Start spin FX
		weapon.EmitWeaponSound_1p3p( MOTOR_SFX_1P, MOTOR_SFX_3P )
		weapon.PlayWeaponEffect( SPIN_FX_1P, SPIN_FX_3P, "fx_barrel" )
	}

	//	Stop windup/down sound
	StopSoundOnEntity( weapon, sfxSpin1P )
	StopSoundOnEntity( weapon, sfxSpin3P )

	//		Sanity checks
	if ( !playSeekFX )
		return

	entity owner = weapon.GetWeaponOwner()
	if ( !IsValid(owner) )
		return

	//		Play ADS SFX
	//	Retrieve timing
	float zoomFrac = owner.GetZoomFrac()
	float zoomTime = weapon.GetWeaponSettingFloat( eWeaponVar.zoom_time_in )
	if ( isOut ) {
		zoomTime = weapon.GetWeaponSettingFloat( eWeaponVar.zoom_time_out )
		zoomFrac = 1 - zoomFrac
	}

	//	Play sound
	#if SERVER
	EmitSoundOnEntityExceptToPlayerWithSeek( weapon, owner, sfxSpinSeek, zoomFrac * zoomTimeIn )
	#else
	StopSoundOnEntity( owner, ADS_IN_SFX )
	StopSoundOnEntity( owner, ADS_OUT_SFX )

	float sfxTime = GetSoundDuration( sfxADS )
	EmitSoundOnEntityWithSeek( owner, sfxADS, zoomFrac * sfxTime )
	EmitSoundOnEntityWithSeek( owner, sfxSpinSeek, zoomFrac * zoomTime )
	#endif
}

bool function IsPredatorCannonActive( entity owner, bool reqZoom = true ) {
	if ( owner.IsNPC() )
		return owner.GetActiveWeapon().GetWeaponClassName() == "mp_titanweapon_predator_cannon"

	if ( reqZoom && owner.GetZoomFrac() != 1.0 )
		return false

	if ( owner.GetViewModelEntity().GetModelName() != $"models/weapons/titan_predator/atpov_titan_predator.mdl" )
		return false

	if ( owner.PlayerMelee_IsAttackActive() )
		return false

	return true
}

#if SERVER
void function PredatorSpinup( entity owner, entity weapon ) {
	if ( !IsAlive(owner) )
		return



	EmitSoundOnEntity( owner, "Weapon_Predator_MotorLoop_3P" )
	EmitSoundOnEntity( owner, "Weapon_Predator_Windup_3P" )

	float npc_pre_fire_delay = expect float( weapon.GetWeaponInfoFileKeyField( "npc_pre_fire_delay" ) )

	OnThreadEnd( function() : ( weapon, owner ) {
			if ( !IsValid(owner) ) return
			// foreach ( elem in owner.e.fxArray )
			// {
			// 	if ( IsValid( elem ) )
			// 		elem.Destroy()
			// }
			// owner.e.fxArray = []

			StopSoundOnEntity( owner, "Weapon_Predator_Windup_3P" )
			StopSoundOnEntity( owner, "Weapon_Predator_MotorLoop_3P" )
	}	)

	weapon.EndSignal( "OnDestroy" )
	owner.EndSignal( "OnDeath" )
	owner.EndSignal( "OnDestroy" )

	wait npc_pre_fire_delay

	// owner.e.fxArray.append( PlayLoopFXOnEntity( $"P_wpn_lasercannon_aim_short", owner, "PROPGUN", null, null, ENTITY_VISIBLE_TO_EVERYONE ) )

	float npc_pre_fire_delay_interval = expect float( weapon.GetWeaponInfoFileKeyField( "npc_pre_fire_delay_interval" ) )

	wait npc_pre_fire_delay_interval
}

void function PredatorCannon_DamagedTarget( entity target, var damageInfo ) {
	if ( !IsValid( target ) )
		return

	if ( !target.IsTitan() )
		return

	if ( !( DamageInfo_GetCustomDamageType( damageInfo ) & DF_SKIPS_DOOMED_STATE ) )
		return

	if ( GetDoomedState( target ) )
		DamageInfo_SetDamage( damageInfo, target.GetHealth() + 1 )
}
#endif