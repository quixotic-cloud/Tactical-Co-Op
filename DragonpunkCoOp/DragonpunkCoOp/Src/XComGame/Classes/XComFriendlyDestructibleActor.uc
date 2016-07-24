/**
 * XComFriendlyDestructibleActor.uc
 *
 * For destructible actors that are of value to the player.
 *
 * Copyright 2012 Firaxis
 * @owner jshopf
 */

class XComFriendlyDestructibleActor extends XComDestructibleActor
	placeable
	native(Destruction);

cpptext
{
	virtual void ApplyAOEDamageMaterial();
	virtual bool ShouldAOEDamageProcFriendlyFirePopup() { return true; }
}

defaultproperties
{
}