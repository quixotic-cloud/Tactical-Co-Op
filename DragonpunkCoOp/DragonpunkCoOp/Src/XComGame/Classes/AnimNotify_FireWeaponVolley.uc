//---------------------------------------------------------------------------------------
//  FILE:    AnimNotify_FireWeaponVolley.uc
//  AUTHOR:  Ryan McFall  --  9/17/2014
//  PURPOSE: This notify allows for the creation of "volleys" of projectiles. The weapon
//           equipped on the unit is what determines the X2UnifiedProjectile archetype(s)
//           as well as sound, effects, etc. involved with the firing of the weapon.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class AnimNotify_FireWeaponVolley extends AnimNotify
	native(Animation);

var() int   NumShots <ToolTip="Used to indicate some number of projectiles fired by this volley.">;
var() float ShotInterval <ToolTip="If NumShots is greater than 1, indicates a time to wait between shots">;
var() bool  bCustom <ToolTip="If TRUE, then this notify will fire the projectile element matching CustomID in the weapon's X2UnifiedProjectile archetype">;
var() int   CustomID <EditCondition=bCustom|ToolTip="Used if bCustom is true to select which projectile element to use in the firing weapon's projectile archetype">;
var() bool	bPerkVolley;
var() string PerkAbilityName<EditCondition=bPerkVolley>;
var() bool	bCosmeticVolley <ToolTip="If TRUE, this means that this projectile volley is just for show and is not part of game play. Used for matinee or death anims with weapons fire.">;

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return "Fire Weapon Volley"; }
	virtual FColor GetEditorColor() { return FColor(255,150,150); }
}

function native NotifyUnit( XComUnitPawnNativeBase XComPawn );

defaultproperties
{
	NumShots=1
	ShotInterval=0.1
	bCustom=false
	CustomID=-1
	bPerkVolley=false
	PerkAbilityName=""
}
