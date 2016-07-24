class XcomTriggerActor extends XComLevelActor;

var MeshComponent Mesh;
var MaterialInstanceConstant MatInst;
var float HitStrength;


var float ParamStep;

var float TargetValue;
var float TargetValue2;

var XComPawn A;
var XComPawn A2;
var XComTriggerActor XTA;


var array<Actor> TouchHistory;


var int ActorsTouchingThisTick;
var int RustleStrength;
var float RustleSpeed;
var int RustleIndex;
var int XPIndex;

var float RustleParam;

var vector HitAngle;
var vector HitLoc;

var vector OtherPointing;
var vector OtherWorldLoc;


var() int RustleRadius;
//var() int RustleTimer;
//var() int RustleMult;
//var() int ParamStep_Idle;
//var() int ParamStep_Touching;
var() bool UpdateTouchLocEveryTick;


auto state Idling
{   
begin:
	TargetValue = 0;
	TargetValue2 = (0 + RustleStrength);
	ParamStep = (0.08+ RustleSpeed);

}

state IsTouching
{

begin:

	TargetValue= 1;
	TargetValue2= (0 + RustleStrength);
	ParamStep= (0.3 + RustleSpeed);

}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
	
	XPIndex = 0;
	//Only respond to XComPawn
	ForEach TouchingActors(class'XComPawn',A2)
		{

			//XPIndex +=1;
			Rustle();
			if (UpdateTouchLocEveryTick == false)
			{
				//create vector pointing from the touching actor to the actor origin
				OtherPointing = Normal(A2.Location - self.Location);
				UpdateMaterialInstanceV(OtherPointing,"OtherPointing");
				//pass world location of touching actor into material
				UpdateMaterialInstanceV(A2.Location,"OtherWorldLoc");
			}
			
			//Make nearby XcomeTriggerActors call rustle function
			ForEach CollidingActors(class'XComTriggerActor', XTA,RustleRadius)
			{
					XTA.Rustle();
					XTA.UpdateMaterialInstanceV(OtherPointing,"OtherPointing");
					//XPIndex = 0;

			}
		}

}


simulated event Tick (float DeltaTime)
{
	super.Tick(DeltaTime);
	
	ActorsTouchingThisTick=0;
	
	ForEach TouchingActors(class'XComPawn', A)
	{

		ActorsTouchingThisTick += 1;

		if (UpdateTouchLocEveryTick == true)
		{
			OtherPointing = Normal(A.Location - self.Location);
			UpdateMaterialInstanceV(OtherPointing,"OtherPointing");
			UpdateMaterialInstanceV(A2.Location,"OtherWorldLoc");
		}


	}

	if (ActorsTouchingThisTick == 0){

		GotoState('Idling');}
	Else
		GotoState('IsTouching');

	InterpParam();
	InterpParam2();

}

function Rustle(optional int Strength = 2, optional float TimerLength = 0.5)
{
	//called by nearby TriggerActors
	RustleIndex+=1;
	if (RustleIndex < 2)
		RustleStrength=Strength;
		RustleSpeed=0.05;
		SetTimer(TimerLength,false,'EndRustle');

}

function EndRustle()
{
		RustleStrength=0;
		RustleSpeed=0.0;
		RustleIndex=0;
}

function InterpParam()
{

	if ((HitStrength + ParamStep) > TargetValue && (HitStrength - ParamStep) < TargetValue){
		HitStrength = TargetValue;
		UpdateMaterialInstance(HitStrength);}

	else if (HitStrength < TargetValue){
		HitStrength+=ParamStep;
		UpdateMaterialInstance(HitStrength);}

	else if (HitStrength > TargetValue){
		HitStrength-=ParamStep;
		UpdateMaterialInstance(HitStrength);}

}


function InterpParam2()
{

	if ((RustleParam + ParamStep) > TargetValue2 && (RustleParam - ParamStep) < TargetValue2){
		RustleParam = TargetValue2;
		UpdateMaterialInstance(RustleParam,"Rustle");}

	else if (RustleParam < TargetValue2){
		RustleParam+=ParamStep;
		UpdateMaterialInstance(RustleParam,"Rustle");}

	else if (RustleParam > TargetValue2){
		RustleParam-=ParamStep;
		UpdateMaterialInstance(RustleParam,"Rustle");}

}


function simulated PostBeginPlay()
{
	super.PostBeginPlay();
	GotoState('Idling');
	InitMaterialInstance();
	
}

function InitMaterialInstance()
{
	MatInst = new(none) Class'MaterialInstanceConstant';
	MatInst.setParent(Mesh.GetMaterial(0));
	Mesh.SetMaterial(0, MatInst);

}

function UpdateMaterialInstance(float InValue, optional string Param = "HitStrength")
{
	//if (InValue > 0)
	MatInst.SetScalarParameterValue(name(Param), InValue);
}


function UpdateMaterialInstanceV(vector InValue , optional string Param = "HitStrength")
{
		local LinearColor LinValue;
		LinValue = MakeLinearColor(InValue.X,Invalue.Y,InValue.Z,0);

		MatInst.SetVectorParameterValue(name(Param),LinValue );
}


DefaultProperties
{
	HitStrength=0
	//NewHS=false
	UpdateTouchLocEveryTick = false
	
	bTickIsDisabled=false
	bCollideActors=true
	bBlockActors=false
	//bBlockFootPlacement=false
	
	RustleRadius = 80
	//ParamStep_Idle = 0.08
	//ParamStep_Touching = .3;

	//RustleMult = 2;


	Begin Object Class=CylinderComponent Name=CylinderComp
		CollisionRadius=32
		CollisionHeight=3
		CollideActors=true
		BlockActors=false
		bBlockFootPlacement=false
	End Object

	Components.Add( CylinderComp )
	CollisionComponent=CylinderComp

	Begin Object  Name=StaticMeshComponent0
		//StaticMesh = CursorOffset.Meshes.CIN_Grass_Trigger
		
	End Object
	
	Mesh=StaticMeshComponent0

	Components.add(StaticMeshComponent0)
}
