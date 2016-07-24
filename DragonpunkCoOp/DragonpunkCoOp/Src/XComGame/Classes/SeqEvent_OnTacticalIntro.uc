//-----------------------------------------------------------
//Event triggers when an intro cinematic is to play in the tactical game
//-----------------------------------------------------------
class SeqEvent_OnTacticalIntro extends SequenceEvent;

var string  strMapName;
var Object  Soldier1,Soldier2,Soldier3,Soldier4,Soldier5,Soldier6;
var Object  Mec1,Mec2,Mec3,Mec4,Mec5,Mec6;
var Object  Shiv1,Shiv2,Shiv3,Shiv4,Shiv5,Shiv6;
var Object  BattleObj;
var int     iSpawnGroup;
var() bool  CollapseSlots;

event Activated()
{
	`log( "SeqEvent_OnTacticalIntro: map name ="@strMapName,,'KismetWarning');
	OutputLinks[0].bDisabled = false;
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
	return Super.GetObjClassVersion() + 2;
}

defaultproperties
{
	ObjName="OnTacticalIntro"
	ObjCategory="Cinematic"
	bPlayerOnly=false
	MaxTriggerCount=1

	OutputLinks.Empty
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_String',LinkDesc="Map Name",PropertyName=strMapName,bWriteable=TRUE)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object',LinkDesc="Soldier 1",PropertyName=Soldier1,bWriteable=TRUE)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Object',LinkDesc="Soldier 2",PropertyName=Soldier2,bWriteable=TRUE)
	VariableLinks(3)=(ExpectedType=class'SeqVar_Object',LinkDesc="Soldier 3",PropertyName=Soldier3,bWriteable=TRUE)
	VariableLinks(4)=(ExpectedType=class'SeqVar_Object',LinkDesc="Soldier 4",PropertyName=Soldier4,bWriteable=TRUE)
	VariableLinks(5)=(ExpectedType=class'SeqVar_Object',LinkDesc="Soldier 5",PropertyName=Soldier5,bWriteable=TRUE)
	VariableLinks(6)=(ExpectedType=class'SeqVar_Object',LinkDesc="Soldier 6",PropertyName=Soldier6,bWriteable=TRUE)

	VariableLinks(7)=(ExpectedType=class'SeqVar_Object',LinkDesc="Battle Obj",PropertyName=BattleObj,bWriteable=TRUE)
	VariableLinks(8)=(ExpectedType=class'SeqVar_Int',LinkDesc="Spawn Group",PropertyName=iSpawnGroup,bWriteable=TRUE)

	VariableLinks(9)=(ExpectedType=class'SeqVar_Object',LinkDesc="Mec 1",PropertyName=Mec1,bWriteable=TRUE)
	VariableLinks(10)=(ExpectedType=class'SeqVar_Object',LinkDesc="Mec 2",PropertyName=Mec2,bWriteable=TRUE)
	VariableLinks(11)=(ExpectedType=class'SeqVar_Object',LinkDesc="Mec 3",PropertyName=Mec3,bWriteable=TRUE)
	VariableLinks(12)=(ExpectedType=class'SeqVar_Object',LinkDesc="Mec 4",PropertyName=Mec4,bWriteable=TRUE)
	VariableLinks(13)=(ExpectedType=class'SeqVar_Object',LinkDesc="Mec 5",PropertyName=Mec5,bWriteable=TRUE)
	VariableLinks(14)=(ExpectedType=class'SeqVar_Object',LinkDesc="Mec 6",PropertyName=Mec6,bWriteable=TRUE)

	VariableLinks(15)=(ExpectedType=class'SeqVar_Object',LinkDesc="Shiv 1",PropertyName=Shiv1,bWriteable=TRUE)
	VariableLinks(16)=(ExpectedType=class'SeqVar_Object',LinkDesc="Shiv 2",PropertyName=Shiv2,bWriteable=TRUE)
	VariableLinks(17)=(ExpectedType=class'SeqVar_Object',LinkDesc="Shiv 3",PropertyName=Shiv3,bWriteable=TRUE)
	VariableLinks(18)=(ExpectedType=class'SeqVar_Object',LinkDesc="Shiv 4",PropertyName=Shiv4,bWriteable=TRUE)
	VariableLinks(19)=(ExpectedType=class'SeqVar_Object',LinkDesc="Shiv 5",PropertyName=Shiv5,bWriteable=TRUE)
	VariableLinks(20)=(ExpectedType=class'SeqVar_Object',LinkDesc="Shiv 6",PropertyName=Shiv6,bWriteable=TRUE)
}
