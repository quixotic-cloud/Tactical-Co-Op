//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_HiddenMovement extends X2Action
	native(Core)
	config(GameCore);

//Cached info for performing the action
//*************************************
var XGUnit					HeardUnit;
//*************************************

var const config string NoiseIndicatorMeshName; // mesh to use when visualizing the noise direction
var const config int MaxHearingRangeTiles; // maximum range at which an xcom soldier can "hear" an alien unit
var const config int MaxNoiseIndicatorSizeInTiles; // maximum size the indicator mesh can reach, in tiles
var const config int TurnsUntilIndicator; // how many turns do we need to not see aliens before the indicator shows

var private Vector AveragePodLocation; // the centerpoint of the pods that we are sensing "hidden movement" for
var private X2Camera_LookAtActor TargetingCamera;
var private AnimNodeSequence PlayingAnim;
var private int HeardEnemyObjectID;	//Stores the object ID for the leader of the nearest enemy pod generating this alert

var private StaticMeshComponent NoiseIndicatorMesh; // mesh component that draws the noise direction visualizer

// From the provided arrays, human that is closest to the aliens
// and under the maximum hearing distance, if any. Then find any pods that he can hear
static private native function bool GetClosestHumanAndPodLocations(out XComGameState_Unit OutClosestHuman,
																   out array<vector> OutPodLocations,
																   out StateObjectReference OutHeardPodLeader);

static function bool AddHiddenMovementActionToBlock(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local VisualizationTrack BuildTrack;
	local X2Action_HiddenMovement Action;
	local X2Action_CameraLookAt CameraAction;
	local XComGameState_Unit ClosestHumanUnit;
	local StateObjectReference OutHeardPodLeader;
	local array<vector> PodLocationstoHear;
	local vector PodLocation;

	if(class'XComGameState_Cheats'.static.GetCheatsObject(GameState.HistoryIndex).SuppressHiddenMovementIndicator)
	{
		return false;
	}

	// if we can find an appropriate human and pods to hear, then add a hear sound action for them
	if(GetClosestHumanAndPodLocations(ClosestHumanUnit, PodLocationstoHear, OutHeardPodLeader))
	{
		// Add a camera to center on the unit
		BuildTrack.StateObject_OldState = ClosestHumanUnit;
		BuildTrack.StateObject_NewState = ClosestHumanUnit;
		BuildTrack.TrackActor = ClosestHumanUnit.GetVisualizer();

		CameraAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTrack(BuildTrack, GameState.GetContext()));
		CameraAction.LookAtActor = BuildTrack.TrackActor;
		CameraAction.UseTether = false; // need to fully center on him so the sound indicator doesn't overlap him
		CameraAction.BlockUntilActorOnScreen = true;

		// Add the action for the hidden movement
		Action = X2Action_HiddenMovement(class'X2Action_HiddenMovement'.static.AddToVisualizationTrack(BuildTrack, GameState.GetContext()));

		// get the average of all pod locations
		foreach PodLocationstoHear(PodLocation)
		{
			Action.AveragePodLocation += PodLocation;
		}

		Action.AveragePodLocation /= PodLocationstoHear.Length;
		Action.HeardEnemyObjectID = OutHeardPodLeader.ObjectID;
	
		VisualizationTracks.AddItem(BuildTrack);
		return true;
	}

	return false;
}

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	if(HeardEnemyObjectID > 0)
	{
		HeardUnit = XGUnit(`XCOMHISTORY.GetVisualizer(HeardEnemyObjectID));
	}
}

function PlayAnimation()
{
	local CustomAnimParams AnimParams;

	AnimParams.AnimName = 'HL_SignalReactToNoise';
	AnimParams.Looping = false;
	if( Unit.GetPawn().GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName) )
	{
		PlayingAnim = Unit.GetPawn().GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
	}
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	function ShowNoiseIndicator()
	{
		local StaticMesh StaticMeshData;
		local vector ToEnemy;
		local Rotator MeshOrientation;
		local float EffectiveScalingDistance;
		local vector Scale;

		// load the static mesh
		StaticMeshData = StaticMesh(DynamicLoadObject(NoiseIndicatorMeshName, class'StaticMesh'));

		// move the indicator to the unit and then orient it to the pod locations center
		NoiseIndicatorMesh.SetStaticMesh(StaticMeshData);
		NoiseIndicatorMesh.SetHidden(false);
		NoiseIndicatorMesh.SetTranslation(Unit.GetLocation());

		// orient toward the enemy
		ToEnemy = AveragePodLocation - Unit.Location;
		MeshOrientation = Rotator(ToEnemy);
		MeshOrientation.Roll = 0;
		NoiseIndicatorMesh.SetRotation(MeshOrientation);

		// set the scale of the indicator
		EffectiveScalingDistance = FMin(VSize(ToEnemy), MaxNoiseIndicatorSizeInTiles * class'XComWorldData'.const.WORLD_StepSize);
		Scale.X = EffectiveScalingDistance / (NoiseIndicatorMesh.Bounds.BoxExtent.X * 2); // BoxExtent.x since we are oriented along the x-axis
		Scale.Y = Scale.X;
		Scale.Z = 1;
		NoiseIndicatorMesh.SetScale3D(Scale);
	}

Begin:
	if( !bNewUnitSelected )
	{
		TargetingCamera = new class'X2Camera_LookAtActor';
		TargetingCamera.ActorToFollow = Unit;
		`CAMERASTACK.AddCamera(TargetingCamera);
	}

	//Make the alien sounds if available
	if(HeardUnit != none)
	{
		HeardUnit.UnitSpeak('HiddenMovementVox');
	}

	// Dramatic pause / give the camera a moment to settle
	Sleep(1.5 * GetDelayModifier());

	ShowNoiseIndicator();	
		
	//Have the x-com unit start their speech
	//Note: these two cues are both used for this situation, so select one randomly.
	if (`SYNC_RAND(100)<50)
	{
		Unit.UnitSpeak('TargetHeard');
	}
	else
	{
		Unit.UnitSpeak('AlienMoving');
	}

	// play the animation and wait for it to finish
	PlayAnimation();

	if( PlayingAnim != None )
	{
		FinishAnim(PlayingAnim);

		// keep the camera looking this way for a few moments
		Sleep(1.0 * GetDelayModifier());
	}

	NoiseIndicatorMesh.SetHidden(true);

	if( TargetingCamera != None )
	{
		`CAMERASTACK.RemoveCamera(TargetingCamera);
		TargetingCamera = None;
	}

	CompleteAction();
}

event HandleNewUnitSelection()
{
	if( TargetingCamera != None )
	{
		`CAMERASTACK.RemoveCamera(TargetingCamera);
		TargetingCamera = None;
	}
}


defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=NoiseIndicatorMeshObject
		StaticMesh=none
		HiddenGame=true
		bOwnerNoSee=FALSE
		CastShadow=FALSE
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
		TranslucencySortPriority=1000
		bTranslucentIgnoreFOW=true
		AbsoluteTranslation=true
		AbsoluteRotation=true
		Scale=1.0
	End Object
	NoiseIndicatorMesh=NoiseIndicatorMeshObject
	Components.Add(NoiseIndicatorMeshObject)
}

