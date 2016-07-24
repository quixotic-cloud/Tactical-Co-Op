//-----------------------------------------------------------
// Physical material properties can be added to physical materials
// that are defined in the editor.
// Used to determine properties of a material, such as footstep sound,
// hit particle effect, etc...
//
// Most of this is copied from UT
//-----------------------------------------------------------
class XComPhysicalMaterialProperty extends PhysicalMaterialPropertyBase;


/** Type of material this is (dirt, gravel, brick, etc) used for looking up material specific effects */
var() EMaterialType				MaterialType;

/**
 * Trace to determine the material type
 *
 */
simulated static function Actor TraceForMaterialType(out vector HitLocation, out vector HitNormal, out EMaterialType OutMaterialType, vector StartLocation, vector EndLocation, int TraceFlags, XComPawn PawnToTraceFrom)
{
	local TraceHitInfo HitInfo;
	local XComPhysicalMaterialProperty PhysicalProperty;
	local Actor HitActor;
	local XComUnitPawn HitXcomUnitPawn;
	local float TraceDist;

	// initialize to default
	OutMaterialType = MaterialType_Default;
	if (PawnToTraceFrom != none)
	{
		HitActor = PawnToTraceFrom.Trace(HitLocation, HitNormal, EndLocation, StartLocation, /*bool(TraceFlags & 0x01)*/ true,, HitInfo, TraceFlags);
	}
	else
	{
		HitActor = class'Engine'.static.GetCurrentWorldInfo().Trace(HitLocation, HitNormal, EndLocation, StartLocation, /*bool(TraceFlags & 0x01)*/ true,, HitInfo, TraceFlags);
	}
	
	HitXComUnitPawn = XComUnitPawn(HitActor);

	// water volumes don't have physical materials?
	if ( WaterVolume(HitActor) != None )
	{
		TraceDist = VSize(EndLocation - StartLocation);
		// if the trace went far, we must be in shallow water
		OutMaterialType = (StartLocation.Z - HitLocation.Z < 0.33*TraceDist) ? MaterialType_Water : MaterialType_ShallowWater;
	}
	// if we hit a pawn, use the flesh material
	else if (HitXcomUnitPawn != None)
	{		
		OutMaterialType = MaterialType_HumanFlesh;
	}
	// otherwise try to pull a physical material
	else if (HitInfo.PhysMaterial != None)
	{
		PhysicalProperty = XComPhysicalMaterialProperty(HitInfo.PhysMaterial.GetPhysicalMaterialProperty(class'XComPhysicalMaterialProperty'));

		if (PhysicalProperty != None)
		{
			OutMaterialType = PhysicalProperty.MaterialType;
		}
	}
	return HitActor;
}

DefaultProperties
{

}
