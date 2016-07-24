//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_UnBurrow extends X2Action
	config(GameCore);

var private CustomAnimParams Params;
var private TTile CurrentTile;
var private bool bIsOwnerLocalPlayer;
var private X2Camera_LookAtActorTimed LookAtCam;
var private Actor FOWViewer;					// The current FOW Viewer actor
var private const config float LookAtUnburrowDurationSec; // in seconds

function Init(const out VisualizationTrack InTrack)
{
	local XComGameState_Unit UnitState;
	local Vector TileWorldPos;
	
	super.Init(InTrack);

	Params.AnimName = 'NO_BurrowStop';

	//grab the unit's gamestate
	UnitState = XComGameState_Unit(InTrack.StateObject_NewState);
	CurrentTile = UnitState.TileLocation;
	TileWorldPos = `XWORLD.GetPositionFromTileCoordinates(CurrentTile);
	
	//get the right Z position
	TileWorldPos.Z = UnitPawn.GetDesiredZForLocation(TileWorldPos);

	//we need to set the location of the unitpawn because it's not necessarily the same position as it was 
	//before, actual case being the Chryssalid.
	UnitPawn.SetLocation(TileWorldPos);
	
	bIsOwnerLocalPlayer = Unit.GetPlayer() == XComTacticalController(`BATTLE.GetALocalPlayerController()).m_XGPlayer;
}

function bool CheckInterrupted()
{
	return false;
}

simulated state Executing
{
	private function RequestLookAtCamera()
	{
		FOWViewer = `XWORLD.CreateFOWViewer(Unit.GetLocation(), class'XComWorldData'.const.WORLD_StepSize * 3);
		LookAtCam = new class'X2Camera_LookAtActorTimed';
		LookAtCam.ActorToFollow = UnitPawn;
		LookAtCam.LookAtDuration = LookAtUnburrowDurationSec;
		LookAtCam.UseTether = false;
		`CAMERASTACK.AddCamera(LookAtCam);
	}

	private function ClearLookAtCamera()
	{
		if( LookAtCam != None )
		{
			`CAMERASTACK.RemoveCamera(LookAtCam);
			LookAtCam = None;
		}

		if( FOWViewer != None )
		{
			`XWORLD.DestroyFOWViewer(FOWViewer);
			FOWViewer = None;
		}
	}
Begin:
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	if( !bIsOwnerLocalPlayer )
	{
		Unit.m_bForceHidden = false;
		`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.VisualizerUpdateVisibility(Unit, CurrentTile);
	}

	if( Unit.IsAI() || Unit.IsVisible() )
	{
		Unit.SetForceVisibility(eForceVisible);

		if( !bNewUnitSelected )
		{
			RequestLookAtCamera();
		}
	}

	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));

	ClearLookAtCamera();
	Unit.SetForceVisibility(eForceNone);

	// Reset the obstruction shader to default
	UnitPawn.bUseObstructionShader = true;
	UnitPawn.UpdateAuxParameterState(false);

	CompleteAction();
}

event HandleNewUnitSelection()
{
	if( LookAtCam != None )
	{
		`CAMERASTACK.RemoveCamera(LookAtCam);
		LookAtCam = None;
	}
}

defaultproperties
{
	bCauseTimeDilationWhenInterrupting = true
}