/**
 * 
 */
class SeqAct_GetPathableLocation extends SequenceAction;

var vector PathableLocation;  // The result/return value of the action

var() int PlacementRadius; //Set the tile radius in which "GetFloorTilePositions" will search for a position

var bool bUseObjectiveLocation;   // Fills vTargetLocation with Objective Parcel location


event Activated()
{
	local array<vector> FloorPoints;
	local vector vTargetLocation;
	local vector vObjParcelLocation;
	local array<XComParcel> arrParcels;
	local int idx;

	vObjParcelLocation = `PARCELMGR.ObjectiveParcel.Location;
	arrParcels = `PARCELMGR.arrParcels;
	arrParcels.RemoveItem(`PARCELMGR.ObjectiveParcel);

	for(idx = 0; idx < arrParcels.Length; idx++)
	{
		if(VSize(arrParcels[idx].Location - vObjParcelLocation) > (48*96))
		{
			arrParcels.Remove(idx, 1);
			idx--;
		}
	}

	if (/*InputLinks[0].bHasImpulse*/true)
	{
		// 1x1 path
		
		if (bUseObjectiveLocation)
		{
			vTargetLocation = vObjParcelLocation;
		}
		else if(arrParcels.Length > 0)
		{
			vTargetLocation = arrParcels[`SYNC_RAND_TYPED(arrParcels.Length)].Location;
		}

		`XWORLD.GetFloorTilePositions(vTargetLocation, 96*PlacementRadius, 96, FloorPoints, true);

		PathableLocation = FloorPoints[`SYNC_RAND_TYPED(FloorPoints.Length)];

		`log("SeqAct_GetPathableLocation - "@PathableLocation);
	}
	else
	{
		// 2x2 path
	}
}

defaultproperties
{
	ObjName="Get Pathable Location"
	ObjCategory="Procedural Missions"
	bCallHandler=false
	PlacementRadius=8

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks.Empty;
	InputLinks(0)=(LinkDesc="1x1 Path")
	InputLinks(1)=(LinkDesc="2x2 Path")

	VariableLinks.Empty;
	VariableLinks(0)=(ExpectedType=class'SeqVar_Bool',LinkDesc="bUseObjLoc",PropertyName=bUseObjectiveLocation)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Vector',LinkDesc="Location",PropertyName=PathableLocation,bWriteable=TRUE)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Int',LinkDesc="Placement Radius",PropertyName=PlacementRadius,bWriteable=TRUE)

}