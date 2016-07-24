class XComLadder extends XComLevelActor
	  native(Level)
	  placeable;

var() int LoopAnimations;
var() deprecated privatewrite float Depth;
var transient LineBatchComponent LineBatch;
var StaticMeshComponent StaticMesh;

var() name nLadderType<DisplayName=Ladder Type|ToolTip=Valid values are: Ladder, Pipe, Vine>;

// Effects
var ParticleSystemComponent AlienAirLiftPSC;
var() privatewrite ParticleSystem AlienAirLiftUpFX;
var() privatewrite ParticleSystem AlienAirLiftDownFX;

replication
{
	if(bNetInitial && Role == ROLE_Authority)
		LoopAnimations;
}

cpptext
{
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);
	virtual void PostLoad();

#if WITH_EDITOR
	virtual void CheckForErrors();
#endif

	virtual void ApplyAOEDamageMaterial();
	virtual void RemoveAOEDamageMaterial();

	void UpdateDebugView();
}

native function Vector GetTop(bool bWorldSpace=true);
native function Vector GetBottom(bool bWorldSpace=true);

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
}

simulated native function float GetHeight();

simulated function bool IsAtBottom(float fHeight)
{
	return (fHeight < Location.Z + GetHeight() / 2);
}

simulated function GetPath(float fStartHeight, out vector vUnitMoveBegin, out vector vUnitMoveEnd)
{
	if (IsAtBottom(fStartHeight))
	{
		vUnitMoveBegin = GetBottom();
		vUnitMoveEnd = GetTop();
	}
	else
	{
		vUnitMoveBegin = GetTop();
		vUnitMoveEnd = GetBottom();
	}
}

simulated function bool GetDistanceSqToClosestMoveToPoint(vector vCenter, int iRadiusSq, int iMaxHeightDiff, out float fClosestDistance)
{
	local vector vGoToPoint;

	 GetMoveToPoint(vCenter, vGoToPoint);

	// Height check
	if (abs(vCenter.Z - vGoToPoint.Z) > iMaxHeightDiff)
        return false;	

	fClosestDistance = VSizeSq2D(vCenter - vGoToPoint);

	if (fClosestDistance < iRadiusSq)
		return true;
	else return false;
}

simulated function GetMoveToPoint(vector vCurrentLoc, out vector vUnitMoveTo)
{
	local vector vTmpDest;

	GetPath(vCurrentLoc.Z, vUnitMoveTo, vTmpDest);

	//vUnitMoveTo = Location;
}

defaultproperties
{
	Begin Object Name=StaticMeshComponent0
		//StaticMesh=StaticMesh'LadderMetal.Meshes.LadderMetalA_192'
	End Object
	Components.Add(StaticMeshComponent0)
	StaticMesh = StaticMeshComponent0;

	nLadderType = "Ladder";

	Depth=48.0f

	DrawScale3D=(X=1, Y=1, Z=1)

	bTickIsDisabled=true
	bPathColliding=false

	// network variables -tsmith 
	//RemoteRole=ROLE_SimulatedProxy
	//bAlwaysRelevant=true
	RemoteRole=ROLE_None
	bAlwaysRelevant=false

	AlienAirLiftUpFX = ParticleSystem'FX_Alien_Air_Lift.P_Alien_Air_Lift_Up';	
	AlienAirLiftDownFX = ParticleSystem'FX_Alien_Air_Lift.P_Alien_Air_Lift_Down';
}
