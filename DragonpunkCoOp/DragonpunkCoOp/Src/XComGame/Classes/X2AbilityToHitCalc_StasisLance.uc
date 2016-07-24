class X2AbilityToHitCalc_StasisLance extends X2AbilityToHitCalc config(GameCore);

var localized string BaseChance;
var localized string HealthModifier;

var config int BASE_CHANCE;         //  base chance before hp adjustments
var config int HP_THRESHOLD;       //  hp amount where things are easier while <= this value
var config int CLAMPED_MIN;         //  absolute minimum hit chance
var config int CLAMPED_MAX;         //  absolute maximum hit chance

function RollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, out AbilityResultContext ResultContext)
{
	local int Chance, RandRoll;
	local XComGameState_Unit TargetUnit;
	local XComGameStateHistory History;

	ResultContext.HitResult = eHit_Miss;
	Chance = GetHitChance(kAbility, kTarget, true);

	if (`CHEATMGR != none)
	{
		if (`CHEATMGR.bDeadEye)
		{
			`log("DeadEye cheat forcing a hit.", true, 'XCom_HitRolls');
			ResultContext.HitResult = eHit_Success;
			return;
		}
		if (`CHEATMGR.bNoLuck)
		{
			`log("NoLuck cheat forcing a miss.", true, 'XCom_HitRolls');
			ResultContext.HitResult = eHit_Miss;			
			return;
		}
	}

	//  @TODO gameplay: guarantee success on Easy/Normal against Advent Captains if a Cyberus brain has not been retrieved
	if( kAbility.GetMyTemplateName() == 'SKULLJACKAbility' )
	{
		History = `XCOMHISTORY;
		TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));
		if( TargetUnit.GetMyTemplate().CharacterGroupName == 'AdventCaptain' || 
			TargetUnit.GetMyTemplate().CharacterGroupName == 'Cyberus' )
		{
			Chance = 100;
		}
	}

	if (Chance > 0)
	{
		RandRoll = `SYNC_RAND_TYPED(100, ESyncRandType_Generic);
		`log("StasisLance hit chance" @ Chance @ "rolled" @ RandRoll $ "...", true, 'XCom_HitRolls');
		if (RandRoll <= Chance)
		{
			ResultContext.HitResult = eHit_Success;
			`log("      Success!!!", true, 'XCom_HitRolls');
		}
		else
		{
			`log("      Failed.", true, 'XCom_HitRolls');
		}
	}
	else
	{
		`log("StasisLance hit chance was 0.", true, 'XCom_HitRolls');
	}
}

protected function int GetHitChance(XComGameState_Ability kAbility, AvailableTarget kTarget, optional bool bDebugLog=false)
{
	local XComGameState_Unit TargetUnit;
	local XComGameStateHistory History;
	//local int TargetHP, Chance, TotalMod;
	//local float fChance;
	local ShotBreakdown EmptyShotBreakdown;

	History = `XCOMHISTORY;
	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));
	m_ShotBreakdown = EmptyShotBreakdown;

	if (TargetUnit != none && !`XENGINE.IsMultiplayerGame())
	{
		AddModifier(default.BASE_CHANCE, class'XLocalizedData'.default.BaseChance);


		//TargetHP = TargetUnit.GetCurrentStat(eStat_HP);
		//if (TargetHP <= default.HP_THRESHOLD)
		//{
		//	Chance = default.BASE_CHANCE + (default.HP_THRESHOLD - TargetHP) * 10;
		//}
		//else
		//{
		//	fChance = float(default.BASE_CHANCE) / 100.0f;
		//	fChance = fChance ** (TargetHP - default.HP_THRESHOLD + 1);
		//	fChance *= 100.0f;
		//	Chance = int(fChance);
		//}
		//Chance = Clamp(Chance, default.CLAMPED_MIN, default.CLAMPED_MAX);

		//if (Chance > default.BASE_CHANCE)
		//	TotalMod = Chance - default.BASE_CHANCE;
		//else
		//	TotalMod = (default.BASE_CHANCE - Chance) * -1;

		//AddModifier(TotalMod, default.HealthModifier);
		FinalizeHitChance();
	}
	
	return m_ShotBreakdown.FinalHitChance;
}