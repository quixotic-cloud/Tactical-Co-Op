//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_Loot extends X2Action;

//Cached info for performing the action
//*************************************
var CustomAnimParams            Params;
var bool                        bLootingComplete;

// the socket on the receiving pawn that will accept each loot item
var Name						LootReceptionSocket;

// The length of time it will take each loot item to be slurped up
var float						LootSlurpTime;

var float						LootStartTimeSeconds;
var Vector						LootStartLoc;

var array<Actor>				LootVisActors;
var array<string>				LootVisActorItemPickupStrings;
var int							LootableObjectID;

var Lootable					OldLootableObjectState;
var Lootable					NewLootableObjectState;

var XComGameState_Unit			OldUnitState;
var AnimNodeSequence			PlayingSequence;

//*************************************

static function AddToVisualizationTrackIfLooted(Lootable LootableObject, XComGameStateContext Context, out VisualizationTrack InTrack)
{
	local XComGameStateHistory History;
	local X2Action_Loot LootAction;
	local XComGameState_BaseObject LootableObjectState;
	local Lootable PreviousLootable;
	
	if(LootableObject != none && !LootableObject.HasLoot())
	{
		History = `XCOMHISTORY;
		LootableObjectState = XComGameState_BaseObject(LootableObject);
		PreviousLootable = Lootable(History.GetGameStateForObjectID(LootableObjectState.ObjectID,, Context.AssociatedState.HistoryIndex - 1));

		if(PreviousLootable.HasLoot())
		{
			LootAction = X2Action_Loot(AddToVisualizationTrack(InTrack, Context));
			LootAction.LootableObjectID = LootableObjectState.ObjectID;
		}
	}
}

function Init(const out VisualizationTrack InTrack)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int OldHistoryIndex, NewHistoryIndex, LootObjectID;
	local array<StateObjectReference> LootItemRefs;
	local Actor LootVisActor;
	local XGParamTag kTag;
	local XComGameState_Item ItemState;
	local XComPresentationLayer Presentation;

	super.Init(InTrack);
	
	Presentation = `PRES;
	History = `XCOMHISTORY;
	bLootingComplete = false;

	UnitState = XComGameState_Unit(InTrack.StateObject_NewState);
	`assert(UnitState != none);

	NewHistoryIndex = InTrack.StateObject_NewState.GetParentGameState().HistoryIndex;
	OldHistoryIndex = NewHistoryIndex - 1;
	OldUnitState = XComGameState_Unit(InTrack.StateObject_OldState);

	OldLootableObjectState = Lootable(History.GetGameStateForObjectID(LootableObjectID, , OldHistoryIndex));
	NewLootableObjectState = Lootable(History.GetGameStateForObjectID(LootableObjectID, , NewHistoryIndex));

	if( OldLootableObjectState != None )
	{
		kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		LootItemRefs = OldLootableObjectState.GetAvailableLoot();

		while( LootItemRefs.Length > 0 )
		{
			LootObjectID = LootItemRefs[LootItemRefs.Length - 1].ObjectID;
			LootVisActor = History.GetVisualizer(LootObjectID);
			if( LootVisActor != None )
			{
				LootVisActors.AddItem(LootVisActor);

				ItemState = XComGameState_Item(History.GetGameStateForObjectID(LootObjectID, , OldHistoryIndex));
				kTag.StrValue0 = ItemState.GetMyTemplate().GetItemFriendlyName();
				LootVisActorItemPickupStrings.AddItem(`XEXPAND.ExpandString(Presentation.m_strTimedLoot));

				// have to clear the visualizer from the map, since it is about to be destroyed
				History.SetVisualizer(LootObjectID, None);
			}
			LootItemRefs.Remove(LootItemRefs.Length - 1, 1);
		}
	}
}

function bool IsTimedOut()
{
	return false;
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	function BeginSlurp()
	{
		if( LootVisActors.Length > 0 )
		{
			LootStartTimeSeconds = WorldInfo.TimeSeconds;
			LootStartLoc = LootVisActors[0].Location;
			if( LootVisActors[0] != None )
			{
				LootVisActors[0].SetPhysics(PHYS_Interpolating);
			}
		}
	}

	function UpdateSlurp()
	{
		local float TimeSinceStart;
		local float Alpha;
		local Vector TargetLocation;

		TimeSinceStart = WorldInfo.TimeSeconds - LootStartTimeSeconds;

		if( TimeSinceStart >= LootSlurpTime )
		{
			`PRES.Notify(LootVisActorItemPickupStrings[0]);
			LootVisActors[0].Destroy();
			LootVisActors.Remove(0, 1);
			LootVisActorItemPickupStrings.Remove(0, 1);
			BeginSlurp();
		}
		else
		{
			Alpha = (TimeSinceStart * TimeSinceStart) / (LootSlurpTime * LootSlurpTime);
			UnitPawn.Mesh.GetSocketWorldLocationAndRotation(LootReceptionSocket, TargetLocation);
			LootVisActors[0].SetLocation(VLerp(LootStartLoc, TargetLocation, Alpha));
		}
	}

Begin:
	// highlight loot sparkles for the old state
	OldLootableObjectState.UpdateLootSparklesEnabled(true);

	// Start looting anim
	Params.AnimName = 'HL_LootBodyStart';
	Params.PlayRate = GetNonCriticalAnimationSpeed();
	PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
	if( Track.TrackActor.CustomTimeDilation < 1.0 )
	{
		Sleep(PlayingSequence.AnimSeq.SequenceLength * PlayingSequence.Rate * Track.TrackActor.CustomTimeDilation);
	}
	else
	{
		FinishAnim(PlayingSequence);
	}

	// Loop while the UI is displayed
	Params.AnimName = 'HL_LootLoop';
	Params.Looping = true;
	UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);

	// show the UI, and wait for it to finish before playing the slurp
	`PRES.UIInventoryTactical(OldUnitState, OldLootableObjectState, OnUIInventoryTacticalClosed);
	while( !bLootingComplete )
	{
		Sleep(0.1f);
	}

	// clear loot sparkles based on the new state
	NewLootableObjectState.UpdateLootSparklesEnabled(false);


	BeginSlurp();
	while( LootVisActors.Length > 0 )
	{
		UpdateSlurp();
		Sleep(0.001f);
	}

	Params.AnimName = 'HL_LootStop';
	Params.Looping = false;
	Params.PlayRate = GetNonCriticalAnimationSpeed();
	PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
	if( Track.TrackActor.CustomTimeDilation < 1.0 )
	{
		Sleep(PlayingSequence.AnimSeq.SequenceLength * PlayingSequence.Rate * Track.TrackActor.CustomTimeDilation);
	}
	else
	{
		FinishAnim(PlayingSequence);
	}

	Unit.UnitSpeak('LootCaptured');

	CompleteAction();
}

event bool BlocksAbilityActivation()
{
	return true;
}

simulated function OnUIInventoryTacticalClosed()
{
	bLootingComplete = true;
}

defaultproperties
{
	LootReceptionSocket = "L_Hand"
	LootSlurpTime = 0.25
	LootStartTimeSeconds = -1.0
}

