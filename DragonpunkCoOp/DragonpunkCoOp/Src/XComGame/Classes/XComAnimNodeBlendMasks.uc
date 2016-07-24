class XComAnimNodeBlendMasks extends AnimNodeBlendBase
	native(Animation);

struct native BlendMask
{
	var() const bool        ForceLocalSpaceBlend;
	var() Name              BranchStartBoneName;
	var init Array<BYTE>    PerBoneMask;
	var init Array<BYTE>    ModelSpaceBones;

	// Dealing with weights
	var float           CurrentWeight;
	var() float         DesiredWeight;
	var float           CurrentBlendTime;
	var() float         TotalBlendTime;
	var float           StartingWeight;
	var bool            BlendOutAfterAnim;

	structcpptext
	{
		FBlendMask();
		FBlendMask(EEventParm);
	}
};

var() Array<BlendMask> BlendMasks;
var() bool ShouldLastMaskBlendAdditive;
var editoronly transient init Array<BlendMask> AvoidChanges;

native function SetBlendMaskWeight(int MaskIndex, float DesiredWeight, float BlendTime);
native function SetBlendMaskWeightForSingleAnim(int MaskIndex, float DesiredWeight, float BlendTime);
native function bool IsBlendMaskActive(int MaskIndex);

cpptext
{
	// Runtime Functions
	virtual void InitAnim(USkeletalMeshComponent* meshComp, UAnimNodeBlendBase* Parent);
	virtual	void TickAnim(FLOAT DeltaSeconds);
	virtual void GetBoneAtoms(FBoneAtomArray& Atoms, const TArray<BYTE>& DesiredBones, FBoneAtom& RootMotionDelta, INT& bHasRootMotion, FCurveKeyArray& CurveKeys);
	void CreatePerBoneMasks(); 

	// Editor Functions
	virtual void OnAddChild(INT ChildNum);
	virtual void OnRemoveChild(INT ChildNum);
	virtual void PreEditChange(UProperty* PropertyAboutToChange);
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);
}

defaultproperties
{
	ShouldLastMaskBlendAdditive = false;
	CategoryDesc = "Firaxis"
}