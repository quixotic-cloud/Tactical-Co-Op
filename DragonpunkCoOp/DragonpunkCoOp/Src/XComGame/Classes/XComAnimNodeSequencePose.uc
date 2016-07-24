class XComAnimNodeSequencePose extends AnimNodeSequence
	native(Animation);

var init Array<BoneAtom> Pose;

cpptext
{
	virtual void GetAnimationPose(UAnimSequence* InAnimSeq, INT& InAnimLinkupIndex, FBoneAtomArray& Atoms, const TArray<BYTE>& DesiredBones, FBoneAtom& RootMotionDelta, INT& bHasRootMotion, FCurveKeyArray& CurveKeys);
	virtual	void TickAnim(FLOAT DeltaSeconds);
}

defaultproperties
{
	CategoryDesc = "Firaxis"
}