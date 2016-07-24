class X2Effect_AidProtocol extends X2Effect_ModifyStats config (GameData_SoldierSkills);

var config int BASE_DEFENSE;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;

	// Register for the required events
	// When the Gremlin is recalled to its owner, if aid protocol is in effect, override and return to the unit receiving aid
	// (Priority 49, so this happens after the regular ItemRecalled)
	EventMgr.RegisterForEvent(EffectObj, 'ItemRecalled', class'X2Effect_AidProtocol'.static.OnItemRecalled, ELD_OnStateSubmitted, 49);
}

//Must be static. Will be associated, in the event manager, with a XComGameState_Effect, rather than this object.
static function EventListenerReturn OnItemRecalled(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateHistory History;

	local XComGameState_Unit OwnerUnitState;
	local XComGameState_Ability RecallingAbility;
	local XComGameState_Item RecalledItem;
	local XComGameState_Effect EffectState;

	local XComGameState_Unit CosmeticUnitState;
	local XComGameState_Unit TargetUnitState;

	local XComGameState NewGameState;
	local XComGameState_Item NewRecalledItem;

	local XGUnit Visualizer;
	local vector MoveToLoc;
	local int i;

	local XComGameState_BaseObject ExistingOldUnitState;
	local XComGameState_BaseObject ExistingNewUnitState;

	local bool bSkippingMoveBackToSpecialist;

	History = `XCOMHISTORY;


	OwnerUnitState = XComGameState_Unit(EventSource);
	RecallingAbility = XComGameState_Ability(EventData);
	if (OwnerUnitState == None || RecallingAbility == None)
		return ELR_NoInterrupt;

	RecalledItem = XComGameState_Item(GameState.GetGameStateForObjectID(RecallingAbility.SourceWeapon.ObjectID));
	if (RecalledItem == None)
		return ELR_NoInterrupt;

	CosmeticUnitState = XComGameState_Unit(GameState.GetGameStateForObjectID(RecalledItem.CosmeticUnitRef.ObjectID));
	if (CosmeticUnitState == None)
		return ELR_NoInterrupt;

	//There really shouldn't be more than one unit getting AidProtocol from this single Gremlin. If there is, then the intended target should be any one of them.
	for (i = 0; i < OwnerUnitState.AppliedEffectNames.Length; i++)
	{
		if (OwnerUnitState.AppliedEffectNames[i] == 'AidProtocol')
		{
			EffectState = XComGameState_Effect(GameState.GetGameStateForObjectID(OwnerUnitState.AppliedEffects[i].ObjectID));
			if (EffectState == None)
				EffectState = XComGameState_Effect(History.GetGameStateForObjectID(OwnerUnitState.AppliedEffects[i].ObjectID));

			if (EffectState != None && !EffectState.bRemoved)
				break;
		}
	}
	if (EffectState == None || EffectState.bRemoved)
		return ELR_NoInterrupt;

	TargetUnitState = XComGameState_Unit(GameState.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnitState == None)
		TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnitState == None)
		return ELR_NoInterrupt;


	//The Gremlin was likely moved back to the specialist when the Gremlin's other ability finished. Don't visualize that.
	History.GetCurrentAndPreviousGameStatesForObjectID(RecalledItem.CosmeticUnitRef.ObjectID, ExistingOldUnitState, ExistingNewUnitState);
	if (XComGameState_Unit(ExistingOldUnitState).TileLocation == CosmeticUnitState.TileLocation && XComGameState_Unit(ExistingNewUnitState).TileLocation != CosmeticUnitState.TileLocation)
	{
		if (ExistingNewUnitState.GetParentGameState().GetNumGameStateObjects() == 1)
		{
			`XCOMVISUALIZATIONMGR.SkipVisualization(ExistingNewUnitState.GetParentGameState().HistoryIndex);

			//It may be the case that we can't safely skip this visualization - the Gremlin can do environmental damage (!?!?) and we don't want to miss that.
			//So, keep track of where the Gremlin needs to start moving from, when it goes back to the aid-protocol target.
			bSkippingMoveBackToSpecialist = true;
			
		}
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Aid Protocol: Gremlin sent back to target unit");
	//Attach the Gremlin back to the unit with Aid Protocol.
	NewRecalledItem = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', RecalledItem.ObjectID));
	NewRecalledItem.AttachedUnitRef.ObjectID = TargetUnitState.ObjectID;
	NewGameState.AddStateObject(NewRecalledItem);
	`GAMERULES.SubmitGameState(NewGameState);

	//Move the Gremlin back to the aid protocol target
	if(bSkippingMoveBackToSpecialist) //Gremlin may be moving to the specialist and then to the aid-protocol target, or may go directly to the aid-protocol target.
		XComGameState_Unit(ExistingNewUnitState).SetVisibilityLocation(CosmeticUnitState.TileLocation); //This influences where the pathing starts.

	CosmeticUnitState = XComGameState_Unit(ExistingNewUnitState);
	Visualizer = XGUnit(History.GetVisualizer(CosmeticUnitState.ObjectID));
	MoveToLoc = `XWORLD.GetPositionFromTileCoordinates(TargetUnitState.TileLocation);
	Visualizer.MoveToLocation(MoveToLoc, CosmeticUnitState);

	return ELR_NoInterrupt;
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Item SourceItem;
	local X2GremlinTemplate GremlinTemplate;
	local StatChange Change;

	Change.StatType = eStat_Defense;
	Change.StatAmount = default.BASE_DEFENSE;

	SourceItem = XComGameState_Item(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));
	if (SourceItem == none)
		SourceItem = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));

	if (SourceItem != none)
	{
		GremlinTemplate = X2GremlinTemplate(SourceItem.GetMyTemplate());
		if (GremlinTemplate != none)
		{
			Change.StatAmount += GremlinTemplate.AidProtocolBonus;
		}
	}
	NewEffectState.StatChanges.AddItem(Change);
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Ability AbilityState;
	local XComGameState_Item ItemState;

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	if( !bCleansed )     //  if it was cleansed, then it was pre-emptively removed by telling the gremlin to do something else. (not really going to happen w/o something like Inspire adding an AP)
	{
		AbilityState = XComGameState_Ability(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		if (AbilityState == none)
			AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));

		//Recall the Gremlin if it hasn't been recalled already (for example, by the target's death)
		ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));
		if (ItemState != None && ItemState.AttachedUnitRef.ObjectID != ItemState.OwnerStateObject.ObjectID)
			`XEVENTMGR.TriggerEvent('ItemRecalled', AbilityState, AbilityState, NewGameState);
	}
}