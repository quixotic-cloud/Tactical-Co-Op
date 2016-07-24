class XComSkelControlLimb_LeftHandIK extends SkelControlLimb
	native;

cpptext
{
	virtual void CalculateNewBoneTransforms(INT BoneIndex, USkeletalMeshComponent* SkelComp, TArray<FBoneAtom>& OutBoneTransforms);
}

DefaultProperties
{
}
