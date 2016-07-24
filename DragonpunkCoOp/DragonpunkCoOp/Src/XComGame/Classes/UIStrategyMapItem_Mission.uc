
class UIStrategyMapItem_Mission extends UIStrategyMapItem;

var localized string m_strMissionType;
var localized string m_strMissionRewards;
var localized string m_strMissionLocked;
var localized string m_strMissionCancel;

function UpdateFlyoverText()
{

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

DefaultProperties
{
	bDisableHitTestWhenZoomedOut = false;
	bFadeWhenZoomedOut = false;
}
