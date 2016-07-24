//-----------------------------------------------------------
//
//-----------------------------------------------------------
class SeqEvent_SetAvengerData extends SequenceEvent;

var int iTerrainIndex;
var() int iMaxTerrainIndex;

event Activated()
{
	iTerrainIndex = rand(iMaxTerrainIndex); // Eventually make this a sequentially # so we hit all the terrain positions
}

/**
 * Return the version number for this class.  Child classes should increment this method by calling Super then adding
 * a individual class version to the result.  When a class is first created, the number should be 0; each time one of the
 * link arrays is modified (VariableLinks, OutputLinks, InputLinks, etc.), the number that is added to the result of
 * Super.GetObjClassVersion() should be incremented by 1.
 *
 * @return	the version number for this specific class.
 */
static event int GetObjClassVersion()
{
	return Super.GetObjClassVersion() + 0;
}

defaultproperties
{
	ObjCategory="Avenger"
	ObjName="SetAvengerData"

	bPlayerOnly=FALSE
	MaxTriggerCount=0
	
	OutputLinks.Empty
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Int',LinkDesc="Terrain Index",PropertyName=iTerrainIndex,bWriteable=TRUE)

	//bAutoActivateOutputLinks=false

	iMaxTerrainIndex = 4;
}
