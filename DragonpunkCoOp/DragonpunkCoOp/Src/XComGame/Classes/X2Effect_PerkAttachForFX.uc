class X2Effect_PerkAttachForFX extends X2Effect_Persistent;

defaultproperties
{
	EffectName="PerkAttachForFX"

	iNumTurns=1
	bInfiniteDuration=false
	bRemoveWhenSourceDies=false
	bIgnorePlayerCheckOnTick=false
	WatchRule=eGameRule_PlayerTurnBegin
}