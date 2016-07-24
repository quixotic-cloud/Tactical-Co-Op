//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_SetWeapon extends X2Action;

var XComWeapon WeaponToSet;

simulated state Executing
{
Begin:

	UnitPawn.SetCurrentWeapon(WeaponToSet);
	CompleteAction();
}