class X2Effect_ReturnFire extends X2Effect_CoveringFire;

DefaultProperties
{
	EffectName = "ReturnFire"
	DuplicateResponse = eDupe_Ignore
	AbilityToActivate = "PistolReturnFire"
	GrantActionPoint = "returnfire"
	MaxPointsPerTurn = 1
	bDirectAttackOnly = true
	bPreEmptiveFire = false
	bOnlyDuringEnemyTurn = true
}