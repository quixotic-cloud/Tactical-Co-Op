//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor.
//-----------------------------------------------------------

class X2Action_UpdateFlashlight extends X2Action;

var private XGWeapon				WeaponToChange;
var private bool					FlashlightOn;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	WeaponToChange = Unit.GetInventory().GetActiveWeapon();
}

simulated state Executing
{
Begin:
	if (WeaponToChange != None)
		WeaponToChange.UpdateFlashlightState();

	CompleteAction();
}

DefaultProperties
{
}