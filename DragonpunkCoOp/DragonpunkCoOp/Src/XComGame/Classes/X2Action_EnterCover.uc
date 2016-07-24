//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_EnterCover extends X2Action 
	dependson(XGUnitNativeBase, XComAnimNodeBlendDynamic)
	config(Animation);

//Cached info for performing the action
//*************************************
var XGWeapon                UseWeapon;
//*************************************

//Cached data from XGAction_Targeting
//*************************************
var XGUnit              PrimaryTarget;  
var Vector              vTarget;

//  Used in state code when changing weapon
//*************************************
var ELocation           m_eChangeLoc;

var XComGameStateContext_Ability AbilityContext;

//Variables used during the Executing state
//********************************************
var private CustomAnimParams	AnimParams;
var AnimNodeSequence			SeqToPlay;
var bool						bInstantEnterCover;
var config float				CelebrateAfterKillPercent;
//********************************************

function Init(const out VisualizationTrack InTrack)
{
	if( AbilityContext != none )
	{
		super.Init(InTrack);
	}
	else
	{
		super.Init(InTrack);
		AbilityContext = XComGameStateContext_Ability(StateChangeContext);
	}

	PrimaryTarget = XGUnit(`XCOMHISTORY.GetGameStateForObjectID( AbilityContext.InputContext.PrimaryTarget.ObjectID ).GetVisualizer());
	if( AbilityContext.InputContext.TargetLocations.Length > 0 )
	{
		vTarget = AbilityContext.InputContext.TargetLocations[0];
	}

	if( AbilityContext.InputContext.ItemObject.ObjectID > 0 )
	{
		UseWeapon = XGWeapon(`XCOMHISTORY.GetGameStateForObjectID( AbilityContext.InputContext.ItemObject.ObjectID ).GetVisualizer());
	}
}

simulated function bool ShouldCelebrate()
{
	local bool bShouldCelebrate;
	
	bShouldCelebrate = false;

	if( PrimaryTarget != None && XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(PrimaryTarget.ObjectID)).IsDead() )
	{
		bShouldCelebrate = FRand() < CelebrateAfterKillPercent;
	}

	return bShouldCelebrate;
}

function CompleteAction()
{
	super.CompleteAction();
}


function EndCrouching()
{
	local XComGameState_Unit TestUnitState;
	local XGUnit TestUnitVisualizer;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', TestUnitState)
	{
		TestUnitVisualizer = XGUnit(TestUnitState.GetVisualizer());
		TestUnitVisualizer.IdleStateMachine.EndCrouch();
	}
}

simulated state Executing
{
	function CheckAmmoUnitSpeak()
	{
		local XComGameStateHistory History;
		local XComGameState_Item WeaponUsed;
		//local int LowAmmoThreshold;

		History = `XCOMHISTORY;

		//For now, only call out ammo for standard shots
		if( AbilityContext.InputContext.AbilityTemplateName == 'StandardShot')
		{
			WeaponUsed = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
			if( WeaponUsed != None )
			{
				//Use delay speech since we just called out whether we hit / missed / killed the target
				if (WeaponUsed.GetItemClipSize() > 1)
				{
					if( WeaponUsed.Ammo == 1  )
					{
						Unit.SetTimer(2 * FRand() + 0.5f, false, 'DelayLowAmmo');
					}
					else if ( WeaponUsed.Ammo == 0 )
					{
						Unit.SetTimer(2 * FRand() + 0.5f, false, 'DelayNoAmmo');
					}
				}
			}
		}		
	}

	function bool IsTargetKilledInThisHistoryFrame( XComGameStateHistory History, int iTargetObjectId )
	{
		local XComGameState_BaseObject CurrTargetGameStateObj;
		local XComGameState_BaseObject PrevTargetGameStateObj;
		local XComGameState_Unit CurrTargetGameStateUnit;
		local XComGameState_Unit PrevTargetGameStateUnit;
		local bool bCurrIsDead;
		local bool bPrevIsDead;

		History.GetCurrentAndPreviousGameStatesForObjectID(iTargetObjectId, PrevTargetGameStateObj, CurrTargetGameStateObj, , AbilityContext.AssociatedState.HistoryIndex);

		CurrTargetGameStateUnit = XComGameState_Unit(CurrTargetGameStateObj);
		PrevTargetGameStateUnit = XComGameState_Unit(PrevTargetGameStateObj);
		bCurrIsDead = (CurrTargetGameStateUnit != None && !CurrTargetGameStateUnit.IsAlive());
		bPrevIsDead = (PrevTargetGameStateUnit != None && !PrevTargetGameStateUnit.IsAlive());

		return (!bPrevIsDead && bCurrIsDead);
	}

	function int GetNumTargetsKilledInThisHistoryFrame()
	{
		local XComGameStateHistory History;
		local StateObjectReference Target;
		local int iNumTargetsKilled;
		local int Index;
		local int DupeCheckIndex;
		local bool bDupeFound;

		History = `XCOMHISTORY;

		iNumTargetsKilled = 0;

		if (IsTargetKilledInThisHistoryFrame(History, AbilityContext.InputContext.PrimaryTarget.ObjectID))
		{
			iNumTargetsKilled++;
		}

		for (Index = 0; Index < AbilityContext.InputContext.MultiTargets.Length; Index++)
		{
			Target = AbilityContext.InputContext.MultiTargets[Index];

			// Check to see if the target is duplicated as the primary target
			if (Target == AbilityContext.InputContext.PrimaryTarget)
			{
				bDupeFound = true;
			}
			else
			{
				bDupeFound = false;
			}
			
			// Check to see if the target is duplicated earlier in the multitarget list
			for (DupeCheckIndex = 0; DupeCheckIndex <= Index - 1 && !bDupeFound; DupeCheckIndex++)
			{
				if (AbilityContext.InputContext.MultiTargets[DupeCheckIndex] == Target)
				{
					bDupeFound = true;
				}
			}

			if (!bDupeFound && IsTargetKilledInThisHistoryFrame(History, Target.ObjectID))
			{
				iNumTargetsKilled++;
			}
		}

		return iNumTargetsKilled;
	}

	function bool IsTargetDamageMitigated(int iTargetObjectId)
	{
		local XComGameState_Unit TargetUnit;
		local int Index;

		TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(iTargetObjectId));
		if (TargetUnit != none)
		{
			for (Index = TargetUnit.DamageResults.Length - 1; index >= 0; --Index)
			{
				if (TargetUnit.DamageResults[Index].Context == AbilityContext)
				{
					if (TargetUnit.DamageResults[Index].MitigationAmount > 0)
						return true;
				}
			}
		}

		return false;
	}

	function bool RespondToShotSpeak()
	{
		local bool bSpoke;

		local AbilityResultContext ResultContext;
		local int iNumTargetsKilled;
		
		local XComGameState_Unit TargetUnit;
		local X2AbilityTemplate AbilityTemplate;

		if (Unit.IsAlive())
		{
			AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
			iNumTargetsKilled = GetNumTargetsKilledInThisHistoryFrame();

			// If there is a primary target, speak to that.  ELSE if multiple targets were killed, speak to that.
			if(AbilityContext.InputContext.PrimaryTarget.ObjectID > 0)
			{
				//Call out if we killed the target
				if( iNumTargetsKilled > 0 )
				{
					if ( Unit.GetTeam() == eTeam_Alien )
					{
						if ( iNumTargetsKilled > 1 )
						{
							if (AbilityTemplate.MultiTargetsKilledByAlienSpeech != '')
							{
								Unit.UnitSpeak(AbilityTemplate.MultiTargetsKilledByAlienSpeech);
								bSpoke = true;
							}
						}
						else
						{
							if (AbilityTemplate.TargetKilledByAlienSpeech != '')
							{
								Unit.UnitSpeak(AbilityTemplate.TargetKilledByAlienSpeech);
								bSpoke = true;
							}
						}
					}
					else if ( Unit.GetTeam() == eTeam_XCom )
					{
						if ( iNumTargetsKilled > 1 )
						{
							if (AbilityTemplate.MultiTargetsKilledByXComSpeech != '')
							{
								Unit.UnitSpeak(AbilityTemplate.MultiTargetsKilledByXComSpeech);
								bSpoke = true;
							}
						}
						else
						{
							if (AbilityTemplate.TargetKilledByXComSpeech != '')
							{
								Unit.UnitSpeak(AbilityTemplate.TargetKilledByXComSpeech);
								bSpoke = true;
							}
						}
					}
				}

				// Call out if we hit, but didn't kill
				else if( AbilityContext.IsResultContextHit() )
				{
					ResultContext = AbilityContext.ResultContext;

					if ( ResultContext.HitResult == eHit_Graze )
					{
						if (AbilityTemplate.TargetWingedSpeech != '')
						{
							Unit.UnitSpeak(AbilityTemplate.TargetWingedSpeech);
							bSpoke = true;
						}
					}
					else if (IsTargetDamageMitigated(AbilityContext.InputContext.PrimaryTarget.ObjectID))
					{
						// TTP 19513: "If a soldier shreds an enemy unit completely, "Armor Defense" VO should not play"
						TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
						if (TargetUnit.GetArmorMitigationForUnitFlag() > 0)
						{
							if (AbilityTemplate.TargetArmorHitSpeech != '')
							{
								Unit.UnitSpeak(AbilityTemplate.TargetArmorHitSpeech);
								bSpoke = true;
							}
						}
					}
				}

				//Call out a miss
				else if( AbilityContext.IsResultContextMiss() )
				{
					if (AbilityTemplate.TargetMissedSpeech != '')
					{
						Unit.UnitSpeak(AbilityTemplate.TargetMissedSpeech);
						bSpoke = true;
					}
				}
			}
			else if( iNumTargetsKilled > 1 )
			{
				if ( Unit.GetTeam() == eTeam_Alien )
				{
					if (AbilityTemplate.MultiTargetsKilledByAlienSpeech != '')
					{
						Unit.UnitSpeak(AbilityTemplate.MultiTargetsKilledByAlienSpeech);
						bSpoke = true;
					}
				}
				else if ( Unit.GetTeam() == eTeam_XCom )
				{
					if (AbilityTemplate.MultiTargetsKilledByXComSpeech != '')
					{
						Unit.UnitSpeak(AbilityTemplate.MultiTargetsKilledByXComSpeech);
						bSpoke = true;
					}
				}
			}
		}

		return bSpoke;
	}

	function RestoreFOW()
	{
		local XGBattle_SP Battle;
		local XGPlayer AIPlayer;

		Battle = XGBattle_SP(`BATTLE);
		AIPlayer = Battle.GetAIPlayer();
		if( AIPlayer != None && AIPlayer.FOWViewer != None )
		{
			`XWORLD.DestroyFOWViewer(AIPlayer.FOWViewer);
		}		
	}

	function DoFallingCheck()
	{
		local bool bFalling; //See if we are going to be falling / fell. Don't do any cover animations if so
		local X2Action FallingAction;

		bFalling = `XCOMVISUALIZATIONMGR.TrackHasActionOfType(Track, class'X2Action_UnitFalling', FallingAction);

		if (bFalling)
		{
			bInstantEnterCover = true;
		}
	}

Begin:
	//`log("X2Action_EnterCover::Begin -"@Unit.IdleStateMachine.GetStateName()@UnitPawn@Unit.ObjectID, , 'XCom_Filtered');

	UnitPawn.EnableLeftHandIK(false);

	DoFallingCheck();

	//Play an enter cover animation if we exited cover
	//The order of operations in here are very sensitive, alter at your own risk
	//******************************************************
	
	//Exit cover animations generally used root motion, get the RMA systems ready
	UnitPawn.EnableRMAInteractPhysics(true);
	UnitPawn.EnableRMA(true, true);

	if( ShouldCelebrate() )
	{
		AnimParams = default.AnimParams;
		AnimParams.AnimName = 'HL_SignalPositive';
		if( UnitPawn.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName) )
		{
			FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
		}
	}

	EndCrouching();
	
	if( Unit.CanUseCover() && Unit.bSteppingOutOfCover )
	{	
		Unit.bShouldStepOut = false;
		AnimParams = default.AnimParams;
		AnimParams.PlayRate = GetNonCriticalAnimationSpeed();

		AnimParams.HasDesiredEndingAtom = true;
		AnimParams.DesiredEndingAtom.Translation = Unit.RestoreLocation;
		AnimParams.DesiredEndingAtom.Rotation = QuatFromRotator(Rotator(Unit.RestoreHeading));
		AnimParams.DesiredEndingAtom.Scale = 1.0f;

		switch (Unit.m_eCoverState)
		{
			case eCS_LowLeft:
			case eCS_HighLeft:
				AnimParams.AnimName = 'HL_StepIn';
				break;
			case eCS_LowRight:
			case eCS_HighRight:
				AnimParams.AnimName = 'HR_StepIn';
				break;
			case eCS_None:
				AnimParams.AnimName = 'NO_IdleGunUp';
				break;
		}

		SeqToPlay = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
		FinishAnim(SeqToPlay);
		if (VSizeSq(UnitPawn.Location - Unit.RestoreLocation) > 16 * 16)
		{
			`RedScreen("X2Action_EnterCover::ERROR! Unit not at unit restore point! : - Josh"$AnimParams.AnimName@UnitPawn@Unit.ObjectID@UnitPawn.Location@Unit.RestoreLocation);
			
			// Forcefully set location to restore location
			UnitPawn.SetLocation(Unit.RestoreLocation);
		}
	}
	else
	{
		AnimParams = default.AnimParams;
		AnimParams.PlayRate = GetNonCriticalAnimationSpeed();

		AnimParams.HasDesiredEndingAtom = true;
		AnimParams.DesiredEndingAtom.Translation = Unit.RestoreLocation;
		AnimParams.DesiredEndingAtom.Rotation = QuatFromRotator(Rotator(Unit.RestoreHeading));
		AnimParams.DesiredEndingAtom.Scale = 1.0f;

		switch (Unit.m_eCoverState)
		{
			case eCS_LowLeft:
			case eCS_LowRight:
				AnimParams.AnimName = 'LL_FireStop';
				break;
			case eCS_HighLeft:
			case eCS_HighRight:
				AnimParams.AnimName = 'HL_FireStop';
				break;
			case eCS_None:
				AnimParams.AnimName = 'NO_FireStop';
				break;
		}
		if (UnitPawn.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName))
		{
			SeqToPlay = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
			FinishAnim(SeqToPlay);
			if (VSizeSq(UnitPawn.Location - Unit.RestoreLocation) > 16 * 16)
			{
				`RedScreen("X2Action_EnterCover::ERROR! Unit not at unit restore point! : - Josh"$AnimParams.AnimName@UnitPawn@Unit.ObjectID@UnitPawn.Location@Unit.RestoreLocation);
				
				// Forcefully set location to restore location
				UnitPawn.SetLocation(Unit.RestoreLocation);
			}
		}
		else
		{
			// No animation to play so manually get rid of the aim
			if( XComWeapon(UseWeapon.m_kEntity).WeaponAimProfileType != WAP_Unarmed )
			{
				UnitPawn.SetAiming(false, 0.5f);
			}

			// Since we aren't playing an animation to get the correct location/facing do it manually
			if( VSizeSq(Unit.RestoreLocation - UnitPawn.Location) >= class'XComWorldData'.const.WORLD_StepSizeSquared )
			{
				UnitPawn.SetLocationNoOffset(Unit.RestoreLocation);
			}
			else
			{
				`Warn("X2Action_EnterCover: Attempting to restore "$UnitPawn$" to location more than a tile away!"@ `ShowVar(UnitPawn.Location)@ `ShowVar(Unit.RestoreLocation));
			}

			Unit.IdleStateMachine.ForceHeading(Unit.RestoreHeading);
			while( Unit.IdleStateMachine.IsEvaluatingStance() )
			{
				Sleep(0.0f);
			}
		}
	}

	if (ShouldCelebrate() && !bInstantEnterCover)
	{
		AnimParams = default.AnimParams;
		AnimParams.AnimName = 'HL_SignalPositivePost';
		if( (Unit.m_eCoverState == eCS_LowLeft || Unit.m_eCoverState == eCS_LowRight) 
			&& UnitPawn.GetAnimTreeController().CanPlayAnimation('LL_SignalPositivePost') )
		{
			AnimParams.AnimName = 'LL_SignalPositivePost';
		}

		if( UnitPawn.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName) )
		{
			FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
		}
	}

	//Reset RMA systems
	UnitPawn.EnableRMA(false, false);
	UnitPawn.EnableRMAInteractPhysics(false);
	UnitPawn.bSkipIK = false;
	UnitPawn.EnableFootIK(true);
	UnitPawn.bNoZAcceleration = false;

	Unit.bSteppingOutOfCover = false;

	Unit.UpdateInteractClaim();

	Unit.IdleStateMachine.CheckForStanceUpdateOnIdle();

	Unit.IdleStateMachine.PlayIdleAnim();
	if (!bInstantEnterCover)
	{
		Sleep(1.5f * GetDelayModifier()); // From Jake: Keep the focus on what we're looking at
	}

	if (!bInstantEnterCover)
	{
		if (RespondToShotSpeak())
		{
			//Don't linger in the targeting camera if the character is going to start talking.
			`CAMERASTACK.OnCinescriptAnimNotify("EnterCoverCut");

			Sleep(1.25f * GetDelayModifier()); // let the audio finish playing. 
		}
	}

	Unit.IdleStateMachine.bTargeting = false;
	PrimaryTarget.IdleStateMachine.bTargeting = false;

		
	//Have the unit callout their ammo state if it is low	
	CheckAmmoUnitSpeak();

	RestoreFOW();

	CompleteAction();
}

DefaultProperties
{	
}
