class XComAnimNodeSequenceAdditive extends AnimNodeSequence
	native(Animation);

cpptext
{
	virtual void GetAnimationPose(UAnimSequence* InAnimSeq, INT& InAnimLinkupIndex, FBoneAtomArray& Atoms, const TArray<BYTE>& DesiredBones, FBoneAtom& RootMotionDelta, INT& bHasRootMotion, FCurveKeyArray& CurveKeys);
}

defaultproperties
{
	CategoryDesc = "Firaxis"
}