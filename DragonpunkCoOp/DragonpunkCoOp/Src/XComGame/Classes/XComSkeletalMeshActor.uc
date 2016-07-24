class XComSkeletalMeshActor extends SkeletalMeshActor
	placeable;

var() const editconst XComFloorComponent FloorComponent;
var() VisibilityBlocking VisibilityBlockingData;

var() bool bEnableXComPhysicsSetup;

simulated event PostBeginPlay()
{
	local RenderChannelContainer RenderChannels;
	super.PostBeginPlay();
	RenderChannels = SkeletalMeshComponent.RenderChannels;
	RenderChannels.UnitVisibility = VisibilityBlockingData.bBlockUnitVisibility;
	SkeletalMeshComponent.SetRenderChannels(RenderChannels);

	if (bEnableXComPhysicsSetup)
	{
		SkeletalMeshComponent.BodyInstance.SetFixed(false);
		SkeletalMeshComponent.PhysicsWeight = 1.0f;
	}
}

defaultproperties
{
	Begin Object Class=XComFloorComponent Name=FloorComponent0
	End Object
	FloorComponent=FloorComponent0
	Components.Add(FloorComponent0)

	bCollideActors=TRUE
	bWorldGeometry=TRUE
}