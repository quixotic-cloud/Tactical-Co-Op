//
// Script wrapper for SimpleShapeManager system
// See FxsUtilClasses.h
// - Jason/tomw
//

class SimpleShapeManager extends Actor;

struct ShapePair
{
	var bool bDestroy;
	var bool bPersistent;
	var DynamicSMActor_Spawnable Shape;
};

var array<ShapePair> mShapes;

private function ShapePair AddShape(StaticMesh StaticMesh, bool bPersistent)
{
	local int index, i;
	local ShapePair tempPair;

	//search for equivalent static mesh actor
	index = -1;
	for(i = 0; (i < mShapes.Length) && (index == -1); i++)
	{
		if(mShapes[i].bDestroy && (mShapes[i].Shape.StaticMeshComponent.StaticMesh == StaticMesh))
		{
			index = i;
		}
	}
	
	//create new one
	if(index == -1)
	{
		index = mShapes.Length;
		tempPair.Shape = Spawn(class'DynamicSMActor_Spawnable',,,,);
		tempPair.Shape.StaticMeshComponent.SetStaticMesh(StaticMesh);
		tempPair.Shape.StaticMeshComponent.CreateAndSetMaterialInstanceConstant(0);
		tempPair.Shape.SetCollision(false, false, false);
		mShapes[index] = tempPair;
	}

	mShapes[index].bDestroy = false;
	mShapes[index].bPersistent = bPersistent;
	return mShapes[index];
}

function DrawSphere(vector Position, vector Scale3D, optional LinearColor c = MakeLinearColor(1, 1, 1, 1), optional bool bPersistent = false)
{
	local ShapePair tempPair;
	tempPair = AddShape(StaticMesh'SimpleShapes.ASE_UnitSphere', bPersistent);
	tempPair.Shape.SetLocation(Position);
	tempPair.Shape.SetDrawScale3D(Scale3D);
	MaterialInstance(tempPair.Shape.StaticMeshComponent.GetMaterial(0)).SetVectorParameterValue('Color', c);	// MHU - transparency channel ignored in this branch of the shader
	MaterialInstance(tempPair.Shape.StaticMeshComponent.GetMaterial(0)).SetScalarParameterValue('Alpha', c.A);  //     - Actually apply the transparency

	tempPair.Shape.SetCollision(false, false, true);
	tempPair.Shape.StaticMeshComponent.SetTraceBlocking(false, false);
}

function DrawBox(vector Position, vector Scale3D, optional LinearColor c = MakeLinearColor(1, 1, 1, 1), optional bool bPersistent = false)
{
	local ShapePair tempPair;
	tempPair = AddShape(StaticMesh'SimpleShapes.ASE_UnitCube', bPersistent);
	tempPair.Shape.SetLocation(Position);
	tempPair.Shape.SetDrawScale3D(Scale3D);
	MaterialInstance(tempPair.Shape.StaticMeshComponent.GetMaterial(0)).SetVectorParameterValue('Color', c);
	tempPair.Shape.SetCollision(false, false, true);
	tempPair.Shape.StaticMeshComponent.SetTraceBlocking(false, false);
}

function DrawTile(const out TTile Tile, byte ColorR, byte ColorG, byte ColorB, optional float Scale = 1.0f, optional bool bPersistent = true)
{
	local Vector DrawDebugBoxExtents;
	local Vector DrawDebugBoxCenter;

	DrawDebugBoxExtents.X = class'XComWorldData'.const.WORLD_HalfStepSize;
	DrawDebugBoxExtents.Y = class'XComWorldData'.const.WORLD_HalfStepSize;
	DrawDebugBoxExtents.Z = class'XComWorldData'.const.WORLD_HalfFloorHeight;

	DrawDebugBoxCenter = `XWORLD.GetPositionFromTileCoordinates(Tile);
	class'WorldInfo'.static.GetWorldInfo().DrawDebugBox(DrawDebugBoxCenter, DrawDebugBoxExtents * Scale, ColorR, ColorG, ColorB, bPersistent);
}


function DrawCylinder(vector Start, vector End, float Radius, optional LinearColor c = MakeLinearColor(1, 1, 1, 1), optional float FlattenScale = 1.0, optional bool bPersistent = false)
{
	local array<float> arrTransitions;
	local array<LinearColor> arrColors;
	arrTransitions[0] = 0;
	arrColors[0] = c;
	DrawMultiCylinder(Start, End, Radius, arrTransitions, arrColors, false, FlattenScale, bPersistent);
}

function DrawMultiCylinder(vector Start, vector End, float Radius, array<float> arrTransitions, array<LinearColor> arrColors, optional bool bBlendColors = true, optional float FlattenScale = 1.0, optional bool bPersistent = false)
{
	local ShapePair tempPair;
	local vector Direction, Scale3D;
	local Rotator MyRotation, FirstRotation;
	local MaterialInstance MInst;
	
	Direction = End - Start;
	Scale3D.X = Radius * FlattenScale;
	Scale3D.Y = Radius;
	Scale3D.Z = VSize(Direction);
	MyRotation = Rotator(Direction);
	FirstRotation = Rotator(vect(0, 0, -1));
	
	tempPair = AddShape(StaticMesh'SimpleShapes.ASE_UnitCylinder', bPersistent);
	tempPair.Shape.SetLocation((Start + End) / 2);
	tempPair.Shape.SetDrawScale3D(Scale3D);
	tempPair.Shape.SetRotation(MyRotation + FirstRotation);
	MInst = MaterialInstance(tempPair.Shape.StaticMeshComponent.GetMaterial(0));
	UpdateMultiMaterial(MInst, arrTransitions, arrColors, MakeLinearColor(1, 1, 0, 0), bBlendColors, false);
	tempPair.Shape.SetCollision(false, false, true);
	tempPair.Shape.StaticMeshComponent.SetTraceBlocking(false, false);
}

function DrawLine(vector Start, vector End, float Thickness, optional LinearColor c = MakeLinearColor(1, 1, 1, 1), optional float FlattenScale = 1.0, optional bool bPersistent = false)
{
	DrawCylinder(Start, End, Thickness / 2, c, FlattenScale, bPersistent);
}

function DrawCone(vector Start, vector End, float Theta, optional LinearColor c = MakeLinearColor(1, 1, 1, 1), optional float FlattenScale = 1.0, optional bool bPersistent = false, optional bool bSweepAnimation = false)
{
	local array<float> arrTransitions;
	local array<LinearColor> arrColors;
	arrTransitions[0] = 0;
	arrColors[0] = c;
	DrawMultiCone(Start, End, Theta, arrTransitions, arrColors, false, FlattenScale, bPersistent, bSweepAnimation);
}

function DrawMultiCone(vector Start, vector End, float Theta, array<float> arrTransitions, array<LinearColor> arrColors, optional bool bBlendColors = true, optional float FlattenScale = 1.0, optional bool bPersistent = false, optional bool bSweepAnimation = false)
{
	local ShapePair tempPair;
	local vector Direction, Scale3D;
	local Rotator MyRotation, FirstRotation;
	local MaterialInstance MInst;
	
	Direction = End - Start;
	Scale3D.Z = VSize(Direction);
	Scale3D.Y = Scale3D.Z * tan(Theta / 2);
	Scale3D.X = Scale3D.Y * FlattenScale;
	MyRotation = Rotator(Direction);
	FirstRotation = Rotator(vect(0, 0, 1));
	
	tempPair = AddShape(StaticMesh'SimpleShapes.ASE_UnitCone', bPersistent);
	tempPair.Shape.SetLocation(End);
	tempPair.Shape.SetDrawScale3D(Scale3D);
	tempPair.Shape.SetRotation(MyRotation + FirstRotation);
	MInst = MaterialInstance(tempPair.Shape.StaticMeshComponent.GetMaterial(0));
	UpdateMultiMaterial(MInst, arrTransitions, arrColors, MakeLinearColor(0, 0, 1, 0), bBlendColors, bSweepAnimation);
	tempPair.Shape.SetCollision(false, false, true);
	tempPair.Shape.StaticMeshComponent.SetTraceBlocking(false, false);
}

function UpdateMultiMaterial(MaterialInstance MInst, array<float> arrTransitions, array<LinearColor> arrColors, LinearColor PositionMask, bool bBlendColors, bool bSweepAnimation)
{
	local array<float> tempTransitions;
	local array<LinearColor> tempColors;
	local LinearColor tmpCol;
	local int i;
	
	for(i=0;i<arrTransitions.Length;i++)
		tempTransitions[i] = arrTransitions[i];
	while(tempTransitions.Length < 4)
		tempTransitions.AddItem(tempTransitions[tempTransitions.Length - 1]);

	for(i=0;i<arrColors.Length;i++)
		tempColors[i] = arrColors[i];
	while(tempColors.Length < 4)
		tempColors.AddItem(tempColors[tempColors.Length - 1]);

	if(tempTransitions.Length > 4 || tempColors.Length > 4)
		`log("SimpleShapes can only handle 4 colors");

	MInst.SetVectorParameterValue('Color0', tempColors[0]);
	MInst.SetVectorParameterValue('Color1', tempColors[1]);
	MInst.SetVectorParameterValue('Color2', tempColors[2]);
	MInst.SetVectorParameterValue('Color3', tempColors[3]);

	tmpCol = MakeLinearColor(tempTransitions[0], tempTransitions[1], tempTransitions[2], tempTransitions[3]);
	MInst.SetVectorParameterValue('Transitions0', tmpCol);
	MInst.SetVectorParameterValue('PositionMask', PositionMask);
	MInst.SetScalarParameterValue('SmoothBlend', bBlendColors ? 1 : 0);
	MInst.SetScalarParameterValue('SweepAnimation', bSweepAnimation ? 1 : 0);
}

function FlushPersistentShapes()
{
	local int i;
	for(i = 0; i < mShapes.Length; i++)
	{
		if(mShapes[i].bPersistent)
		{
			mShapes[i].bPersistent = false;
			mShapes[i].bDestroy = true;
		}
	}
}

function Tick(float fDeltaTime)
{
	local int i;
	for(i = mShapes.Length - 1; i >= 0; i--)
	{
		if(mShapes[i].bDestroy)
		{
			mShapes[i].Shape.Destroy();
			mShapes.Remove(i, 1);
		}
		else if(!mShapes[i].bPersistent)
		{
			mShapes[i].bDestroy = true;
		}
	}
}

//----------------------------------------------------------
function DynamicSMActor_Spawnable CreateCone( Vector vEnd, Vector vStart, float fRadius, float fHeight, Color clrCone )
{
	local DynamicSMActor_Spawnable kCone;
	local vector vDirection, vScale;
	local Rotator MyRotation, FirstRotation;
	local MaterialInstance MInst;
	local LinearColor clrLinear;

	// Spawn the Cone mesh
	kCone = Spawn(class'DynamicSMActor_Spawnable',,,,);
	kCone.StaticMeshComponent.SetStaticMesh(StaticMesh'SimpleShapes.ASE_UnitCone');
	kCone.StaticMeshComponent.CreateAndSetMaterialInstanceConstant(0);
	kCone.SetCollision(false, false, false);
	
	// Set the size and rotation of the Cone
	vDirection = vEnd - vStart;
	vScale.Z = VSize(vDirection);
	vScale.Y = fRadius;
	vScale.X = fHeight; // 1.0 to make flat
	MyRotation = Rotator(vDirection);
	FirstRotation = Rotator(vect(0, 0, 1));

	// Set the color of the Cone
	clrLinear = ColorToLinearColor(clrCone);
	MInst = MaterialInstance(kCone.StaticMeshComponent.GetMaterial(0));
	MInst.SetVectorParameterValue('Color0', clrLinear);
	MInst.SetVectorParameterValue('Color1', clrLinear);
	MInst.SetVectorParameterValue('Color2', clrLinear);
	MInst.SetVectorParameterValue('Color3', clrLinear);
	clrLinear = MakeLinearColor(0,0,0,0);
	MInst.SetVectorParameterValue('Transitions0', clrLinear);
	clrLinear =  MakeLinearColor(0,0,1,0);
	MInst.SetVectorParameterValue('PositionMask', clrLinear);

	//MInst.SetScalarParameterValue('SweepAnimation', 1 ); - Turn on sweep animation...

	// Set the location of the Cone
	kCone.SetLocation( vEnd );
	kCone.SetDrawScale3D(vScale);
	kCone.SetRotation(MyRotation + FirstRotation);
	
	kCone.SetCollision(false, false, true);
	kCone.StaticMeshComponent.SetTraceBlocking(false, false);

	return kCone;
}
//----------------------------------------------------------
// Create a cylinder shape oriented along the up axis
function DynamicSMActor_Spawnable CreateCylinder( Vector vCenter, float fRadius, float fHeight, Color clrCylinder )
{
	local DynamicSMActor_Spawnable kCylinder;
	local vector vDirection, vScale;
	local Rotator MyRotation, FirstRotation;
	local MaterialInstance MInst;
	local LinearColor clrLinear;

	// Spawn the cylinder mesh
	kCylinder = Spawn(class'DynamicSMActor_Spawnable',,,,);
	kCylinder.StaticMeshComponent.SetStaticMesh(StaticMesh'SimpleShapes.ASE_UnitCylinder');
	kCylinder.StaticMeshComponent.CreateAndSetMaterialInstanceConstant(0);
	kCylinder.SetCollision(false, false, false);
	
	// Set the size and rotation of the cylinder
	vDirection.X = 0;vDirection.Y = 0;vDirection.Z = fHeight;
	vScale.X = fRadius;
	vScale.Y = fRadius;
	vScale.Z = fHeight;
	MyRotation = Rotator(vDirection);
	FirstRotation = Rotator(vect(0, 0, -1));

	// Set the color of the cylinder
	clrLinear = ColorToLinearColor(clrCylinder);
	MInst = MaterialInstance(kCylinder.StaticMeshComponent.GetMaterial(0));
	MInst.SetVectorParameterValue('Color0', clrLinear);
	MInst.SetVectorParameterValue('Color1', clrLinear);
	MInst.SetVectorParameterValue('Color2', clrLinear);
	MInst.SetVectorParameterValue('Color3', clrLinear);
	clrLinear = MakeLinearColor(0,0,0,0);
	MInst.SetVectorParameterValue('Transitions0', clrLinear);
	clrLinear =  MakeLinearColor(0,0,1,0);
	MInst.SetVectorParameterValue('PositionMask', clrLinear);
	

	// Set the location of the cylinder
	vCenter.Z += fHeight/2;
	kCylinder.SetLocation( vCenter );
	kCylinder.SetDrawScale3D(vScale);
	kCylinder.SetRotation(MyRotation + FirstRotation);
	
	kCylinder.SetCollision(false, false, true);
	kCylinder.StaticMeshComponent.SetTraceBlocking(false, false);

	return kCylinder;
}

DefaultProperties
{

}
