
class XComCable extends Actor
	inherits(FTickableObject)
	placeable
	native(Level);

var (Cable)	    const XComCablePoint PointA;
var (Cable)	    const XComCablePoint PointB;
var (Cable)	    const SkeletalMesh  CableMesh;
var (Cable)	    name BoneAName;
var (Cable)	    name BoneBName;
var (Cable)	    name MidBoneName;
var (Cable)     const float Droop;
var (Cable)     const float SwayDistance;
var (Cable)     const float SwaySpeed;
var (Cable)     const float SwayOffset;

var (Cable) SkeletalMeshComponent CableMeshComponent;
var int AnimBoneIndex;
var int BoneAIndex;
var int BoneBIndex;
var float SwayTimer;

cpptext
{
	// Actor interface
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);
	virtual void PostLoad();

	// Internals
	void CacheBoneIndices();
	void UpdateBones();
	UBOOL HasValidBoneCache();
	void UpdateSway(FLOAT DeltaTime=0.0f);

	// FTickableObject
	virtual void Tick(FLOAT DeltaTime);
	virtual UBOOL IsTickable() const
	{
		// We cannot tick objects that are unreachable or are in the process of being loaded in the background.
		return !HasAnyFlags( RF_Unreachable | RF_AsyncLoading );
	}

	virtual UBOOL IsTickableWhenPaused() const
	{
		return FALSE;
	}
}

defaultproperties
{
	CableMesh = SkeletalMesh'EXT_PROP_Powerlines.Meshes.SM_PROP_Powerline'
	AnimBoneIndex = -1
	BoneAIndex = -1
	BoneBIndex = -1

	Droop = 32
	SwayDistance = 16
	SwaySpeed = 1
	SwayOffset = 0
	SwayTimer = 0

	BoneAName = "b_endA"
	BoneBName = "b_endB"
	MidBoneName = "b_mid"

	Begin Object Class=SkeletalMeshComponent Name=SkeletalMeshComponent0
		SkeletalMesh=SkeletalMesh'EXT_PROP_Powerlines.Meshes.SM_PROP_Powerline'
		bUpdateSkelWhenNotRendered=FALSE
		bProcedurallyAnimated=FALSE // jboswell: native code flips this when it's time
		bUseAsOccluder=FALSE
	End Object
	Components.Add(SkeletalMeshComponent0);
	CableMeshComponent = SkeletalMeshComponent0;

	bStatic = true
}