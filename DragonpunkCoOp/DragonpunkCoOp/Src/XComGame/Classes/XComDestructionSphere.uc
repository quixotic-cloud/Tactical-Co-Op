class XComDestructionSphere extends Actor
	  placeable
	  native(Core);

var() const int UnitDamageAmount;
var() const int DamageAmount;
var() ParticleSystemComponent BlastRadiusComponent;
var() int DamageRadiusTiles;

var privatewrite transient int ObjectID;

cpptext
{
#if WITH_EDITOR
	virtual void EditorApplyScale(const FVector& DeltaScale, const FMatrix& ScaleMatrix, const FVector* PivotLocation, UBOOL bAltDown, UBOOL bShiftDown, UBOOL bCtrlDown);
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);
#endif
}

simulated event PostBeginPlay()
{
	BlastRadiusComponent.SetScale(DamageRadiusTiles);
}

function SyncToGameState()
{
	local XComGameState_DestructionSphere StateObject;

	StateObject = class'XComGameState_DestructionSphere'.static.GetStateObject(self);

	if(StateObject != none)
	{
		BlastRadiusComponent.SetHidden(!StateObject.DamageSphereVisible);
	}
}

function Explode()
{
	local XComGameState_DestructionSphere StateObject;

	StateObject = class'XComGameState_DestructionSphere'.static.GetStateObject(self);
	
	if(StateObject != none)
	{
		ObjectID = StateObject.ObjectID;
		StateObject.Explode();
	}
}

defaultproperties
{
	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'LayerIcons.Editor.Chaos'
		HiddenGame=True
		Scale=0.3f
	End Object
	Components.Add(Sprite);

	Begin Object Class=ParticleSystemComponent Name=DestructionSphereComponent
		Template=ParticleSystem'UI_Range.Particles.BlastRadius_Shpere'
		bAutoActivate=true
		HiddenGame=true // hidden by default in game
	End Object
	BlastRadiusComponent=DestructionSphereComponent
	Components.Add(DestructionSphereComponent)

	bCollideWhenPlacing=false
	bCollideActors=false
	bStaticCollision=true
	bCanStepUpOn=false
	bEdShouldSnap=true

	UnitDamageAmount=10 
	DamageAmount=100
	DamageRadiusTiles=10
	ObjectID=-1
}