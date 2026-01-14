untyped

global function MpTitanweaponMeteor_Init

global function OnWeaponActivate_Meteor
global function OnWeaponDeactivate_Meteor

global function OnProjectileCollision_Meteor

global function OnWeaponPrimaryAttack_Meteor
#if SERVER
global function OnWeaponNpcPrimaryAttack_Meteor

global function CreateThermiteTrail
global function CreateThermiteTrailOnMovingGeo
#global function CreatePhysicsThermiteTrail

global function Scorch_SelfDamageReduction
global function GetMeteorRadiusDamage

global const PLAYER_METEOR_DAMAGE_TICK = 100.0
global const PLAYER_METEOR_DAMAGE_TICK_PILOT = 20.0

global const NPC_METEOR_DAMAGE_TICK = 100.0
global const NPC_METEOR_DAMAGE_TICK_PILOT = 20.0

global struct MeteorRadiusDamage {
	float pilotDamage
	float heavyArmorDamage
}
#endif // #if SERVER

#if CLIENT
const INDICATOR_IMAGE = $"ui/menu/common/locked_icon"
#endif

global const SP_THERMITE_DURATION_SCALE = 1.25


const METEOR_FX_CHARGED = $"P_wpn_meteor_exp_amp"
global const METEOR_FX_TRAIL = $"P_wpn_meteor_exp_trail"
global const METEOR_FX_BASE = $"P_wpn_meteor_exp"

const FLAME_WALL_SPLIT = false
const METEOR_LIFE_TIME = 1.2
global const METEOR_THERMITE_DAMAGE_RADIUS_DEF = 45
const FLAME_WALL_DAMAGE_RADIUS_DEF = 60

const METEOR_SHELL_EJECT		= $"models/Weapons/shellejects/shelleject_40mm.mdl"
const METEOR_FX_LOOP		= "Weapon_Sidwinder_Projectile"

const int METEOR_DAMAGE_FLAGS = damageTypes.gibBullet | DF_IMPACT | DF_EXPLOSION

function MpTitanweaponMeteor_Init() {
	PrecacheParticleSystem( $"wpn_mflash_40mm_smoke_side_FP" )
	PrecacheParticleSystem( $"wpn_mflash_40mm_smoke_side" )
	PrecacheParticleSystem( $"P_scope_glint" )

	PrecacheParticleSystem( $"P_team_jet_hover_HLD" )
	PrecacheParticleSystem( $"P_enemy_jet_hover_HLD" )

	PrecacheModel( $"models/dev/empty_physics.mdl" )

	PrecacheParticleSystem( METEOR_FX_TRAIL )
	PrecacheParticleSystem( METEOR_FX_CHARGED )

	#if SERVER
	AddDamageCallbackSourceID( eDamageSourceId.mp_titanweapon_meteor_thermite, MeteorThermite_DamagedTarget )

	PrecacheParticleSystem( THERMITE_GRENADE_FX )
	PrecacheModel( METEOR_SHELL_EJECT )

	FlagInit( "SP_MeteorIncreasedDuration" )
	FlagSet( "SP_MeteorIncreasedDuration" )
	#endif

	#if CLIENT
	PrecacheMaterial( INDICATOR_IMAGE )
	RegisterSignal( "NewOwner" )
	#endif

	MpTitanweaponFlameWall_Init()
}

//	     :::       ::: ::::::::::     :::     :::::::::   ::::::::  ::::    :::
//	    :+:       :+: :+:          :+: :+:   :+:    :+: :+:    :+: :+:+:   :+:
//	   +:+       +:+ +:+         +:+   +:+  +:+    +:+ +:+    +:+ :+:+:+  +:+
//	  +#+  +:+  +#+ +#++:++#   +#++:++#++: +#++:++#+  +#+    +:+ +#+ +:+ +#+
//	 +#+ +#+#+ +#+ +#+        +#+     +#+ +#+        +#+    +#+ +#+  +#+#+#
//	 #+#+# #+#+#  #+#        #+#     #+# #+#        #+#    #+# #+#   #+#+#
//	 ###   ###   ########## ###     ### ###         ########  ###    ####

void function OnWeaponActivate_Meteor( entity weapon ) {  }
void function OnWeaponDeactivate_Meteor( entity weapon ) {  }

var function OnWeaponPrimaryAttack_Meteor( entity weapon, WeaponPrimaryAttackParams attackParams ) {
	weapon.EmitWeaponNpcSound( LOUD_WEAPON_AI_SOUND_RADIUS_MP, 0.2 )
	return PlayerOrNPCFire_Meteor( attackParams, true, weapon )
}

var function OnWeaponNpcPrimaryAttack_Meteor( entity weapon, WeaponPrimaryAttackParams attackParams ) {
	weapon.EmitWeaponNpcSound( LOUD_WEAPON_AI_SOUND_RADIUS_MP, 0.2 )
	return PlayerOrNPCFire_Meteor( attackParams, false, weapon )
}

int function PlayerOrNPCFire_Meteor( WeaponPrimaryAttackParams attackParams, bool playerFired, entity weapon ) {
	//entity owner = weapon.GetWeaponOwner()
	bool shouldCreateProjectile = false
	if ( IsServer() || weapon.ShouldPredictProjectiles() )
		shouldCreateProjectile = true
	#if CLIENT
		if ( !playerFired )
			shouldCreateProjectile = false
	#endif

	if ( shouldCreateProjectile ) {
		float speed	= 1.0 // 2200.0

 		//TODO:: Calculate better attackParams.dir if auto-titan using mortarShots
		entity bolt = weapon.FireWeaponBolt( attackParams.pos, attackParams.dir, speed, METEOR_DAMAGE_FLAGS, METEOR_DAMAGE_FLAGS, playerFired , 0 )
		if ( bolt != null )
			EmitSoundOnEntity( bolt, "weapon_thermitelauncher_projectile_3p" )
	}

	return 1
}

void function OnProjectileCollision_Meteor(
	entity projectile,
	vector pos, vector normal,
	entity hitEnt, int hitbox,
	bool isCritical
) {
	#if SERVER
	if ( projectile.proj.projectileBounceCount > 0 )
		return

	projectile.proj.projectileBounceCount++

	entity owner = projectile.GetOwner()
	if ( !IsValid( owner ) )
		return

	if ( IsValid( owner ) )
		thread Proto_MeteorCreatesThermite( projectile, hitEnt )
	#endif
}

//	       :::::::::: :::    ::: ::::    :::  :::::::: ::::::::::: ::::::::::: ::::::::  ::::    :::  ::::::::
//	      :+:        :+:    :+: :+:+:   :+: :+:    :+:    :+:         :+:    :+:    :+: :+:+:   :+: :+:    :+:
//	     +:+        +:+    +:+ :+:+:+  +:+ +:+           +:+         +:+    +:+    +:+ :+:+:+  +:+ +:+
//	    :#::+::#   +#+    +:+ +#+ +:+ +#+ +#+           +#+         +#+    +#+    +:+ +#+ +:+ +#+ +#++:++#++
//	   +#+        +#+    +#+ +#+  +#+#+# +#+           +#+         +#+    +#+    +#+ +#+  +#+#+#        +#+
//	  #+#        #+#    #+# #+#   #+#+# #+#    #+#    #+#         #+#    #+#    #+# #+#   #+#+# #+#    #+#
//	 ###         ########  ###    ####  ########     ###     ########### ########  ###    ####  ########

//		Fire creation
int ANGLE_RANGE = 180
function Proto_MeteorCreatesThermite( entity projectile, entity hitEnt = null ) {
	//	Get owner
	entity owner = projectile.GetOwner()
	Assert( IsValid( owner ) )

	//	Set fire speed from parent
	vector projVel = projectile.GetVelocity()
	float speed = min( Length( projVel ), 2500 )

	float speedScale = 0.25
	if ( IsSingleplayer() ) {
		speedScale = 0.35
	}

	projVel = Normalize( projVel ) * speed * speedScale

	vector normal = <0,0,1>

	vector origin = projectile.GetOrigin()
	vector angles = VectorToAngles( normal )

	//DebugDrawLine( origin, origin + projVel * 10, 255, 0, 0, true, 5.0 )
	//EmitSoundAtPosition( owner.GetTeam(), origin, "Explo_MeteorGun_Impact_3P" )

	//	Get fire information
	float thermiteLifetimeMin = 2.0
	float thermiteLifetimeMax = 2.5
	if ( IsSingleplayer() ) {
		if ( owner.IsPlayer() || Flag( "SP_MeteorIncreasedDuration" ) ) {
			thermiteLifetimeMin *= SP_THERMITE_DURATION_SCALE
			thermiteLifetimeMax *= SP_THERMITE_DURATION_SCALE
		}
	}

	//	Create inflictor
	entity inflictor = CreateOncePerTickDamageInflictorHelper( thermiteLifetimeMax )

	//	Get fire counts
	int fireCount = 4
	float fireSpeed = 50

	array<string> mods = projectile.ProjectileGetMods()
	if ( mods.contains( "pas_scorch_weapon" ) ) {
		fireCount = 8
		fireSpeed = 200
	}

	//	Spawn fires
	float fireVel = projVel
	float fireTime = thermiteLifetimeMax
	for (int i = 0; i < fireCount+1; i++ ) {
		//	Spawn fire first, then change variables
		entity fire = CreatePhysicsThermiteTrail(
			origin, fireVel, fireTime
			owner, inflictor, projectile,
		)

		fire.SetAngles( fireVel )

		//	First ent stick
		if ( i == 0 && hitEnt != null && hitEnt.IsWorld() )
			fire.StopPhysics()

		//	Random angles/velocity
		angles = Vector(
			RandomFloatRange(-ANGLE_RANGE, ANGLE_RANGE),
			RandomFloatRange(-ANGLE_RANGE, ANGLE_RANGE),
			RandomFloatRange(-ANGLE_RANGE, ANGLE_RANGE)
		)

		vector fwd = AnglesToForward( trailAngles )
		vector up = AnglesToUp( trailAngles )
		fireVel = (fwd + up) * fireSpeed + projVel
	}
}


entity function CreatePhysicsThermiteTrail(
	vector origin, vector velocity, float killDelay,
	entity owner, entity inflictor, entity projectile,
	//	Actually utilizing these nice defaults
	asset overrideFX = METEOR_FX_TRAIL,
	int damageSourceId = eDamageSourceId.mp_titanweapon_meteor_thermite
) {
	//	Sanity checks
	Assert( IsValid( owner ) )

	//		Physics-enabled props
	//	Create
	entity fire = CreateEntity( "prop_physics" )
	fire.SetOwner( owner )

	//	Render
	fire.SetValueForModelKey( $"models/dev/empty_physics.mdl" )
	fire.kv.fadedist = 2000
	fire.kv.renderamt = 255
	fire.kv.rendercolor = "255 255 255"
	fire.Hide()

	fire.kv.minhealthdmg = 9999
	fire.kv.nodamageforces = 1
	fire.kv.inertiaScale = 1.0

	//	Physics
	fire.kv.CollisionGroup = TRACE_COLLISION_GROUP_DEBRIS
	fire.kv.spawnflags = 4 /* SF_PHYSPROP_DEBRIS */

	fire.SetOrigin( origin )
	fire.SetVelocity( velocity )

	DispatchSpawn( fire )

	//	PFX
	entity fx = StartParticleEffectOnEntity_ReturnEntity( fire,
		GetParticleSystemIndex( overrideFX ),
		FX_PATTACH_POINT_FOLLOW_NOROTATE,
		fire.LookupAttachment( "origin" )
	)

	fx.SetOwner( owner )
	fire.e.fxArray.append( fx )
	AddActiveThermiteBurn( fx )

	//	Kill delay
	if( killDelay > 0 ) { EntFireByHandle( fire, "Kill", "", killDelay, null, null ) }

	//	AI
	AI_CreateDangerousArea( fire, projectile, METEOR_THERMITE_DAMAGE_RADIUS_DEF, TEAM_INVALID, true, false )

	//	Damage
	thread PROTO_PhysicsThermiteCausesDamage( fire, inflictor, damageSourceId )

	return fire
}


#if SERVER
//		Damage handling
//	Physics variant
void function PROTO_PhysicsThermiteCausesDamage(
	entity trail, entity inflictor,
	int damageSourceId = eDamageSourceId.mp_titanweapon_meteor_thermite
) {
	entity owner = trail.GetOwner()
	Assert( IsValid( owner ) )

	trail.EndSignal( "OnDestroy" )
	owner.EndSignal( "OnDestroy" )

	MeteorRadiusDamage meteorRadiusDamage = GetMeteorRadiusDamage( owner )
	float METEOR_DAMAGE_TICK_PILOT = meteorRadiusDamage.pilotDamage
	float METEOR_DAMAGE_TICK = meteorRadiusDamage.heavyArmorDamage

	array<entity> fxArray = trail.e.fxArray

	OnThreadEnd( function() : ( fxArray ) {
			foreach ( fx in fxArray ) {
				if ( IsValid( fx ) )
					EffectStop( fx )
			}
	}	)

	wait 0.2 // thermite falls and ignites

	vector currOrigin = trail.GetOrigin()
	vector lastOrigin = currOrigin
	for ( ;; ) {
		currOrigin = trail.GetOrigin()
		vector moveVec = lastOrigin - currOrigin

		// spread the circle while the particles are moving fast, could replace with trace
		float moveDist = Length( moveVec )
		float dist = max( METEOR_THERMITE_DAMAGE_RADIUS_DEF, moveDist )

		RadiusDamage(
			trail.GetOrigin(),									// origin
			owner,												// owner
			inflictor,		 									// inflictor
			METEOR_DAMAGE_TICK_PILOT,							// pilot damage
			METEOR_DAMAGE_TICK,									// heavy armor damage
			dist,												// inner radius
			dist,												// outer radius
			SF_ENVEXPLOSION_NO_NPC_SOUND_EVENT,					// explosion flags
			0, 													// distanceFromAttacker
			0, 													// explosionForce
			0,													// damage flags
			damageSourceId 										// damage source id
		)

		WaitFrame()
	}
}

//	Static variant
void function PROTO_ThermiteCausesDamage(
	entity trail, entity owner, entity inflictor,
	int damageSourceId = eDamageSourceId.mp_titanweapon_meteor_thermite
) {
	Assert( IsValid( owner ) )

	trail.EndSignal( "OnDestroy" )
	owner.EndSignal( "OnDestroy" )
	inflictor.EndSignal( "OnDestroy" )

	MeteorRadiusDamage meteorRadiusDamage = GetMeteorRadiusDamage( owner )
	float METEOR_DAMAGE_TICK_PILOT = meteorRadiusDamage.pilotDamage
	float METEOR_DAMAGE_TICK = meteorRadiusDamage.heavyArmorDamage

	OnThreadEnd( function() : ( trail ) {
			EffectStop( trail )
	} )

	float radius = METEOR_THERMITE_DAMAGE_RADIUS_DEF
	if ( damageSourceId == eDamageSourceId.mp_titanweapon_flame_wall )
		radius = FLAME_WALL_DAMAGE_RADIUS_DEF

	for ( ;; ) {
		RadiusDamage(
			trail.GetOrigin(),									// origin
			owner,												// owner
			inflictor,		 									// inflictor
			METEOR_DAMAGE_TICK_PILOT,							// pilot damage
			METEOR_DAMAGE_TICK,									// heavy armor damage
			radius,												// inner radius
			radius,												// outer radius
			SF_ENVEXPLOSION_NO_NPC_SOUND_EVENT,					// explosion flags
			0, 													// distanceFromAttacker
			0, 													// explosionForce
			DF_EXPLOSION,										// damage flags
			damageSourceId										// damage source id
		)

		WaitFrame()
	}
}

void function MeteorThermite_DamagedTarget( entity target, var damageInfo ) {
	//	Sanity checks
	if( !IsValid( target ) )
		return

	//
	Thermite_DamagePlayerOrNPCSounds( target )
	Scorch_SelfDamageReduction( target, damageInfo )

	entity attacker = DamageInfo_GetAttacker( damageInfo )
	if ( !IsValid( attacker ) || attacker.GetTeam() == target.GetTeam() )
		return

	array<entity> weapons = attacker.GetMainWeapons()
	if ( weapons.len() > 0 ) {
		if ( weapons[0].HasMod( "fd_fire_damage_upgrade" )  )
			DamageInfo_ScaleDamage( damageInfo, FD_FIRE_DAMAGE_SCALE )
		if ( weapons[0].HasMod( "fd_hot_streak" ) )
			UpdateScorchHotStreakCoreMeter( attacker, DamageInfo_GetDamage( damageInfo ) )
	}
}

//	This one has been modified
const float SELFDAMAGE_SCALE_SP = 0.00
const float SELFDAMAGE_SCALE_DEF = 0.00
const float SELFDAMAGE_SCALE_MOD = 0.00

const float MOD_SPEED_BOOST = 0.20
const float MOD_DAMAGE_REDUCTION = 0.15
const float MOD_EFFECT_TIME = 0.1
const float MOD_EFFECT_FADE_TIME = 0.0

void function Scorch_SelfDamageReduction( entity target, var damageInfo ) {
	//	Sanity checks
	if ( !IsAlive( target ) )
		return

	entity attacker = DamageInfo_GetAttacker( damageInfo )
	if ( !IsValid( attacker ) )
		return

	if ( target != attacker )
		return

	entity soul = attacker.GetTitanSoul()
	if ( !IsValid( soul ) )
		return

	//	Choose damage scale
	float scale = SELFDAMAGE_SCALE_DEF
	if( IsSingleplayer() ) {
		scale = SELFDAMAGE_SCALE_SP
	}

	//	Thermite effect
	if( SoulHasPassive( soul, ePassives.PAS_SCORCH_SELFDMG ) ) {
		scale = SELFDAMAGE_SCALE_MOD

		//	Add effects
		int speedStatusID = StatusEffect_AddTimed( soul, eStatusEffect.speed_boost, MOD_SPEED_BOOST, MOD_EFFECT_TIME, MOD_EFFECT_FADE_TIME )
		int damageStatusID = StatusEffect_AddTimed( soul, eStatusEffect.damage_reduction, MOD_DAMAGE_REDUCTION, MOD_EFFECT_TIME, MOD_EFFECT_FADE_TIME )
	}

	//	Scale damage
	DamageInfo_ScaleDamage( damageInfo, scale )
}


/*
void function MeteorAirburst( entity bolt ) {
	bolt.EndSignal( "OnDestroy" )
	bolt.GetOwner().EndSignal( "OnDestroy" )
	wait METEOR_LIFE_TIME
	thread Proto_MeteorCreatesThermite( bolt )
	bolt.Destroy()
} //*/


MeteorRadiusDamage function GetMeteorRadiusDamage( entity owner ) {
	MeteorRadiusDamage meteorRadiusDamage
	if ( owner.IsNPC() ) {
		meteorRadiusDamage.pilotDamage = NPC_METEOR_DAMAGE_TICK_PILOT
		meteorRadiusDamage.heavyArmorDamage = NPC_METEOR_DAMAGE_TICK
	} else {
		meteorRadiusDamage.pilotDamage = PLAYER_METEOR_DAMAGE_TICK_PILOT
		meteorRadiusDamage.heavyArmorDamage = PLAYER_METEOR_DAMAGE_TICK
	}

	return meteorRadiusDamage
}



//	Trail creation
entity function CreateThermiteTrail(
	vector origin, vector angles,
	entity owner, entity inflictor,
	float killDelay,
	asset overrideFX = METEOR_FX_TRAIL,
	int damageSourceId = eDamageSourceId.mp_titanweapon_meteor_thermite
) {
	Assert( IsValid( owner ) )

	entity particle = StartParticleEffectInWorld_ReturnEntity( GetParticleSystemIndex( overrideFX ), origin, angles )
	particle.SetOwner( owner )

	AddActiveThermiteBurn( particle )

	if ( killDelay > 0.0 )
		EntFireByHandle( particle, "Kill", "", killDelay, null, null )

	thread PROTO_ThermiteCausesDamage( particle, owner, inflictor, damageSourceId )

	return particle
}

entity function CreateThermiteTrailOnMovingGeo(
	entity parent, vector origin, vector angles,
	entity owner, entity inflictor,
	float killDelay,
	asset overrideFX = METEOR_FX_TRAIL,
	int damageSourceId = eDamageSourceId.mp_titanweapon_meteor_thermite
) {
	Assert( IsValid( owner ) )

	entity mover = CreateScriptMover( origin, angles )
	mover.SetParent( parent, "", true, 0 )

	int attachIdx 		= mover.LookupAttachment( "REF" )
	entity particle 	= StartParticleEffectOnEntityWithPos_ReturnEntity(	//	Used to be StartParticleEffectOnEntity_ReturnEntity
		parent,
		GetParticleSystemIndex( overrideFX ),
		FX_PATTACH_CUSTOMORIGIN_FOLLOW,
		-1,
		mover.GetLocalOrigin(), angles
	)

	particle.SetOwner( owner )
	mover.SetOwner( owner )

	AddActiveThermiteBurn( particle )

	if ( killDelay > 0.0 ) {
		EntFireByHandle( mover, "Kill", "", killDelay, null, null )
		EntFireByHandle( particle, "Kill", "", killDelay, null, null )
	}

	thread PROTO_ThermiteCausesDamage( particle, owner, inflictor, damageSourceId )

	return particle
}

#endif // #if SERVER



