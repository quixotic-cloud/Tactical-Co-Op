
class UIStrategyMap_OffScreenIndicators extends UIPanel;

// Constructor
simulated function UIStrategyMap_OffScreenIndicators InitOffScreenIndicators()
{
	InitPanel();
	return self;
}

simulated function OnInit()
{
	super.OnInit();
	Movie.Pres.SubscribeToUIUpdate( Update );
	InitializeTooltipData();
}

simulated function InitializeTooltipData()
{
	
}

simulated function Update()
{
	local float yaw;
	local bool isOnScreen;
	local Vector2D vScreenCoords;
	local XComGameState_MissionSite kMission;

	if(Movie.Stack.GetCurrentClass() != class'UIStrategyMap') return;

	// Mission Indicators
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_MissionSite', kMission)
	{
		if(kMission.Available)
		{
			isOnScreen = class'UIUtilities'.static.IsOnScreen(`EARTH.ConvertEarthToWorld(kMission.Get2DLocation()), vScreenCoords);
			yaw = GetRotation(vScreenCoords);

			if( isOnScreen )
			{
				RemoveIndicator("Mission_"$kMission.ObjectID);	
			}
			else
			{
				vScreenCoords = Movie.ConvertNormalizedScreenCoordsToUICoords(vScreenCoords.X, vScreenCoords.Y);
				SetIndicator("Mission_" $ kMission.ObjectID, vScreenCoords.x, vScreenCoords.y, yaw, "yellow", "mission");
			}
		}
	}
}

simulated function float GetRotation(Vector2D vScreenCoords)
{
	local Vector2D vTmp;
	vTmp.x = 0.5f - vScreenCoords.x; // vector from center of screen to arrow location
	vTmp.y = 0.5f - vScreenCoords.y; // vector from center of screen to arrow location
	return Atan2(vTmp.y, vTmp.x) * (180.0f / Pi) - 90;
}

// Send individual arrow update information over to flash
simulated function SetIndicator( string id, float xloc,  float yloc, float yaw, string sColor, string sIcon)
{
	MC.BeginFunctionOp("SetIndicator");
	MC.QueueString(id);
	MC.QueueNumber(xloc);
	MC.QueueNumber(yloc);
	MC.QueueNumber(yaw);
	MC.QueueString(sColor);
	MC.QueueString(sIcon);
	MC.EndOp();
}

simulated function RemoveIndicator( string id )
{
	MC.FunctionString("RemoveIndicator", id);
}

simulated function RemoveMission( XComGameState_MissionSite kMission )
{
	RemoveIndicator("Mission_"$kMission.ObjectID);
}

event Destroyed()
{
	Movie.Pres.m_kTooltipMgr.RemoveTooltips(self);
	Movie.Pres.UnsubscribeToUIUpdate( Update );
	super.Destroyed();
}

DefaultProperties
{
	MCName = "OffScreenIndicatorContainer";
	LibID = "OffScreenIndicatorContainer";
}
