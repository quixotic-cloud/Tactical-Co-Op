class XComTutorialRoomBorder extends StaticMeshActor 
	placeable; 

var MaterialInstanceConstant MIC;
var bool bPulsing;
var float CurrentPulseTime;
var float MaxPulseTime;
var LinearColor BorderColor;
var float ChokeAmount;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();

	StaticMeshComponent.SetHidden(true);
	
	MIC = MaterialInstanceConstant(StaticMeshComponent.GetMaterial(0));
	if( MIC == none )
		MIC = StaticMeshComponent.CreateAndSetMaterialInstanceConstant(0);

	MIC.SetVectorParameterValue('TintColor', BorderColor);
	MIC.SetScalarParameterValue('EmissiveBoost', 1.0);
	MIC.SetScalarParameterValue('ChokeAmount', ChokeAmount); // Controls thickness
}

simulated function OnToggle(SeqAct_Toggle Action)
{
	// Turn ON
	if (Action.InputLinks[0].bHasImpulse)
	{
		bPulsing=true;
	}
	// Turn OFF
	else if (Action.InputLinks[1].bHasImpulse)
	{
		bPulsing=false;
	}
	// Toggle
	else if (Action.InputLinks[2].bHasImpulse)
	{
		bPulsing = !bPulsing;
	}

	SetPulsing(bPulsing);
}

function SetPulsing(bool bEnabled)
{
	StaticMeshComponent.SetHidden(!bEnabled);
	CurrentPulseTime = 0.0;
}

function Tick(float DeltaTime)
{	
	local float PulseTime;

	super.Tick(DeltaTime);

	if (bPulsing)
	{
		CurrentPulseTime += DeltaTime;

		if( CurrentPulseTime >= MaxPulseTime)
		{
			CurrentPulseTime = CurrentPulseTime - MaxPulseTime;
		}

		PulseTime = Sin(CurrentPulseTime * PI / MaxPulseTime);

		MIC.SetScalarParameterValue('EmissiveBoost', PulseTime * 1.5f);
	}
}

defaultproperties
{
	ChokeAmount=6.0
	MaxPulseTime=1.0
	BorderColor=(R=0.14,G=0.81,B=0.85,A=1.0)

	Begin Object Name=StaticMeshComponent0
		HiddenGame=TRUE
		BlockRigidBody=TRUE
		WireframeColor=(R=193,G=255,B=6,A=255)
		StaticMesh=StaticMesh'HQ_RoomBorderFX.Meshes.RoomBorderGlowRing'
		bForceDirectLightMap=false
		bReceiverOfDecalsEvenIfHidden=TRUE // Prevent decals getting deleted when hiding this actor through building vis system.
		CanBlockCamera=true
	End Object

	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.Spline.T_Loft_Spline'
		HiddenGame=True
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		SpriteCategoryName="Misc"
		Scale=0.3
	End Object
	Components.Add(Sprite)

	bTickIsDisabled=false
	bStatic=false // TODO: is there other stuff we need?
	bStaticCollision=true;
	bNoDelete=false
	bMovable=false
	bWorldGeometry=true
	bPathColliding=true
	bCollideActors=TRUE
	bBlockActors=true
	bConsiderAllStaticMeshComponentsForStreaming=true;
}
