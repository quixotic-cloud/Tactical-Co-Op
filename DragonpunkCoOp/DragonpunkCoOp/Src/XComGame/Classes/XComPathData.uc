//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComPathData.uc
//  AUTHOR:  Todd Smith  --  11/15/2010
//  PURPOSE: Data common to the pathing system needed by multiple files
//---------------------------------------------------------------------------------------
//  Copyright (c) 2010 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class XComPathData extends Object
	native(Core)
	dependson(XComWorldData);

struct native ReplicatedPathPoint
{
	// NOTE: we dont need to replicate the actor because an interaction with an actor at a path point is replicated via the action associated with said point. -tsmith 
	var Vector          vRawPathPoint;
	var ETraversalType  eTraversal;
	// used by the owning player controller when receiving adjusted paths while moving the cursor. -tsmith 
	var float           fTimestamp;
	// flag to denote the point is set so if we are replicating an array of points we know whether or not to treat this as an actualy point. -tsmith 
	var bool            bPathPointSet; 
};

static final function string ReplicatedPathPoint_ToString(const out ReplicatedPathPoint kReplicatedPathPoint)
{
	local string strRep;

	strRep = "vRawPathPoint=" $ kReplicatedPathPoint.vRawPathPoint;
	strRep $= ", eTraversal=" $ kReplicatedPathPoint.eTraversal;
	strRep $= ", fTimestamp=" $ kReplicatedPathPoint.fTimestamp;
	strRep $= ", bPathPointSet=" $ kReplicatedPathPoint.bPathPointSet;

	return strRep;
}