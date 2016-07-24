
class SeqAct_CustomUnitFlag extends SequenceAction;

var XComHumanPawn UnitPawn;
var StaticMeshComponent AttachedMeshComponent;
var vector MeshTranslation;
var rotator MeshRotation;
var vector MeshScale;

var() TextureMovie MovieTexture;
var() Material FlagMaterial;
var() StaticMesh MeshToAttach;

event Activated()
{
	local XComTacticalController kTacticalController;

	if (UnitPawn != none && MeshToAttach != none && FlagMaterial != none && MovieTexture != none)
	{
		kTacticalController = GetPC();

		if (InputLinks[0].bHasImpulse)
		{
			XComPresentationLayer(kTacticalController.Pres).m_kUnitFlagManager.Hide();
			AttachedMeshComponent = new(self) class'StaticMeshComponent';
			AttachedMeshComponent.SetAbsolute(false, true, false);
			AttachedMeshComponent.SetRotation(MeshRotation);
			AttachedMeshComponent.SetTranslation(MeshTranslation);
			AttachedMeshComponent.SetScale3D(MeshScale);
			AttachedMeshComponent.SetStaticMesh(MeshToAttach, true);
			AttachedMeshComponent.SetMaterial(0, FlagMaterial);
			UnitPawn.AttachComponent(AttachedMeshComponent);
		}
		else if (InputLinks[1].bHasImpulse)
		{
			XComPresentationLayer(kTacticalController.Pres).m_kUnitFlagManager.Show();
			UnitPawn.DetachComponent(AttachedMeshComponent);
		}
		else if (InputLinks[2].bHasImpulse)
		{
			HandleMovie(true);
		}
		else if (InputLinks[3].bHasImpulse)
		{
			HandleMovie(false);
		}
	}
}

function HandleMovie(bool bPlay)
{
	local XComTacticalController kTacticalController;
	local EMovieControlType Mode;

	if (MovieTexture != None)
	{
		if (bPlay)
		{
			Mode = MCT_Play;
		}
		else
		{
			Mode = MCT_Stop;
		}

		kTacticalController = GetPC();
		kTacticalController.ClientControlMovieTexture(MovieTexture, Mode);
	}
}

function XComTacticalController GetPC()
{
	local XComTacticalController kTacticalController;

	foreach GetWorldInfo().AllControllers(class'XComTacticalController', kTacticalController)
	{
		break;
	}

	return kTacticalController;
}

defaultproperties
{
	ObjCategory="Unit"
	ObjName="Custom Unit Flag"
	bCallHandler=false

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="UnitPawn",PropertyName=UnitPawn)

	InputLinks(0)=(LinkDesc="Attach")
	InputLinks(1)=(LinkDesc="Detach")
	InputLinks(2)=(LinkDesc="Play")
	InputLinks(3)=(LinkDesc="Stop")

	MeshRotation=(Roll=8192,Yaw=-7281)
	MeshTranslation=(X=60.0,Y=-35.0,Z=-25.0)
	MeshScale=(X=2.0,Y=1.5,Z=1.0)
}
