//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_Fire_SaturationFire extends X2Action_Fire config(GameCore);

var int HandBone;
var SkeletalMeshSocket AttachSocket;

var X2AbilityMultiTarget_Cone coneTemplate;
var float ConeLength, ConeWidth;

var Vector StartLocation, EndLocation;
var Vector UnitDir, ConeDir;

var Vector SweepEndLocation_Begin, SweepEndLocation_End;
var float Duration, ArcDelta, ConeAngle;

var bool beginAnim;
var bool doneAnim;

var float currDuration;

var XComGameState_Ability AbilityState;

var Vector EndCornerLocation;

var array<TTile> CornerTiles;
var array<StateObjectReference> TargetsLeftToNotify;


function bool IsNeighboringTile(TTile center, TTile neighbor)
{
	local TTile t;
	t = center;
	t.x += 1;
	if (t == neighbor)
	{
		return true;
	}

	t = center;
	t.x -= 1;
	if (t == neighbor)
	{
		return true;
	}
	t = center;
	t.y += 1;
	if (t == neighbor)
	{
		return true;
	}

	t = center;
	t.y -= 1;
	if (t == neighbor)
	{
		return true;
	}

	//t = center;
	//t.x -= 1;
	//if (t == neighbor)
	//{
	//	return true;
	//}
	//t = center;
	//t.x -= 1;
	//if (t == neighbor)
	//{
	//	return true;
	//}

	return false;
}

function bool FindTile(TTile tile, out array<TTile> findArray)
{
	local TTile iter;
	foreach findArray(iter)
	{
		if (iter == tile)
		{
			return true;
		}
	}

	return false;
}

function bool FindSameXYTile(TTile tile, out array<TTile> findArray)
{
	local TTile iter;
	foreach findArray(iter)
	{
		if (iter.X == tile.X && iter.Y == tile.Y)
		{
			return true;
		}
	}

	return false;
}


function Init(const out VisualizationTrack InTrack)
{
	local Vector TempDir;
	local float degree, testDegree, degreeDelta;
	local TTile tile;
	local bool found;

	local float a;

	super.Init(InTrack);

	UnitPawn.AimEnabled = true;
	
	SetFireParameters(false, , false);		// Notify targets individually and not at once
	
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

	if (AbilityState.GetMyTemplate().TargetingMethod == class'X2TargetingMethod_Cone')
	{
		coneTemplate = X2AbilityMultiTarget_Cone(AbilityState.GetMyTemplate().AbilityMultiTargetStyle);

		ConeLength = coneTemplate.GetConeLength(AbilityState);

		// Widen the cone a little bit so the sweep looks more natural when hitting outer units
		ConeWidth = coneTemplate.GetConeEndDiameter(AbilityState) + class'XComWorldData'.const.WORLD_STEPSIZE;

		StartLocation = UnitPawn.Location;
		EndLocation = AbilityContext.InputContext.TargetLocations[0];

		ConeDir = EndLocation - StartLocation;
		UnitDir = Normal(ConeDir);

		ConeAngle = ConeWidth / ConeLength;

		ArcDelta = ConeAngle / Duration;

		degreeDelta = ConeAngle / (ConeWidth / 96);

		TempDir.x = UnitDir.x * cos(-ConeAngle / 2) - UnitDir.y * sin(-ConeAngle / 2);
		TempDir.y = UnitDir.x * sin(-ConeAngle / 2) + UnitDir.y * cos(-ConeAngle / 2);
		TempDir.z = 0;

		SweepEndLocation_Begin = StartLocation + (TempDir * VSize(ConeDir));

		TempDir.x = UnitDir.x * cos(ConeAngle / 2) - UnitDir.y * sin(ConeAngle / 2);
		TempDir.y = UnitDir.x * sin(ConeAngle / 2) + UnitDir.y * cos(ConeAngle / 2);
		TempDir.z = 0;

		SweepEndLocation_End = StartLocation + (TempDir * VSize(ConeDir));


		for (degree = 0; degree < ConeAngle; degree += degreeDelta)
		{
			testDegree = degree - (ConeAngle / 2);

			TempDir.x = UnitDir.x * cos(testDegree) - UnitDir.y * sin(testDegree);
			TempDir.y = UnitDir.x * sin(testDegree) + UnitDir.y * cos(testDegree);
			TempDir.z = 0;

			EndLocation = StartLocation + (TempDir * VSize(ConeDir));

			tile = `XWORLD.GetTileCoordinatesFromPosition(EndLocation);
			found = false;
			a = VSize(EndLocation - StartLocation);
			while (found == false && a >= (class'XComWorldData'.const.WORLD_STEPSIZE * 2))
			{
				found = FindTile(tile, AbilityContext.InputContext.VisibleTargetedTiles);

				if (found == false)
				{
					if (FindTile(tile, CornerTiles) == false)
					{
						CornerTiles.AddItem(tile);
					}
					EndLocation -= (TempDir * class'XComWorldData'.const.WORLD_STEPSIZE);
					tile = `XWORLD.GetTileCoordinatesFromPosition(EndLocation);
					a = VSize(EndLocation - StartLocation);
				}
			}
		}

		TargetsLeftToNotify = AbilityContext.InputContext.MultiTargets;
	}

	currDuration = 0.0;
	beginAnim = false;
	doneAnim = false;
}

simulated state Executing
{
	simulated event Tick(float fDeltaT)
	{
		local StateObjectReference targetIter;
		local XComGameState_Unit targetUnitState;
		local XComGameState_Destructible targetDestructibleState;
		local Vector tilePoint;
		local Rotator hittingTargetRotator;
		local Rotator currentAimingRotator;

		NotifyTargetTimer -= fDeltaT;

		if (bUseAnimToSetNotifyTimer && !bNotifiedTargets && NotifyTargetTimer < 0.0f)
		{
			NotifyTargetsAbilityApplied();
		}

		UpdateAim(fDeltaT);
		
		//Sweep across the targets - notify those we've passed
		currentAimingRotator = Rotator(EndLocation - StartLocation);
		foreach TargetsLeftToNotify(targetIter)
		{
			targetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(targetIter.ObjectID));
			targetDestructibleState = XComGameState_Destructible(`XCOMHISTORY.GetGameStateForObjectID(targetIter.ObjectID));

			if (targetUnitState != None)
				tilePoint = `XWORLD.GetPositionFromTileCoordinates(targetUnitState.TileLocation);
			else if (targetDestructibleState != None)
				tilePoint = `XWORLD.GetPositionFromTileCoordinates(targetDestructibleState.TileLocation);
			else
				continue;

			hittingTargetRotator = Rotator(tilePoint - StartLocation);
			if (Normalize(hittingTargetRotator - currentAimingRotator).Yaw < 0) //We passed this target
			{
				VisualizationMgr.SendInterTrackMessage(targetIter);
				TargetsLeftToNotify.RemoveItem(targetIter);
				break; //To avoid issues modifying an array while in a foreach
			}
		}
	}

	simulated function UpdateAim(float DT)
	{
		local float angle;
		local Vector TempDir;
		local bool aimDone;

		aimDone = true;

		if (UnitPawn.AimEnabled)
		{
			aimDone = false;

			angle = ArcDelta * currDuration;
			angle = angle - (ConeAngle / 2);

			TempDir.x = UnitDir.x * cos(angle) - UnitDir.y * sin(angle);
			TempDir.y = UnitDir.x * sin(angle) + UnitDir.y * cos(angle);
			TempDir.z = 0;

			EndLocation = StartLocation + (TempDir * VSize(ConeDir));

			//`SHAPEMGR.DrawSphere(EndLocation, Vect(10, 10, 10), MakeLinearColor(0.5f, 1.0f, 0.5f, 1.0f));
			//`SHAPEMGR.DrawLine(StartLocation, EndLocation, 6, MakeLinearColor(1.0f, 0.5f, 0.5f, 1.0f));
			//`SHAPEMGR.DrawLine(StartLocation, SweepEndLocation_Begin, 6, MakeLinearColor(0.0f, 0.0f, 1.0f, 1.0f));		// Beginning of sweep
			//`SHAPEMGR.DrawLine(StartLocation, SweepEndLocation_End, 6, MakeLinearColor(1.0f, 1.0f, 0.0f, 1.0f));		// End of sweep
			//`SHAPEMGR.DrawSphere(EndLocation, Vect(10, 10, 10), MakeLinearColor(0.0f, 1.0f, 0.0f, 1.0f));
			//`SHAPEMGR.DrawTile(tile, 0, 255, 255);
			
			//blend aim anim
			UnitPawn.TargetLoc = EndLocation;
		}

		if (aimDone == false)
		{
			currDuration += DT;

			if (currDuration > Duration)
			{
				currDuration = Duration;
				aimDone = true;
			}
		}

		if (aimDone && currDuration > 0.0)
		{
			CompleteAction();
		}
	}

	function SetTargetUnitDiscState()
	{
		local XGUnit ThisTargetUnit;

		ThisTargetUnit = XGUnit(PrimaryTarget);
		if (ThisTargetUnit != None && ThisTargetUnit.IsMine())
		{
			ThisTargetUnit.SetDiscState(eDS_Hidden);
		}

		if (Unit != None)
		{
			Unit.SetDiscState(eDS_Hidden);
		}
	}
	
Begin:
	if (XGUnit(PrimaryTarget).GetTeam() == eTeam_Neutral)
	{
		FOWViewer = `XWORLD.CreateFOWViewer(XGUnit(PrimaryTarget).GetPawn().Location, class'XComWorldData'.const.WORLD_StepSize * 3);

		XGUnit(PrimaryTarget).SetForceVisibility(eForceVisible);
		XGUnit(PrimaryTarget).GetPawn().UpdatePawnVisibility();

		// Sleep long enough for the fog to be revealed
		Sleep(1.0f * GetDelayModifier());
	}

	Unit.CurrentFireAction = self;
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

	while (!bNotifiedTargets && !IsTimedOut())
		Sleep(0.0f);

	//Failure case handling! We failed to notify our targets that damage was done. Notify them now.
	if (IsTimedOut())
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
}

function CompleteAction()
{
	local StateObjectReference targetIter;

	//Send remaining notifies regardless of unit/destructible targets
	foreach TargetsLeftToNotify(targetIter)
	{
		VisualizationMgr.SendInterTrackMessage(targetIter);
	}

	super.CompleteAction();
}


DefaultProperties
{
	NotifyTargetTimer = 1.0;
	TimeoutSeconds = 10.0f; //Should eventually be an estimate of how long we will run
	bNotifyMultiTargetsAtOnce = false;

		Duration = 3.0;
}
