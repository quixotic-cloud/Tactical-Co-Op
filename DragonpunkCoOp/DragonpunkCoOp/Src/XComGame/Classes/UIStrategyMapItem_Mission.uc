
class UIStrategyMapItem_Mission extends UIStrategyMapItem;

var string Label; 

simulated function UIStrategyMapItem InitMapItem(out XComGameState_GeoscapeEntity Entity)
{
	super.InitMapItem(Entity);
	Hide();
	return self; 
}

function UpdateFlyoverText()
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local string tempLabel; 

	History = `XCOMHISTORY;
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));

	tempLabel = MissionState.GetMissionSource().MissionPinLabel;
	if( Label != tempLabel )
	{
		Label = tempLabel;
		MC.FunctionString("setHTMLText", Label);// set label to the mission type, e.g. ADVENT Blacksite
	}
}

simulated function OnMouseIn()
{
	Super.OnMouseIn();

	if(MapItem3D != none)
		MapItem3D.SetHoverMaterialValue(1);
	if(AnimMapItem3D != none)
		AnimMapItem3D.SetHoverMaterialValue(1);
}

// Clear mouse hover special behavior
simulated function OnMouseOut()
{
	Super.OnMouseOut();

	if(MapItem3D != none)
		MapItem3D.SetHoverMaterialValue(0);
	if(AnimMapItem3D != none)
		AnimMapItem3D.SetHoverMaterialValue(0);
}

simulated function bool IsSelectable()
{
	return true;
}

// select the mission
function OnMissionLaunch()
{
	local XComGameStateHistory History;
	local XComGameState_GeoscapeEntity GeoscapeEntity;

	History = `XCOMHISTORY;
	GeoscapeEntity = XComGameState_GeoscapeEntity(History.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));
	GeoscapeEntity.AttemptSelectionCheckInterruption();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return true;
	}

	switch(cmd)
	{
		case class'UIUtilities_Input'.static.GetAdvanceButtonInputCode():
			OnMissionLaunch();
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function Show()
{
	//Prevent from being turned on all the time in the base MapItem's Tick check. 
	if( bIsFocused )
		super.Show();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	Show();
	MC.FunctionVoid("MoveToHighestDepth");
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	Hide();
}

DefaultProperties
{
	bDisableHitTestWhenZoomedOut = false;
	bFadeWhenZoomedOut = false;
}
