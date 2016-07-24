class X2Action_Fire_AdditiveAnim extends X2Action_Fire;

simulated state Executing
{
Begin:
	if (XGUnit(PrimaryTarget).GetTeam() == eTeam_Neutral)
	{
		HideFOW();

		// Sleep long enough for the fog to be revealed
		Sleep(1.0f * GetDelayModifier());
	}

	FinishAnim(UnitPawn.GetAnimTreeController().PlayAdditiveDynamicAnim(AnimParams));
	
	// Jwats: Now blend out the animation
	UnitPawn.GetAnimTreeController().RemoveAdditiveDynamicAnim(AnimParams);

	SetTargetUnitDiscState();

	if (FOWViewer != none)
	{
		`XWORLD.DestroyFOWViewer(FOWViewer);
		XGUnit(PrimaryTarget).SetForceVisibility(eForceNone);
		XGUnit(PrimaryTarget).GetPawn().UpdatePawnVisibility();
	}

	CompleteAction();
	//reset to false, only during firing would the projectile be able to overwrite aim
	UnitPawn.ProjectileOverwriteAim = false;
}
