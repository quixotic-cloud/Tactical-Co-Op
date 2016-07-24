class X2AbilityArmorHitRolls extends Object 
	native(Core)
	config(GameCore);

var config int HIGH_COVER_ARMOR_CHANCE;     //  DEPRECATED - not used anywhere
var config int LOW_COVER_ARMOR_CHANCE;      //  DEPRECATED - not used anywhere

//  This no longer rolls for armor, as armor is always available.
//  The incoming Armor parameter is not inspected.
//  Results will fill in all bonus armor effects, as well as set the TotalMitigation field to all armor the unit has.
//  Note: Shred value is not factored in here
static event RollArmorMitigation(const out ArmorMitigationResults Armor, out ArmorMitigationResults Results, XComGameState_Unit UnitState)
{
	local XComGameStateHistory History;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local X2Effect_BonusArmor ArmorEffect;

	`log("  " $ GetFuncName() $ "  ",,'XCom_HitRolls');

	Results.TotalMitigation = UnitState.GetCurrentStat(eStat_ArmorMitigation);
	if (UnitState.AffectedByEffects.Length > 0)
	{
		History = `XCOMHISTORY;
		foreach UnitState.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			ArmorEffect = X2Effect_BonusArmor(EffectState.GetX2Effect());
			if (ArmorEffect != none)
			{
				Results.BonusArmorEffects.AddItem(EffectRef);
				Results.TotalMitigation += ArmorEffect.GetArmorMitigation(EffectState, UnitState);
				`log("BonusArmorEffect" @ ArmorEffect.GetArmorName(EffectState, UnitState), true, 'XCom_HitRolls');
			}
		}
	}
	`log("  Total Mitigation:" @ Results.TotalMitigation, true, 'XCom_HitRolls');
}

static function bool DoRoll(int Chance, out int RandRoll)
{
	RandRoll = `SYNC_RAND_STATIC(100);
	return RandRoll <= Chance;
}