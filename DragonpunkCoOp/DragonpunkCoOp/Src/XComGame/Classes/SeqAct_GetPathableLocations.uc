/**
 * 
 */
class SeqAct_GetPathableLocations extends SequenceAction;


var bool bUseObjectiveLocation;   // Fills vTargetLocation with Objective Parcel location
var int iNumObjectives;

event Activated()
{
	local SeqVar_VectorList VectorList;
	local array<vector> FloorPoints;
	local vector vTargetLocation;
	local vector vObjParcelLocation;
	local array<XComParcel> arrParcels;
	local int idx;

	foreach LinkedVariables(class'SeqVar_VectorList',VectorList,"Location List")
	{
		break;
	}

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

	for(idx = 0; idx < iNumObjectives; idx++)
	{
		if (bUseObjectiveLocation)
		{
			vTargetLocation = vObjParcelLocation;
		}
		else if(arrParcels.Length > 0)
		{
			vTargetLocation = arrParcels[`SYNC_RAND_TYPED(arrParcels.Length)].Location;
		}

		`XWORLD.GetFloorTilePositions(vTargetLocation, 96*8, 96, FloorPoints, true);

		VectorList.arrVectors.AddItem(FloorPoints[`SYNC_RAND_TYPED(FloorPoints.Length)]);
	}
}

defaultproperties
{
	ObjName="Get Pathable Locations"
	ObjCategory="Procedural Missions"
	bCallHandler=false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks.Empty;
	VariableLinks(0)=(ExpectedType=class'SeqVar_Bool',LinkDesc="bUseObjLoc",PropertyName=bUseObjectiveLocation)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Int',LinkDesc="Num Objectives",bWriteable=FALSE,PropertyName=iNumObjectives)
	VariableLinks(2)=(ExpectedType=class'SeqVar_VectorList',LinkDesc="Location List",bWriteable=TRUE)

}