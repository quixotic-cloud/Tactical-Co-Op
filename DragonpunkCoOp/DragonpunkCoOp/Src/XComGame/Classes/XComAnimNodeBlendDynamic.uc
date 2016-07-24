class XComAnimNodeBlendDynamic extends AnimNodeBlendBase
	native(Animation);

struct native PlayingChild
{
	var BoneAtom    InitialStartingAtom;
	var BoneAtom    DesiredStartingAtom;
	var int			Index;
	var float		DesiredWeight;
	var float		TargetWeight;
	var float		CurrentBlendTime;
	var float		TotalBlendTime;
	var float		StartingWeight;
	var bool		HasFixup;
	var float       FixupBeginTime;
	var float       FixupEndTime;
};

struct native CustomAnimParams
{
	var Name					AnimName;
	var bool					Looping;
	var float					TargetWeight;
	var float					BlendTime;
	var float					PlayRate;
	var float					StartOffsetTime;
	var bool					Additive;
	var bool					ModifyAdditive;
	var bool					HasDesiredEndingAtom;
	var BoneAtom				DesiredEndingAtom;
	var bool					HasPoseOverride;
	var float					PoseOverrideDuration; //Allow the caller to specify a duration for pose override anims
	var init Array<BoneAtom>	Pose;
	
	structdefaultproperties
	{
		AnimName = "None";
		Looping = false;
		TargetWeight = 1.0f;
		BlendTime = 0.1f;
		PlayRate = 1.0f;
		StartOffsetTime = 0.0f;
		Additive = false;
		HasDesiredEndingAtom = false;
		DesiredEndingAtom = (Rotation=(X=0,Y=0,Z=0,W=1), Translation=(X=0,Y=0,Z=0), Scale=1);
		HasPoseOverride = false;
		PoseOverrideDuration = 0.0f;
	}

	structcpptext
	{
		FCustomAnimParams()
		{
			AnimName = FName(TEXT("None"));
			Looping = false;
			TargetWeight = 1.0f;
			BlendTime = 0.1f;
			PlayRate = 1.0f;
			StartOffsetTime = 0.0f;
			Additive = false;
			HasDesiredEndingAtom = false;
			DesiredEndingAtom.SetIdentity();
			HasPoseOverride = false;
			PoseOverrideDuration = 0.0f;
		}
		FCustomAnimParams(EEventParm)
		{
			appMemzero(this, sizeof(FCustomAnimParams));
		}
	}
};

var private init Array<PlayingChild> ChildrenPlaying;
var private bool ComputedFixupRootMotion;
var private BoneAtom FixedUpRootMotionDelta;
var private BoneAtom EstimatedCurrentAtom;
var private bool Additive;

native function AnimNodeSequence PlayDynamicAnim(out CustomAnimParams Params);
native function bool BlendOutDynamicAnim(AnimNodeSequence PlayingSequence, float BlendTime);
native function AnimNodeSequence GetTerminalSequence();
native function SetAdditive(bool TreatAsAdditive); // This is so we know to use identity for the weight filler instead of reference pose

cpptext
{
public:
	static FName FindRandomAnimMatchingName(FName AnimName, USkeletalMeshComponent* SkelComp);
	static TArray<FName> GetAllPossibleAnimNames(FName AnimName, USkeletalMeshComponent* SkelComp);
	static UBOOL CanPlayAnimation(FName AnimName, UBOOL SearchAnimName, USkeletalMeshComponent* SkelComp);
	virtual void RootMotionProcessed();
	virtual UAnimNodeSequence* GetAnimNodeSequence();
private:
	virtual void InitAnim(USkeletalMeshComponent* meshComp, UAnimNodeBlendBase* Parent);
	virtual	void TickAnim(FLOAT DeltaSeconds);
	virtual void GetBoneAtoms(FBoneAtomArray& Atoms, const TArray<BYTE>& DesiredBones, FBoneAtom& RootMotionDelta, INT& bHasRootMotion, FCurveKeyArray& CurveKeys);
	void CalculateWeights();
	FBoneAtom CalculateDesiredAtom(const UAnimNodeSequence* AnimNodeSeq, const FBoneAtom& StartLocation);
	FBoneAtom CalculateDesiredStartingAtom(const UAnimNodeSequence* AnimNodeSeq, const FBoneAtom& DesiredEndingAtom);
	INT CreateBlankBlendChild(FCustomAnimParams& AnimParams);
	
	// Editor Functions
	virtual void OnAddChild(INT ChildNum);
}

defaultproperties
{
	bFixNumChildren = TRUE
	CategoryDesc = "Firaxis"
	Additive = FALSE
}