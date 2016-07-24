//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComCamState_Shell extends XComCamState_HQ;

var name CamName;
var transient CameraActor CamActor;

function InitView( PlayerController ForPlayer, name CameraName )
{
	local Actor TmpActor;
	local array<Actor> Actors;
	local XComBlueprint Blueprint;

	InitCameraState( ForPlayer );

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
}

function GetView( float DeltaTime, out vector out_Focus, out rotator out_Rotation, out float out_ViewDistance, out float out_FOV, out PostProcessSettings out_PPSettings, out float out_PPOverrideAlpha  )
{
	local vector AdjustedCamActorLoc;

	if (CamActor == none)
		return;

	// A camera actor is used to determine where the camera should go.
	
	AdjustedCamActorLoc = CamActor.Location;

	out_ViewDistance = ViewDistance;
	out_Focus = AdjustedCamActorLoc;
	out_Rotation = CamActor.Rotation;
	out_FOV = CamActor.FOVAngle;
	PCOwner.SetRotation( out_Rotation );

	out_PPSettings = CamActor.CamOverridePostProcess;
	out_PPOverrideAlpha = CamActor.CamOverridePostProcessAlpha;

}

DefaultProperties
{
	ViewDistance=0
}
