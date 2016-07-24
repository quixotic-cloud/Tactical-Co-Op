//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_BreakInteractActor extends X2Action;

//Cached info for performing the action and the target object
//*************************************
var XComInteractiveLevelActor   Interactor;
var name                        InteractSocketName;
var TTile                       InteractTile;
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

	//Typically, this action will be on the track of the door/etc that's getting hit.
	//We want the UnitPawn that's doing the breaking in that case.
	if (UnitPawn == None)
	{
		Unit = XGUnit(UnitState.GetVisualizer());
		UnitPawn = Unit.GetPawn();
	}

	GetInteractionInformation();
}

private function GetInteractionInformation()
{
	local array<XComInteractPoint> InteractionPoints;
	local XComWorldData World;
	local Vector UnitLocation;	
	local Vector SocketLocation;

	World = class'XComWorldData'.static.GetWorldData();

	UnitLocation = UnitPawn.Location;
	UnitLocation.Z = World.GetFloorZForPosition(UnitLocation) + class'XComWorldData'.const.Cover_BufferDistance;
	World.GetInteractionPoints(UnitLocation, 8.0f, 90.0f, InteractionPoints);
	if (InteractionPoints.Length > 0)
	{		
		InteractSocketName = InteractionPoints[0].InteractSocketName;
	}
	else
	{
		Interactor.GetClosestSocket(UnitLocation, InteractSocketName, SocketLocation);
	}
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
Begin:
	// Play animations
	Interactor.BreakInteractActor(InteractSocketName);

	Sleep(0.1f); // force a tick, to allow blends to start

	// Wait for interaction to finish
	while(Interactor.IsAnimating())
	{
		if((Interactor.IsInState('_Destroyed') || Interactor.IsInState('_Destroyed')))
		{
			break; //Exit if this actor is destroyed. There should be no anim to play in this case
		}
		Sleep(0.1f);
	}
	
	CompleteAction();
}

defaultproperties
{
	bCauseTimeDilationWhenInterrupting = true
}

