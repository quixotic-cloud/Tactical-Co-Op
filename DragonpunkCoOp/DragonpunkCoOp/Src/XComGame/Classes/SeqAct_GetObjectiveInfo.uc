class SeqAct_GetObjectiveInfo extends SequenceAction
	native(Level);

var int ObjectiveIndex;
var string ObjectiveSpawnTag;
var XComGameState_Unit ObjectiveUnit;
var XComGameState_InteractiveObject ObjectiveObject;
var Actor ObjectiveActor;
var Vector ObjectiveLocation;
var int NumObjectives;

event Activated()
{
	local XComGameStateHistory History;
	local XComTacticalMissionManager MissionManager;
	local string MissionType;
	local XComGameState_ObjectiveInfo ObjectiveInfo;
	local array<XComGameState_ObjectiveInfo> ObjectiveInfos;
	local TTile Tile;

	History = `XCOMHISTORY;
	MissionManager = `TACTICALMISSIONMGR;

	MissionType = MissionManager.ActiveMission.sType;

	// get all objectives that are valid for this kismet map
	foreach History.IterateByClassType(class'XComGameState_ObjectiveInfo', ObjectiveInfo)
	{
		if(MissionType == ObjectiveInfo.MissionType)
		{
			ObjectiveInfos.AddItem(ObjectiveInfo);
		}
	}

	NumObjectives = ObjectiveInfos.Length;

	// if a tag was specified, find it
	if(ObjectiveSpawnTag != "")
	{
		foreach ObjectiveInfos(ObjectiveInfo)
		{
			if(ObjectiveInfo.OSPSpawnTag != ObjectiveSpawnTag)
			{
				ObjectiveInfo = none;
			}
			else
			{
				break;
			}
		}
	
		if(ObjectiveInfo == none)
		{
			`redscreen("SeqAct_GetObjectiveInfo::Activated()\n Assert FAILED: ObjectiveSpawnTag was specified, but no object has that tag!\n"
				$ "ObjectiveSpawnTag: " $ ObjectiveSpawnTag $ "\n");
		}
	}
	else if(ObjectiveIndex < ObjectiveInfos.Length)
	{
		// sort them by objectid. This guarantees that the indexs are always the same, regardless of what order
		// the objectives were loaded
		ObjectiveInfos.Sort(SortInfos);
		ObjectiveInfo = ObjectiveInfos[ObjectiveIndex];
	}
	else
	{
		`redscreen("SeqAct_GetObjectiveInfo::Activated()\n Assert FAILED: ObjectiveIndex is greater than ObjectiveInfos.Length!\n"
			$ "ObjectiveIndex: " $ ObjectiveIndex $ "\n"
			$ "ObjectiveInfos.Length" $ ObjectiveInfos.Length);
		return;
	}

	// now fill out the kismet vars		
	ObjectiveUnit = XComGameState_Unit(ObjectiveInfo.FindComponentObject(class'XComGameState_Unit', true));
	ObjectiveObject = XComGameState_InteractiveObject(ObjectiveInfo.FindComponentObject(class'XComGameState_InteractiveObject', true));
	ObjectiveActor = History.GetVisualizer(ObjectiveInfo.ObjectID);

	// get the location
	if(ObjectiveUnit != none)
	{
		// special case units. They are special
		ObjectiveUnit.GetKeystoneVisibilityLocation(Tile);
		ObjectiveLocation = class'XComWorldData'.static.GetWorldData().GetPositionFromTileCoordinates(Tile);
	}
	else if(ObjectiveObject != None)
	{
		// special case interactive objects. They are special-ish
		Tile = ObjectiveObject.TileLocation;
		ObjectiveLocation = class'XComWorldData'.static.GetWorldData().GetPositionFromTileCoordinates(Tile);
	}
	else
	{
		// not a special object, just look at the actor
		ObjectiveLocation = ObjectiveActor.Location;
	}
}

private function int SortInfos(XComGameState_ObjectiveInfo Info1, XComGameState_ObjectiveInfo Info2)
{
	return Info1.ObjectID > Info2.ObjectID ? 1 : -1;
}

static event int GetObjClassVersion()
{
	return super.GetObjClassVersion() + 1;
}

cpptext
{
	virtual void PostLoad();
#if WITH_EDITOR
	virtual void CheckForErrors();
#endif
};

defaultproperties
{
	ObjName="Get Objective Info"
	ObjCategory="Procedural Missions"
	bCallHandler=false
	bAutoActivateOutputLinks=true

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks.Empty;
	VariableLinks(0)=(ExpectedType=class'SeqVar_Int',LinkDesc="Index",PropertyName=ObjectiveIndex)
	VariableLinks(1)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=ObjectiveUnit,bWriteable=true)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Object',LinkDesc="Actor",PropertyName=ObjectiveActor,bWriteable=true)
	VariableLinks(3)=(ExpectedType=class'SeqVar_Vector',LinkDesc="Location",PropertyName=ObjectiveLocation,bWriteable=true)
	VariableLinks(4)=(ExpectedType=class'SeqVar_InteractiveObject',LinkDesc="ObjectiveObject",PropertyName=ObjectiveObject,bWriteable=true)
	VariableLinks(5)=(ExpectedType=class'SeqVar_Int',LinkDesc="Num Objectives",PropertyName=NumObjectives,bWriteable=true)
}