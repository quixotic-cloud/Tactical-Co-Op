//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComCamState_HQ_BaseRoomView extends XComCamState_HQ_BaseView;

//var transient vector					TargetLocation;
var name CamName;

function InitRoomView( PlayerController ForPlayer, name CameraName )
{
	local float fSlaveTime;
	local bool bMoviePlaying;
	local Actor TmpActor;
	local array<Actor> Actors;
	local XComBlueprint Blueprint;
	local XComHeadquartersCamera HQCam;
	local XGStrategy GameCore;

	if(CameraName == 'Base')
	{
		ViewDistance = 500.0f;
	}
	else
	{
		ViewDistance = 0.0f;
	}

	InitCameraState( ForPlayer );

	GameCore = `GAME;
	if(GameCore != none && GameCore.GetGeoscape().m_kBase != none) //If the game core isn't ready, it means we are in the strategy debug menu
	{
		`EARTH.Show(false);

		CamName = CameraName;
		foreach WorldInfo.AllActors(class'CameraActor', CamActor)
		{
			if(CamActor != none && CamActor.Tag == CameraName)
				break;
		}

		// Check blueprints if we didn't find a camera actor
		if(CamActor == None)
		{
			foreach WorldInfo.AllActors(class'XComBlueprint', Blueprint)
			{
				if(Blueprint != none && Blueprint.Tag == CameraName)
				{
					Blueprint.GetLoadedLevelActors(Actors);
					foreach Actors(TmpActor)
					{
						CamActor = CameraActor(TmpActor);
						if(CamActor != none)
							break;
					}
				}
			}
		}

		if(CameraName == 'MissionControl')
		{
			bMoviePlaying = `XENGINE.IsAnyMoviePlaying();			
		}

		if(CamActor != none)
		{
			// When going to mission control from the squad selection screen, a Bink plays. Need to hang onto the slave location longer
			HQCam = XComHeadquartersCamera(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController.PlayerCamera);
			if(HQCam != none && HQCam.CurrentRoom == 'AwayTeam')
			{
				fSlaveTime = 15.0f;
			}
			else
			{
				fSlaveTime = `HQINTERPTIME * 2.0f;
			}

			`XENGINE.AddStreamingTextureSlaveLocation(CamActor.Location, CamActor.Rotation, fSlaveTime, bMoviePlaying);
		}	
	}
}

function GetView( float DeltaTime, out vector out_Focus, out rotator out_Rotation, out float out_ViewDistance, out float out_FOV, out PostProcessSettings out_PPSettings, out float out_PPOverrideAlpha  )
{
	local vector AdjustedCamActorLoc;

	if (CamActor == none)
	{
		foreach WorldInfo.AllActors(class'CameraActor', CamActor)
		{
			if (CamActor.Tag == CamName)
				break;
		}
	}

	if (CamActor == none)
		return;

	// A camera actor is used to determine where the camera should go.. since we are
	//  determining the y coordinate procedurally, we need to override the cam actor location.
	//  Basically 'Base' view needs to match the FreeMovement view as it is just the initial view
	//  of the base.
	
	AdjustedCamActorLoc = CamActor.Location;

	/*
	if( CamActor.Tag == 'Base' )
	{
		AdjustedCamActorLoc.Y = GetPlatformViewDistance(); 
	}*/


	out_ViewDistance = ViewDistance;
	out_Focus = AdjustedCamActorLoc;
	out_Rotation = CamActor.Rotation;
	out_FOV = CamActor.FOVAngle;
	PCOwner.SetRotation( out_Rotation );

	out_PPSettings = CamActor.CamOverridePostProcess;
	out_PPOverrideAlpha = CamActor.CamOverridePostProcessAlpha;

}

function EndCameraState()
{
//	local vector NewPawnLoc;
	
//	NewPawnLoc = TargetLocation;
//	NewPawnLoc.Z = PCOwner.Pawn.Location.Z;
	
//	PCOwner.Pawn.SetLocation( NewPawnLoc );
}


DefaultProperties
{
	ViewDistance=500.0f
}
