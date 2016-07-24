//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_CreateDoppelganger extends X2Action
	config(GameCore);

//Cached info for the unit performing the action
//*************************************
var protected XGUnit			DoppelgangerUnit;
var protected TTile				CurrentTile;
var protected CustomAnimParams	AnimParams;

var private XComGameState_Unit			DoppelgangerUnitState;
var private X2Camera_LookAtActorTimed	LookAtCam;
var private Actor						FOWViewer;					// The current FOW Viewer actor
var private bool						bReceivedStartMessage;

var float						StartAnimationMinDelaySec;
var float						StartAnimationMaxDelaySec;

// Set by visualizer so we know who to mimic
var XGUnit						OriginalUnit;
var XComGameState_Unit          OriginalUnitState; //Used to find visualizer if OriginalUnit not explicitly set
var bool						ShouldCopyAppearance;
var name                        ReanimationName;
var XComGameState_Ability       ReanimatorAbilityState;
var bool                        bWaitForOriginalUnitMessage;
var bool                        bAllowNewAnimationsOnDoppelganger;
var bool                        bReplacingOriginalUnit;
var bool                        bIgnorePose;
//*************************************

function Init(const out VisualizationTrack InTrack)
{
	local XComGameStateHistory History;

	super.Init(InTrack);

	History = `XCOMHISTORY;
	DoppelgangerUnit = XGUnit(Track.TrackActor);

	DoppelgangerUnitState = XComGameState_Unit(History.GetGameStateForObjectID(DoppelgangerUnit.ObjectID));

	//It may be the case that this X2Action is created before the original unit's visualizer is ready (on loading).
	//In that case, their state object is passed in, and we ask for the visualizer now.
	if (OriginalUnit == None && OriginalUnitState != None)
		OriginalUnit = XGUnit(OriginalUnitState.GetVisualizer());
}

function bool CheckInterrupted()
{
	return VisualizationBlockContext.InterruptionStatus == eInterruptionStatus_Interrupt;
}

function HandleTrackMessage()
{
	bReceivedStartMessage = true;
}

function ForceImmediateTimeout()
{
	// Do nothing. We want the ragdoll to finish.
}

simulated state Executing
{
	simulated function bool CopyMeshAndMaterials(SkeletalMeshComponent SourceComp, SkeletalMeshComponent DestComp, SkeletalMeshComponent SourceParent, SkeletalMeshComponent DestParent, DynamicLightEnvironmentComponent SourceLightEnvironment)
	{
		local int i;
		local bool CreatedComponent;

		CreatedComponent = false;
		if( SourceComp != None )
		{
			if( SourceComp.SkeletalMesh != none )
			{
				DestComp.SetSkeletalMesh(SourceComp.SkeletalMesh);
			}

			// copy materials
			for( i = 0; i < SourceComp.Materials.Length; i++ )
			{
				DestComp.SetMaterial(i, SourceComp.GetMaterial(i));
			}
			for( i = 0; i < SourceComp.AuxMaterials.Length; i++ )
			{
				DestComp.SetAuxMaterial(i, SourceComp.GetAuxMaterial(i));
			}

			// set parent anim comp if needed
			if( SourceComp.ParentAnimComponent == SourceParent && SourceParent != none )
			{
				DestComp.SetParentAnimComponent(DestParent);
			}

			// always set light environment and shadow parent
			DestComp.SetLightEnvironment(SourceLightEnvironment);
			DestComp.SetShadowParent(DestParent);
		}

		return CreatedComponent;
	}

	function CopyAppearance(XComUnitPawn SourcePawn, XComUnitPawn DestinationPawn)
	{
		local XComHumanPawn DestinationHuman;

		DestinationHuman = XComHumanPawn(DestinationPawn);
		if( DestinationHuman != None )
		{
			DestinationHuman.SetAppearance(DoppelgangerUnitState.kAppearance);
		}
		else
		{
			CopyMeshAndMaterials(SourcePawn.Mesh, DestinationPawn.Mesh, None, None, SourcePawn.LightEnvironment);
			DestinationPawn.m_kHeadMeshComponent = DestinationPawn.Mesh;

			CopyMeshAndMaterials(SourcePawn.m_kTorsoComponent, DestinationPawn.m_kTorsoComponent, SourcePawn.Mesh, DestinationPawn.Mesh, SourcePawn.LightEnvironment);
			CopyMeshAndMaterials(SourcePawn.m_kArmsMC, DestinationPawn.m_kArmsMC, SourcePawn.Mesh, DestinationPawn.Mesh, SourcePawn.LightEnvironment);			
			CopyMeshAndMaterials(SourcePawn.m_kLeftArm, DestinationPawn.m_kLeftArm, SourcePawn.Mesh, DestinationPawn.Mesh, SourcePawn.LightEnvironment);
			CopyMeshAndMaterials(SourcePawn.m_kRightArm, DestinationPawn.m_kRightArm, SourcePawn.Mesh, DestinationPawn.Mesh, SourcePawn.LightEnvironment);
			CopyMeshAndMaterials(SourcePawn.m_kLeftArmDeco, DestinationPawn.m_kLeftArmDeco, SourcePawn.Mesh, DestinationPawn.Mesh, SourcePawn.LightEnvironment);
			CopyMeshAndMaterials(SourcePawn.m_kRightArmDeco, DestinationPawn.m_kRightArmDeco, SourcePawn.Mesh, DestinationPawn.Mesh, SourcePawn.LightEnvironment);
			CopyMeshAndMaterials(SourcePawn.m_kLegsMC, DestinationPawn.m_kLegsMC, SourcePawn.Mesh, DestinationPawn.Mesh, SourcePawn.LightEnvironment);
			CopyMeshAndMaterials(SourcePawn.m_kHelmetMC, DestinationPawn.m_kHelmetMC, SourcePawn.Mesh, DestinationPawn.Mesh, SourcePawn.LightEnvironment);
			CopyMeshAndMaterials(SourcePawn.m_kDecoKitMC, DestinationPawn.m_kDecoKitMC, SourcePawn.Mesh, DestinationPawn.Mesh, SourcePawn.LightEnvironment);
			CopyMeshAndMaterials(SourcePawn.m_kEyeMC, DestinationPawn.m_kEyeMC, SourcePawn.Mesh, DestinationPawn.Mesh, SourcePawn.LightEnvironment);
			CopyMeshAndMaterials(SourcePawn.m_kTeethMC, DestinationPawn.m_kTeethMC, SourcePawn.Mesh, DestinationPawn.Mesh, SourcePawn.LightEnvironment);
			CopyMeshAndMaterials(SourcePawn.m_kHairMC, DestinationPawn.m_kHairMC, SourcePawn.Mesh, DestinationPawn.Mesh, SourcePawn.LightEnvironment);
			CopyMeshAndMaterials(SourcePawn.m_kBeardMC, DestinationPawn.m_kBeardMC, SourcePawn.Mesh, DestinationPawn.Mesh, SourcePawn.LightEnvironment);
			CopyMeshAndMaterials(SourcePawn.m_kUpperFacialMC, DestinationPawn.m_kUpperFacialMC, SourcePawn.Mesh, DestinationPawn.Mesh, SourcePawn.LightEnvironment);
			CopyMeshAndMaterials(SourcePawn.m_kLowerFacialMC, DestinationPawn.m_kLowerFacialMC, SourcePawn.Mesh, DestinationPawn.Mesh, SourcePawn.LightEnvironment);
		}
		
		DestinationPawn.RestoreAnimSetsToDefault();
		DestinationPawn.UpdateAnimations();
		DestinationPawn.PostInitAnimTree(DestinationPawn.Mesh);

		DestinationPawn.MarkAuxParametersAsDirty(DestinationPawn.m_bAuxParamNeedsPrimary, DestinationPawn.m_bAuxParamNeedsSecondary, DestinationPawn.m_bAuxParamUse3POutline);
	}

	function ChangePerkTarget()
	{
		local XComUnitPawn CasterPawn;
		local int i;
		local array<XComPerkContent> Perks;

		if( ReanimatorAbilityState != none )
		{
			CasterPawn = XGUnit(`XCOMHISTORY.GetVisualizer(ReanimatorAbilityState.OwnerStateObject.ObjectID)).GetPawn();
			class'XComPerkContent'.static.GetAssociatedPerks(Perks, CasterPawn, ReanimatorAbilityState.GetMyTemplateName());

			for( i = 0; i < Perks.Length; ++i )
			{
				if (DoppelgangerUnitState.IsDead())
					Perks[i].RemovePerkTarget(OriginalUnit);
				else
					Perks[i].ReplacePerkTarget(OriginalUnit, DoppelgangerUnit);
			}
		}
	}
	
	function CopyPose()
	{
		local SkeletalMeshComponent OriginalPawnMesh, DoppelgangerPawnMesh;

		DoppelgangerUnit.GetPawn().SetLocation(OriginalUnit.GetPawn().Location);
		DoppelgangerUnit.GetPawn().SetRotation(OriginalUnit.GetPawn().Rotation);

		OriginalPawnMesh = OriginalUnit.GetPawn().Mesh;
		DoppelgangerPawnMesh = DoppelgangerUnit.GetPawn().Mesh;
		DoppelgangerPawnMesh.SetTranslation(OriginalPawnMesh.Translation);

		DoppelgangerUnit.GetPawn().EnableFootIK(false);

		AnimParams.AnimName = 'Pose';
		AnimParams.Looping = true;
		AnimParams.BlendTime = 0.0f;
		AnimParams.HasPoseOverride = true;
		AnimParams.Pose = OriginalUnit.GetPawn().Mesh.LocalAtoms;

		DoppelgangerUnit.GetPawn().bSkipIK = true;
		DoppelgangerUnit.GetPawn().GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
	}

	private function float GetAnimationDelay()
	{
		local float RandTimeAmount;

		RandTimeAmount = 0.0f;
		if( (StartAnimationMinDelaySec >= 0.0f) &&
		   (StartAnimationMaxDelaySec > 0.0f) &&
		   (StartAnimationMinDelaySec < StartAnimationMaxDelaySec) )
		{
			RandTimeAmount = StartAnimationMinDelaySec + (`SYNC_FRAND() * (StartAnimationMaxDelaySec - StartAnimationMinDelaySec));
		}

		return RandTimeAmount;
	}

Begin:

	// Copy appearance of OriginalUnit to RanimatedUnit
	if( ShouldCopyAppearance )
	{
		CopyAppearance(OriginalUnit.GetPawn(), DoppelgangerUnit.GetPawn());
	}

	while( bWaitForOriginalUnitMessage && !bReceivedStartMessage)
	{
		Sleep(0.1f);
	}

	if( bReplacingOriginalUnit )
	{
		if (!bIgnorePose)
		{
			// Wait for the Original units ragdoll to complete (but not forever, don't let this hang us!)
			if( (StartAnimationMaxDelaySec > 0) && (StartAnimationMinDelaySec > 0) )
			{
				Sleep(GetAnimationDelay() * GetDelayModifier());
			}

			DoppelgangerUnit.GetPawn().EnableRMA(true, true);
			DoppelgangerUnit.GetPawn().EnableRMAInteractPhysics(true);

			// Then copy all the bone transforms so we match his pose
			CopyPose();
		}

		// Time to actually show the unit
		OriginalUnit.m_bForceHidden = true;
		CurrentTile = `XWORLD.GetTileCoordinatesFromPosition(OriginalUnit.Location);
		`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.VisualizerUpdateVisibility(OriginalUnit, CurrentTile);
	}

	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(bAllowNewAnimationsOnDoppelganger);

	DoppelgangerUnit.m_bForceHidden = false;
	CurrentTile = `XWORLD.GetTileCoordinatesFromPosition(DoppelgangerUnit.Location);
	`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.VisualizerUpdateVisibility(DoppelgangerUnit, CurrentTile);

	if( bReplacingOriginalUnit )
	{
		ChangePerkTarget();
	}

	CompleteAction();
}

function CompleteAction()
{
	if (!bIgnorePose)
	{
		DoppelgangerUnit.GetPawn().EnableFootIK(true);
		DoppelgangerUnit.GetPawn().EnableRMA(false, false);
		DoppelgangerUnit.GetPawn().EnableRMAInteractPhysics(false);
	}

	super.CompleteAction();
}

DefaultProperties
{
	ShouldCopyAppearance = true;
	TimeoutSeconds=30
	bWaitForOriginalUnitMessage=false
	bReceivedStartMessage=false
	bAllowNewAnimationsOnDoppelganger=true
	bReplacingOriginalUnit=true
	bCauseTimeDilationWhenInterrupting = true
}