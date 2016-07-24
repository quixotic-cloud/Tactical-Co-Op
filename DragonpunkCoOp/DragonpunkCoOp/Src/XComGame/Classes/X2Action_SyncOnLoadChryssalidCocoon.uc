//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_SyncOnLoadChryssalidCocoon extends X2Action;


var XComGameState_Unit OriginalUnitState;

var private CustomAnimParams AnimParams;
var private XGUnit OriginalUnit;
var private bool bSavedAllowNewAnims;

var private Rotator SavedRotation;
var private vector SavedLocation, SavedTranslation;
var private AnimNodeSequence PlayingSequence;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
	if( (OriginalUnit == None && OriginalUnitState != None) )
	{
		OriginalUnit = XGUnit(OriginalUnitState.GetVisualizer());
	}
}

function ForceImmediateTimeout()
{
	// Do nothing. We want the ragdoll to finish.
}

simulated state Executing
{
	function CopyAnimSetsFromOriginal(bool bClearAnimSets=false)
	{
		local XComChryssalidCocoon CocoonPawn;
		local int i;

		CocoonPawn = XComChryssalidCocoon(UnitPawn);
		if( CocoonPawn != none )
		{
			CocoonPawn.OriginalUnitPawnAnimSets.Length = 0;

			if( !bClearAnimSets )
			{
				for( i = 0; i < OriginalUnit.GetPawn().Mesh.AnimSets.Length; ++i)
				{
					CocoonPawn.OriginalUnitPawnAnimSets.AddItem(OriginalUnit.GetPawn().Mesh.AnimSets[i]);
				}
			}

			CocoonPawn.UpdateAnimations();
		}
	}

	function SavePose()
	{
		SavedLocation = UnitPawn.Location;
		SavedRotation = UnitPawn.Rotation;
		SavedTranslation = UnitPawn.Mesh.Translation;

		AnimParams.AnimName = 'Pose';
		AnimParams.Looping = true;
		AnimParams.BlendTime = 0.0f;
		AnimParams.HasPoseOverride = true;
		AnimParams.Pose = UnitPawn.Mesh.LocalAtoms;
	}

	function CopyPose()
	{
		UnitPawn.SetLocation(SavedLocation);
		UnitPawn.SetRotation(SavedRotation);
		UnitPawn.Mesh.SetTranslation(SavedTranslation);

		UnitPawn.EnableFootIK(false);

		UnitPawn.bSkipIK = true;

		UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
	}

Begin:

	bSavedAllowNewAnims = UnitPawn.GetAnimTreeController().GetAllowNewAnimations();

	CopyAnimSetsFromOriginal();

	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
	AnimParams.AnimName = 'HL_GetUp';
	AnimParams.BlendTime = 0.0f;
	UnitPawn.bSkipIK = true;
	PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);

	Sleep(0.0f);
	SavePose();
	CopyPose();

	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(bSavedAllowNewAnims);

	CompleteAction();
}