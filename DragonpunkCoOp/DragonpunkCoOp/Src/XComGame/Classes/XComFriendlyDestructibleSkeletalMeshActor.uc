/**
 * XComFriendlyDestructibleSkeletalMeshActor.uc
 *
 * For destructible actors that are of value to the player.
 *
 * Copyright 2012 Firaxis
 * @owner jshopf
 */

class XComFriendlyDestructibleSkeletalMeshActor extends XComDestructibleActor
	placeable
	native(Destruction);

cpptext
{
	virtual UMaterialInterface* GetDefaultAOEMaterial(AXComTacticalGRI* Tactical);
	virtual bool ShouldAOEDamageProcFriendlyFirePopup() { return true; }
}

defaultproperties
{
}