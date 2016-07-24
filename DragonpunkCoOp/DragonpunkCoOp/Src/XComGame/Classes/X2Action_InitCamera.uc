//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_InitCamera extends X2Action;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
}

function bool CheckInterrupted()
{
	return false;
}

static function InitCamera()
{
	local XComTacticalController TacticalController;
	local XComPresentationLayer Pres;
	local XComCamera CurrentCamera;
	local XComGameState_Unit UnitState;
	local XGUnit FirstUnitVisualizer;
	local XComGameStateHistory History;
	local XGPlayer PlayerVisualizer;
	local X2TacticalGameRuleset TacticalRuleset;

	local XComCamera Cam;
	local X2Camera_LookAtActorTimed LookAtActorCamera;

	TacticalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
	Pres = XComPresentationLayer(TacticalController.Pres);
	History = `XCOMHISTORY;
	TacticalRuleset = `TACTICALRULES;

	if( TacticalController != none && Pres != none )
	{
		CurrentCamera = Pres.GetCamera();
		CurrentCamera.StartTactical();	

		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			PlayerVisualizer = XGPlayer(History.GetVisualizer(UnitState.ControllingPlayer.ObjectID));
			if( !PlayerVisualizer.IsRemote() )
			{
				break;
			}
		}

		FirstUnitVisualizer = XGUnit(History.GetVisualizer(UnitState.ObjectID));
		if( FirstUnitVisualizer != none && (!TacticalRuleset.bLoadingSavedGame || `REPLAY.bInReplay))
		{	
			Cam = XComCamera(TacticalController.PlayerCamera);
			if(Cam == none) return;

			LookAtActorCamera = new class'X2Camera_LookAtActorTimed';
			LookAtActorCamera.ActorToFollow = FirstUnitVisualizer;
			LookAtActorCamera.LookAtDuration = 3;
			Cam.CameraStack.AddCamera(LookAtActorCamera);

			// also snap the 3d cursor to the unit so that it will have the correct floor
			// etc. info for the unit that will become active once the loading screen drops.
			TacticalController.GetCursor().MoveToUnit(FirstUnitVisualizer.GetPawn());

			// Force an update here because OrientCameraTowardsObjective() is going to get 
			// Camera location/rotation data which otherwise won't be correct
			Cam.CameraStack.UpdateCameras(0.0f);

			SetInitialCameraOrientation();
		}
	}
}

static private function SetInitialCameraOrientation()
{
	local XComParcelManager ParcelManager;
	local XComGameState_BattleData BattleData;
	local PlotDefinition Plot;

	ParcelManager = `PARCELMGR;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	Plot = ParcelManager.GetPlotDefinition(BattleData.MapData.PlotMapName, "");

	if (Plot.InitialCameraFacingDegrees == 1)
	{
		OrientCameraTowardsObjective();
	}
	else
	{
		`CAMERASTACK.YawCameras(Plot.InitialCameraFacingDegrees);
	}
}

static private function OrientCameraTowardsObjective()
{
	local Vector ObjectiveLoc, FromCameraToObj;
	local TPOV POV;
	local Rotator Rot;
	local float YawDiff;
	local int Num90DegRots;

	if (`TACTICALMISSIONMGR.GetObjectivesCenterPoint(ObjectiveLoc))
	{
		POV = `CAMERASTACK.GetCameraLocationAndOrientation();

		FromCameraToObj = ObjectiveLoc - POV.Location;
		FromCameraToObj.Z = 0;

		Rot = Rotator(FromCameraToObj);

		YawDiff = Rot.Yaw - POV.Rotation.Yaw;

		// Add 45 Degrees so we can get the closest angle or our objective in 90 degree increments
		if (YawDiff > 0)
			YawDiff += 45.0f * DegToUnrRot; 
		else YawDiff -= 45.0f * DegToUnrRot;

		Num90DegRots = YawDiff / (90.0f * DegToUnrRot);

		`CAMERASTACK.YawCameras(Num90DegRots * 90);
	}
}

simulated state Executing
{
Begin:
	if( !bNewUnitSelected )
	{
		InitCamera();
	}

	CompleteAction();
}

DefaultProperties
{
}
