//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_Fire_WeaponOnly extends X2Action_Fire;

function Init(const out VisualizationTrack InTrack)
{
	Super.Init(InTrack);

	AnimParams.AnimName = AbilityTemplate.CustomFireAnim;
}

simulated state Executing
{
Begin:
	if (XGUnit(PrimaryTarget).GetTeam() == eTeam_Neutral)
	{
		HideFOW();

		// Sleep long enough for the fog to be revealed
		Sleep(1.0f * GetDelayModifier());
	}

	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);
	FinishAnim(UnitPawn.PlayWeaponAnim(AnimParams));	
	
	while (!bNotifiedTargets && !IsTimedOut())
		Sleep(0.0f);

	//Failure case handling! We failed to notify our targets that damage was done. Notify them now.
	if( IsTimedOut() )
	{
		NotifyTargetsAbilityApplied();
	}

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

DefaultProperties
{
}
