class X2Effect_MarkValidActivationTiles extends X2Effect;

var name AbilityToMark;
var bool OnlyUseTargetLocation;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Ability AbilityState, SourceAbilityState;
	local StateObjectReference AbilityRef;
	local XComGameState_Unit UnitState;
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	local vector TargetLoc;
	local TTile TargetTile;
//	local TTile DebugTile;        //  used for debug visualization

	UnitState = XComGameState_Unit(kNewTargetState);
	`assert(UnitState != none);
	AbilityRef = UnitState.FindAbility(AbilityToMark);
	if (AbilityRef.ObjectID == 0)
	{
		`RedScreen("MarkValidActivationTiles wanted to find ability '" $ AbilityToMark $ "' but the unit doesn't have it." @ UnitState.ToString());
		return;
	}
	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	if (AbilityContext == none)
	{
		`RedScreen("MarkValidActiationTiles is only valid from an ability context." @ NewGameState.ToString());
		return;
	}
	AbilityState = XComGameState_Ability(NewGameState.GetGameStateForObjectID(AbilityRef.ObjectID));
	if (AbilityState == none)
	{
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityRef.ObjectID));
		if (AbilityState == none)
		{
			`RedScreen("Ability reference found for" @ AbilityToMark @ "Object ID" @ AbilityRef.ObjectID @ "but could not find the state object!" @ UnitState.ToString());
			return;
		}
		AbilityState = XComGameState_Ability(NewGameState.CreateStateObject(AbilityState.Class, AbilityState.ObjectID));
		NewGameState.AddStateObject(AbilityState);
	}
	SourceAbilityState = XComGameState_Ability(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	if (SourceAbilityState == none)
		SourceAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	if (SourceAbilityState == none)
	{
		`RedScreen("Unable to get ability state for executed ability in context." @ NewGameState.ToString());
		return;
	}
	AbilityTemplate = SourceAbilityState.GetMyTemplate();
	if (AbilityTemplate.AbilityMultiTargetStyle == none && !OnlyUseTargetLocation)
	{
		`RedScreen("No multi target style exists for ability template" @ AbilityTemplate.DataName);
		return;
	}
	if (AbilityContext.InputContext.TargetLocations.Length > 0)
	{
		TargetLoc = AbilityContext.InputContext.TargetLocations[0];
	}
	else
	{
		`RedScreen("Cannot handle getting tile locations without a TargetLocation in the input context. Code me?");
		return;
	}

	AbilityState.ValidActivationTiles.Length = 0;
	if (!OnlyUseTargetLocation)
	{
		AbilityTemplate.AbilityMultiTargetStyle.GetValidTilesForLocation(SourceAbilityState, TargetLoc, AbilityState.ValidActivationTiles);
	}
	else
	{
		TargetTile = `XWORLD.GetTileCoordinatesFromPosition(TargetLoc);
		AbilityState.ValidActivationTiles.AddItem(TargetTile);
	}

	//  Debug visualization for marked tiles.
	/*foreach AbilityState.ValidActivationTiles(DebugTile)
	{
		TargetLoc = `XWORLD.GetPositionFromTileCoordinates(DebugTile);
		`SHAPEMGR.DrawSphere(TargetLoc, vect(15,15,15), MakeLinearColor(0,0,1,1), true);
	}*/
}

defaultproperties
{
	OnlyUseTargetLocation=false
}