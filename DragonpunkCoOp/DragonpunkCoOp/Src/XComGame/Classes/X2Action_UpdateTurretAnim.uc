class X2Action_UpdateTurretAnim extends X2Action;

//------------------------------------------------------------------------------------------------
simulated state Executing
{
Begin:
	Unit.UpdateTurretIdle();
	CompleteAction();
}

defaultproperties
{
}
