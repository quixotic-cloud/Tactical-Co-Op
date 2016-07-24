//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_SuperpositionUnitGo extends X2Action;

var vector  Destination;
var bool    bWaitForSpawnedUnitStay;

var private bool bAbilityEffectReceived;

//Cached info for the unit performing the action
//*************************************
var protected CustomAnimParams AnimParams;

var private X2Camera_LookAtActorTimed LookAtCam;
var private Actor FOWViewer;					// The current FOW Viewer actor
//*************************************

function bool CheckInterrupted()
{
	return false;
}

function bool IsTimedOut()
{
	return false;
}

function HandleTrackMessage()
{
	bAbilityEffectReceived = true;
}

function ResetTimeDilation()
{
	local X2VisualizerInterface VisualizerInterface;

	VisualizerInterface = X2VisualizerInterface(Track.TrackActor);
	if(VisualizerInterface != None)
	{
		VisualizerInterface.SetTimeDilation(1.0f);
	}
}

simulated state Executing
{
	private function RequestLookAtCamera()
	{
		LookAtCam = new class'X2Camera_LookAtActorTimed';
		LookAtCam.ActorToFollow = UnitPawn;
		LookAtCam.UseTether = false;
		`CAMERASTACK.AddCamera(LookAtCam);

		FOWViewer = `XWORLD.CreateFOWViewer(Unit.GetLocation(), 3 * class'XComWorldData'.const.WORLD_StepSize);
	}

	private function ClearLookAtCamera()
	{
		`CAMERASTACK.RemoveCamera(LookAtCam);
		LookAtCam = None;

		if (FOWViewer != None)
		{
			`XWORLD.DestroyFOWViewer(FOWViewer);
			FOWViewer = None;
		}
	}

Begin:
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	ResetTimeDilation(); //Ensure Time Dilation is full speed

	// Play the teleport start animation
	AnimParams.AnimName = 'HL_CloneGo';
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

	if( bWaitForSpawnedUnitStay )
	{
		// Wait for notification from the Staying (spawned) Unit
		while(!bAbilityEffectReceived && !IsTimedOut())
		{
			sleep(0.0f);
		}
	}

	// Move the pawn to the end position
	Destination.Z = `XWORLD.GetFloorZForPosition(Destination, true) + UnitPawn.CollisionHeight + class'XComWorldData'.const.Cover_BufferDistance;	
	UnitPawn.SetLocation(Destination);		

	if( !bNewUnitSelected )
	{
		RequestLookAtCamera();
		while( LookAtCam != None && !LookAtCam.HasArrived && LookAtCam.IsLookAtValid() )
		{
			Sleep(0.0);
		}
	}

	// Play the teleport stop animation
	AnimParams.AnimName = 'HL_TeleportStop';
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

	ClearLookAtCamera();

	UnitPawn.EnableRMA(false, false);
	UnitPawn.EnableRMAInteractPhysics(false);
	UnitPawn.SnapToGround();

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

