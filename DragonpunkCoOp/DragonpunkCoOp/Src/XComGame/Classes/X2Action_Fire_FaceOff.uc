class X2Action_Fire_Faceoff extends X2Action_Fire;


var transient vector vTargetLocation;



simulated state Executing
{
	// This overrides (and is based on) the parent version, but is simpler.
	simulated function UpdateAim(float DT)
	{
		if(!bNotifiedTargets && !bHaltAimUpdates )
		{
			if((PrimaryTarget != none) && AbilityContext.ResultContext.HitResult != eHit_Miss)
			{
				UnitPawn.TargetLoc = PrimaryTarget.GetShootAtLocation(AbilityContext.ResultContext.HitResult, AbilityContext.InputContext.SourceObject);
			}
			else
			{
				UnitPawn.TargetLoc = AimAtLocation;
			}

			//If we are very close to the target, just update our aim with a more distance target once and then stop
			if(VSize(UnitPawn.TargetLoc - UnitPawn.Location) < (class'XComWorldData'.const.WORLD_StepSize * 2.0f))
			{
				bHaltAimUpdates = true;
				UnitPawn.TargetLoc = UnitPawn.TargetLoc + (Normal(UnitPawn.TargetLoc - UnitPawn.Location) * 400.0f);
			}
		}
	}

	// Snap-Rotate the unit if it is facing too far away from the target.
	simulated function SnapUnitPawnToTargetDirIfNeeded()
	{
		local vector   vTargetDir;
		local Rotator  DesiredRotation;
		local float    fDot;

		vTargetDir = vTargetLocation - UnitPawn.Location;
		vTargetDir.Z = 0;
		vTargetDir = normal(vTargetDir);
		fDot = vTargetDir dot vector(UnitPawn.Rotation);

		// 90 degrees check.
		if (fDot < 0.0f)
		{
			DesiredRotation = Normalize(Rotator(vTargetDir));
			DesiredRotation.Pitch = 0;
			DesiredRotation.Roll = 0;
			UnitPawn.SetRotation( DesiredRotation );
		}
	}

Begin:

	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	SnapUnitPawnToTargetDirIfNeeded();

	AnimParams.BlendTime = 0.25f;
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

	//Failure case handling! We failed to notify our targets that damage was done. Notify them now.
	SetTargetUnitDiscState();

	if (FOWViewer != none)
	{
		`XWORLD.DestroyFOWViewer(FOWViewer);

		if(XGUnit(PrimaryTarget).IsAlive())
		{
			XGUnit(PrimaryTarget).SetForceVisibility(eForceNone);
			XGUnit(PrimaryTarget).GetPawn().UpdatePawnVisibility();
		}
	}

	CompleteAction();
}
