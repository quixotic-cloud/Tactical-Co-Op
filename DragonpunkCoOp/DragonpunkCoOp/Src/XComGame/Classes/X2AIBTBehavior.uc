class X2AIBTBehavior extends Object
	native(AI);

enum bt_status
{
	BTS_INVALID,
	BTS_SUCCESS,
	BTS_FAILURE,
	BTS_RUNNING,
};

struct native BTDetailedInfo
{
	var bt_status Result;
	var string DetailedText;
};

struct native EquivalentAbilityNames
{
	var Name KeyName;							// KeyName is the General ability name referred to in the behavior tree ini file. i.e. StandardShot
	var array<Name> EquivalentAbilityName;	// EquivalentAbilityName= array of alternate names for same ability.  i.e. AssaultRifleStandardShot
};

var bt_status m_eStatus;
var name m_strName;
var StateObjectReference m_kRef;
var name m_strIntent;

// for debug use only.
var int m_iSubNodeCount; 
var int m_iTraversalIndex;
var int m_iLastInit;

protected function bt_status Update();

native function SetName( name strName );
native function SetIntent( name strIntent );

protected function OnInit( int iObjectID, int iFrame )
{
	m_kRef.ObjectID = iObjectID;
	m_eStatus = BTS_RUNNING;
	m_iLastInit = iFrame;
}

function bt_status Run( int ObjectID, int iFrame ) // Init, update, and terminate.
{
	if (m_eStatus != BTS_RUNNING)
	{
		OnInit(ObjectID, iFrame);
	}  

	`LogAI("BTNode"@self@m_strName@"Updating. Status= pending...");
	m_eStatus = Update();
	`LogAI("BTNode"@self@m_strName@"Updated.  Status="$m_eStatus);

	if (m_eStatus != BTS_RUNNING)
	{
		OnTerminate(m_eStatus);
	}

	return m_eStatus;
}

protected function OnTerminate(bt_status eStatus)
{
	local XComTacticalCheatManager CheatMgr;
	CheatMgr = `CHEATMGR;
	if (CheatMgr != None && m_eStatus == BTS_SUCCESS && m_strIntent != '')
	{
		CheatMgr.AddIntent(m_strIntent);
	}
}

//------------------------------------------------------------------------------
// Functions used for debugging 
function int SetTraversalIndex(int iIndex)
{
	m_iTraversalIndex = iIndex;
	return iIndex+1;
}

function LogDetailText(string NewText);
function UpdateAdditionalInfo(out BTDetailedInfo BTInfo);

function GetNodeStatusList(out array<BTDetailedInfo> List, int iFrame)
{
	local BTDetailedInfo BTInfo;
	if (m_iLastInit == iFrame)
	{
		BTInfo.Result = m_eStatus;
		UpdateAdditionalInfo(BTInfo);
		List.AddItem(BTInfo);
	}
	else
	{
		// Status value can be incorrect if it was not visited this frame.
		BTInfo.Result = BTS_INVALID;
		List.AddItem(BTInfo);
	}
}

function X2AIBTBehavior GetNodeIndex( int iIndex )
{
	if (iIndex == 0)
		return self;

	return None;
}

function string GetNodeDetails(const out array<BTDetailedInfo> TraversalData)
{
	local string strText;
	strText = "Name= "$m_strName @"   SubnodeCount="$GetSubNodeCount();
	if (m_strIntent != '')
	{
		strText @= "\nIntent="@m_strIntent;
	}
	return strText;
}
function String GetLeafParentName()
{
	return "";
}

function int GetSubNodeCount()
{
	return 0;
}

//------------------------------------------------------------------------------------------------
defaultproperties
{
	m_iSubNodeCount = -1;
	m_iTraversalIndex = -1;
}