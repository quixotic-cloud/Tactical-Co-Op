/**
 * Damageable interface provides functions for objects which can take damage.
 */

interface Damageable dependson(X2TacticalGameRulesetDataStructures)
	native(Core);


/**
 * TakeEffectDamage
 * Take the specified amount of damage.
 */
function TakeEffectDamage(const X2Effect DmgEffect, const int DamageAmount, const int MitigationAmount, const int ShredAmount, const out EffectAppliedData EffectData, XComGameState NewGameState,
						  optional bool bForceBleedOut = false, optional bool bAllowBleedout = true, optional bool bIgnoreShields = false, optional array<Name> DamageTypes);

function TakeDamage( XComGameState NewGameState, const int DamageAmount, const int MitigationAmount, const int ShredAmount, optional EffectAppliedData EffectData,
	optional Object CauseOfDeath, optional StateObjectReference DamageSource, optional bool bExplosiveDamage = false, optional array<name> DamageTypes,
	optional bool bForceBleedOut = false, optional bool bAllowBleedout = true, optional bool bIgnoreShields = false );

/**
 * GetArmorMitigation
 * Get the armor value protecting this Damageable.
 */
function float GetArmorMitigation(const out ArmorMitigationResults Armor);

/**
 * IsImmuneToDamage
 * Returns true if the object is immune to this damage type.
 */
function bool IsImmuneToDamage(name DamageType);

/**
 * GetRupturedValue
 * Returns amount of rupture this object has (increases damage against it).
 */
function int GetRupturedValue();

/**
 * AddRupturedValue
 * Increase the object's rupture value
 */
function AddRupturedValue(const int Rupture);

/**
 * AddShreddedValue
 * Increase the object's Shredded value
 */
function AddShreddedValue(const int Shred);