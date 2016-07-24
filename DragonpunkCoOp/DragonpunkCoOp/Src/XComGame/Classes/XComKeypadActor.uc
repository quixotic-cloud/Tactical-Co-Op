class XComKeypadActor extends XComInteractiveLevelActor
	placeable
	native(Destruction)
	deprecated;

var() SkeletalMeshComponent SkelMesh;
var() array<XComInteractiveLevelActor> arrLinkedDoors;
var() int iIntelCost;
var() bool bUnlocked;

defaultproperties
{
	Begin Object Name=SkeletalMeshComponent0
		SkeletalMesh=SkeletalMesh'HotButton.Meshes.HotButtonPanelHigh'
		HiddenEditor=true
		HiddenGame=true
	End Object
	Components.Add(SkeletalMeshComponent0)
	SkelMesh=SkeletalMeshComponent0

	IconSocket=XGBUTTON_Icon
	bMovable=true

	InteractionPoints[0]=(SrcSocket=XGBUTTON_01,Facing=eIF_Front)
	Begin Object Name=CoveringMeshComponent
		HiddenGame=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		BlockRigidBody=false
		CollideActors=false
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
		StaticMesh=StaticMesh'hqaslt_computer.Meshes.HQAsltComp_KeyPad'
	End Object

	Toughness=XComDestructibleActor_Toughness'GameData_Toughness.Toughness_METAL'

	Begin Object Class=XComDestructibleActor_Action_Hide Name=ActionHide
	End Object

	Begin Object Class=XComDestructibleActor_Action_PlayEffectCue Name=ActionEffectCue
	End Object

	Begin Object Class=XComDestructibleActor_Action_PlaySoundCue Name=ActionSoundCue
	End Object

	DamagedEvents[0]=(Action=ActionHide)
	DamagedEvents[1]=(Action=ActionEffectCue)
	DamagedEvents[2]=(Action=ActionSoundCue)

	DestroyedEvents[0]=(Action=ActionHide)
	DestroyedEvents[1]=(Action=ActionEffectCue)
	DestroyedEvents[2]=(Action=ActionSoundCue)

	bHiddenSkeletalMesh=true
}