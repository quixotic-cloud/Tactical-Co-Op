class X2Actor_ConeTarget extends Actor;

var protected StaticMeshComponent MeshComp;
var string MeshLocation;

function InitConeMesh(float Length, float Width)
{
	local StaticMesh ConeMesh;
	local MaterialInstanceConstant MIC;

	ConeMesh = StaticMesh(`CONTENT.RequestGameArchetype(MeshLocation));
	`assert(ConeMesh != none);
	MeshComp.SetStaticMesh(ConeMesh);

	MIC = MaterialInstanceConstant(MeshComp.GetMaterial(0));
	MIC.SetScalarParameterValue('RangeLengthScale', Length);
	MIC.SetScalarParameterValue('RangeWidthScale', Width);
}

function UpdateLengthScale(float NewLength)
{
	local MaterialInstanceConstant MIC;

	MIC = MaterialInstanceConstant(MeshComp.GetMaterial(0));
	MIC.SetScalarParameterValue('RangeLengthScale', NewLength);
}

DefaultProperties
{
	Begin Object Class=StaticMeshComponent Name=DefaultMeshComp
		bOwnerNoSee = FALSE
		CastShadow = FALSE
		CollideActors = FALSE
		BlockActors = FALSE
		BlockZeroExtent = FALSE
		BlockNonZeroExtent = FALSE
		BlockRigidBody = FALSE
		HiddenGame = FALSE
	End Object
	Components.Add(DefaultMeshComp)

	MeshComp = DefaultMeshComp;

	MeshLocation = "UI_3D.Targeting.ConeRange_Neutral";
}