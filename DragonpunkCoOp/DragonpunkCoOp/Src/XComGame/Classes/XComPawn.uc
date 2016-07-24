//-----------------------------------------------------------
// Base pawn for ALL Xcom pawns that need common functionality
//-----------------------------------------------------------
class XComPawn extends GamePawn
    dependson(XComTacticalGame)
	abstract
	native(Unit)
	implements(IMouseInteractionInterface)
	implements(XComCoverInterface)
	implements(IXComBuildingVisInterface);

var XComPawnIndoorOutdoorInfo IndoorInfo;
var bool bConsiderForCover; 

native simulated function bool NavMeshTrace(Vector vStart, Vector vEnd, Vector vExtent, out Vector vHitLocation);

simulated function HideMainPawnMesh()
{
	Mesh.SetHidden(true);
}

simulated function EMaterialType GetMaterialTypeBelow()
{
	local vector HitLocation, HitNormal;
	local EMaterialType MaterialType;

	class'XComPhysicalMaterialProperty'.static.TraceForMaterialType(HitLocation, HitNormal, MaterialType, Location, Location - (1.5 * GetCollisionHeight() * vect(0,0,1)), TRACEFLAG_PhysicsVolumes, self);

	// `log( "MaterialType:"@MaterialType );

	return MaterialType;
}

simulated function NotifyTacticalGameOfEvent(EXComTacticalEvent EEvent)
{
	local XComTacticalGRI TacticalGRI;
	local XGLevel kLevel;
	local XComUnitPawnNativeBase kPawn;
	local bool bSuccess;

	TacticalGRI = XComTacticalGRI(`XCOMGRI);
	if (`BATTLE != none)
		kLevel = `LEVEL;

	if (TacticalGRI == none ||
		kLevel == none)
		return;

	bSuccess = false;

	kPawn = XComUnitPawnNativeBase(self);
	if (kPawn != none)
	{
		TacticalGRI.NotifyOfEvent(EEvent, kPawn);
		bSuccess = true;
	}

	if (!bSuccess)
		`log ("NotifyTacticalGameOfEvent() reports unhandled Event"@EEvent@"for XComPawn"@self);
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
	if( IndoorInfo != none )
		IndoorInfo.ParentTouchedOrUntouched(Other, true);
}

event UnTouch( Actor Other )
{
	super.UnTouch(Other);
	if( IndoorInfo != none )
		IndoorInfo.ParentTouchedOrUntouched(Other, false);
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();
	IndoorInfo = new(Self) class'XComPawnIndoorOutdoorInfo';
	IndoorInfo.BuildingVisActor = self;	
}

simulated function bool NavTraceBelowSelf(float fDistance, optional out Vector vHitLoc, optional out Vector vHitNormal)
{
	return NavTraceBelowLocation(Location, fDistance, vHitLoc, vHitNormal);
}

simulated function bool NavTraceBelowLocation(vector vLoc, float fDistance, optional out Vector vHitLoc, optional out Vector vHitNormal)
{
	local Vector vTraceTo, vTraceFrom, vExtent;
	local bool bHitResult;

	vExtent.X = CylinderComponent.CollisionRadius;
	vExtent.Y = CylinderComponent.CollisionRadius;
	vExtent.Z = CylinderComponent.CollisionRadius;

	vTraceTo = vLoc;
	vTraceTo.Z += fDistance;

	vTraceFrom = vLoc + Vect(0,0,8);

	bHitResult = NavMeshTrace(vTraceFrom, vTraceTo, vExtent, vHitLoc);
	bHitResult = bHitResult && `XWORLD.IsPositionOnFloor(vHitLoc);

	if (bHitResult)
		return true;
	else
		return false;
}

function Actor GetActor()
{
	return self;
}

function bool TraceBelowSelf(float fDistance, optional out Vector vHitLoc, optional out Vector vHitNormal)
{
	local Vector vTraceTo, vTraceFrom, vExtent;
	local Actor HitActor;

	// Position pawn at contact point
	vTraceTo = Location;
	vTraceTo.Z += fDistance;
	vTraceFrom = Location + vect(0,0,8);

	vExtent.X = CylinderComponent.CollisionRadius;
	vExtent.Y = CylinderComponent.CollisionRadius;
	vExtent.Z = 1;

	HitActor = Trace( vHitLoc, vHitNormal, vTraceTo, vTraceFrom, true, vExtent,,TRACEFLAG_Blocking );

	if (HitActor != none)
		return true;
	else
		return false;
}

// -------------------------------------------------------------------------------------
// Receives mouse events
function bool OnMouseEvent(    int cmd, 
							   int Actionmask, 
							   optional Vector MouseWorldOrigin, 
							   optional Vector MouseWorldDirection, 
							   optional Vector HitLocation)
{
	return false; 
}

// XComCoverInterface
simulated native function bool ConsiderForOccupancy();
simulated native function bool ShouldIgnoreForCover();
simulated native function bool CanClimbOver();
simulated native function bool CanClimbOnto();
simulated native function bool UseRigidBodyCollisionForCover();
simulated native function ECoverForceFlag GetCoverForceFlag();
simulated native function ECoverForceFlag GetCoverIgnoreFlag();

// XComBuildingVisInterface
// -------------------------------------------------------------------------------------

simulated native function XComPawnIndoorOutdoorInfo GetIndoorOutdoorInfo();

// Used by XTraceAndHideBuildingFloors - written because XComIndoorOutdoorInfo is not native.
simulated native event XComBuildingVolume GetCurrentBuildingVolumeIfInside();


// A helper function to get IndoorInfo since it is script-only.. 
simulated native event bool IsInside();

// Route change of indoor/outdoor status through the TacticalGRI
simulated function OnChangedIndoorStatus() 
{
	NotifyTacticalGameOfEvent(PAWN_INDOOR_OUTDOOR);
}

// Route change of floor status through the TacticalGRI and trigger any kismet events
simulated function OnChangedFloor()
{
	// do delegates stuff
	NotifyTacticalGameOfEvent(PAWN_CHANGED_FLOORS);
}

// -------------------------------------------------------------------------------------

DefaultProperties
{
	InventoryManagerClass=class'XComInventoryManager'
	bConsiderForCover=false
}
