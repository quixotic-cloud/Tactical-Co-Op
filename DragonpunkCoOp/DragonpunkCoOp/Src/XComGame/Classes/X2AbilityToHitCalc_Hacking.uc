class X2AbilityToHitCalc_Hacking extends X2AbilityToHitCalc config(GameCore);

var config int SKULLJACK_HACKING_BONUS;

function RollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, out AbilityResultContext ResultContext)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Hacker;
	local XComGameState_BaseObject TargetState;

	History = `XCOMHISTORY;
	Hacker = XComGameState_Unit(History.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));
	TargetState = History.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID);

	if (Hacker != None && TargetState != None)
	{
		ResultContext.StatContestResult = `SYNC_RAND(100);
		ResultContext.HitResult = eHit_Success;

		`COMBATLOG(Hacker.GetName(eNameType_RankFull) @ "uses hack. Rolls:" @ ResultContext.StatContestResult $ "%" @ ResultContext.HitResult);
	}
	else
	{
		`COMBATLOG("Hack failed due to no Hacker or no Target!");
		ResultContext.HitResult = eHit_Miss;
	}
}


static function int GetHackAttackForUnit(XComGameState_Unit Hacker, XComGameState_Ability AbilityState)
{
	local XComGameState_Item SourceWeapon;
	local X2GremlinTemplate GremlinTemplate;
	local int HackAttack;

	HackAttack = Hacker.GetCurrentStat(eStat_Hacking);

	// when the skullmining tech is researched, carrying the skulljack confers a bonus to hacking
	if( Hacker.HasItemOfTemplateType('SKULLJACK') && `XCOMHQ.IsTechResearched('Skullmining') )
	{
		HackAttack += default.SKULLJACK_HACKING_BONUS;
	}

	SourceWeapon = AbilityState.GetSourceWeapon();
	if (SourceWeapon != None)
	{
		GremlinTemplate = X2GremlinTemplate(SourceWeapon.GetMyTemplate());
		if (GremlinTemplate != None)
			HackAttack += GremlinTemplate.HackingAttemptBonus;
	}

	return HackAttack;
}

static function int GetHackDefenseForTarget(XComGameState_BaseObject TargetState)
{
	local XComGameState_InteractiveObject ObjectState;
	local XComGameState_Unit UnitState;

	ObjectState = XComGameState_InteractiveObject(TargetState);
	if (ObjectState != None)
	{
		return ObjectState.LockStrength;
	}
	UnitState = XComGameState_Unit(TargetState);
	if (UnitState != None)
	{
		return UnitState.GetCurrentStat(eStat_HackDefense);
	}

	return -1;
}

//  Hacking hit chance is displayed in a special UI and does not  use this functionality. -jbouscher
protected function int GetHitChance(XComGameState_Ability kAbility, AvailableTarget kTarget, optional bool bDebugLog=false)
{
	m_ShotBreakdown.HideShotBreakdown = true;
	return 0;
}