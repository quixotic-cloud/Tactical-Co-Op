//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_InteractOpenClose extends X2Action;

//Cached info for performing the action and the target object
//*************************************
var XComInteractiveLevelActor   Interactor;
var name                        InteractSocketName;
var TTile                       InteractTile;
var AnimNodeSequence			PlayingSequence;
//*************************************

function Init(const out VisualizationTrack InTrack)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit UnitState;

	super.Init(InTrack);
	AbilityContext = XComGameStateContext_Ability(StateChangeContext);

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	`assert(UnitState != none);

	Interactor = XComInteractiveLevelActor(InTrack.TrackActor);

	GetInteractionInformation();
}

private function GetInteractionInformation()
{
	local array<XComInteractPoint> InteractionPoints;
	local XComWorldData World;
	local Vector UnitLocation;
	

	World = class'XComWorldData'.static.GetWorldData();

	UnitLocation = UnitPawn.Location;
	UnitLocation.Z = World.GetFloorZForPosition(UnitLocation) + class'XComWorldData'.const.Cover_BufferDistance;
	World.GetInteractionPoints(UnitLocation, 8.0f, 90.0f, InteractionPoints);
	if (InteractionPoints.Length > 0)
	{		
		InteractSocketName = InteractionPoints[0].InteractSocketName;
	}
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
Begin:
	// Play animations
	FinishAnim(Interactor.PlayAnimations(Unit, InteractSocketName));

	Interactor.AnimNode.SetActiveChild(0, 1.0f);
	
	Sleep(1.0f * GetDelayModifier());

	CompleteAction();
}

defaultproperties
{
}

