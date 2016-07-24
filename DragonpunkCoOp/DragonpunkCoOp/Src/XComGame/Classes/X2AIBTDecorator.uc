class X2AIBTDecorator extends X2AIBTBehavior
	native(AI);

enum EDecoratorType 
{
	eDT_Invalid,
	eDT_Inverter, // Returns FAILURE when SUCCESS, and vice versa
	eDT_Failer,  // Always returns FAILURE
	eDT_Successor, // Always returns SUCCESS.
	eDT_RepeatUntilFail, // Continues to update child node until it returns failure.
	eDT_RandFilter,	// Randomize filter, with param[0]= Percent of time to execute child node, otherwise return failure.
};

var private X2AIBTBehavior m_Child;
var EDecoratorType m_eDecType;
var int RandValue, RolledValue;
var delegate<BTDecoratorDelegate> m_dDecoratorFn;

const MAX_REPEAT_DECORATOR_ITERATIONS = 128; // Abort RepeatUntilFail decorator after this many repeats.

var string DebugDetailText; // For debug only
delegate bt_status BTDecoratorDelegate();       

static event EDecoratorType GetDecTypeFromName( name strType )
{
	if (string(strType) ~= "Inverter")
	{
		return eDT_Inverter;
	}
	if (string(strType) ~= "Failer")
	{
		return eDT_Failer;
	}
	if (string(strType) ~= "Successor")
	{
		return eDT_Successor;
	}
	if (string(strType) ~= "RepeatUntilFail")
	{
		return eDT_RepeatUntilFail;
	}
	if( string(strType) ~= "RandFilter" )
	{
		return eDT_RandFilter;
	}
	return eDT_Invalid;
}
event SetDecType( EDecoratorType eType )
{
	m_eDecType = eType;
	if (!FindBTDecoratorDelegate(m_eDecType, m_dDecoratorFn))
	{
		`WARN("X2AIBTDefaultActions- No delegate action defined for node"@m_strName@"("$m_eDecType$")");
	}
}

protected function OnInit( int iObjectID, int iFrame )
{
	super.OnInit(iObjectID, iFrame);
	RolledValue = INDEX_NONE;
}


protected function bt_status Update()
{
	// Early exit if this has already been evaluated.
	if (m_eStatus == BTS_SUCCESS || m_eStatus == BTS_FAILURE)
		return m_eStatus;

	X2AIBTBehaviorTree(Outer).ActiveNode = self;

	if( m_dDecoratorFn != None )
	{
		return m_dDecoratorFn();
	}
	return BTS_FAILURE;
}

function LogDetailText(string NewText)
{
	DebugDetailText = DebugDetailText @ NewText;
}

function UpdateAdditionalInfo(out BTDetailedInfo BTInfo)
{
	BTInfo.DetailedText = DebugDetailText;
}

static event bool FindBTDecoratorDelegate(EDecoratorType eType, optional out delegate<BTDecoratorDelegate> dOutFn)
{
	// Was hoping to use a hash map for names to delegates, but that may not be valid.
	// using switch statement for now.
	dOutFn = None;
	switch (eType)
	{
	case eDT_Inverter:
		dOutFn = Invert;
		return true;
	break;

	case eDT_Failer:
		dOutFn = Failer;
		return true;
	break;

	case eDT_Successor:
		dOutFn = Successor;
		return true;
	break;

	case eDT_RepeatUntilFail:
		dOutFn = RepeatUntilFail;
		return true;
	break;

	case eDT_RandFilter:
		dOutFn = RandFilter;
		return true;
	break;

	default:
		`Log("No decorator delegate found for type "$eType);
	break;
	}
	return false;
}

function bt_status Invert()
{
	local bt_status ChildStatus;
	ChildStatus = m_Child.Run(m_kRef.ObjectID, m_iLastInit);
	if (ChildStatus == BTS_SUCCESS)
		return BTS_FAILURE;
	if (ChildStatus == BTS_FAILURE)
		return BTS_SUCCESS;

	// Other return codes are not affected.
	return ChildStatus;
}

function bt_status Failer()
{
	local bt_status ChildStatus;
	ChildStatus = m_Child.Run(m_kRef.ObjectID, m_iLastInit);
	if (ChildStatus == BTS_RUNNING)
		return BTS_RUNNING;
	return BTS_FAILURE;
}
function bt_status Successor()
{
	local bt_status ChildStatus;
	ChildStatus = m_Child.Run(m_kRef.ObjectID, m_iLastInit);
	if (ChildStatus == BTS_RUNNING)
		return BTS_RUNNING;
	return BTS_SUCCESS;
}

function bt_status RepeatUntilFail()
{
	local bt_status ChildStatus;
	local int iMaxIterations, iIterations;
	iMaxIterations = MAX_REPEAT_DECORATOR_ITERATIONS;
	do
	{
		ChildStatus = m_Child.Run(m_kRef.ObjectID, m_iLastInit);
		iIterations++;
	} until (ChildStatus == BTS_FAILURE || iIterations > iMaxIterations);

	if (iIterations > iMaxIterations)
	{
		`Log("Error - exceeded max iterations!  Failed!  (this should not fail.)");
		`RedScreen("AIBTDecorator RepeatUntilFail exceeded MaxIterations! ("$iMaxIterations$") - NodeName="@m_strName@" -ACHENG");
		return BTS_FAILURE;
	}
	return BTS_SUCCESS;
}

// Rand Filter rolls the dice before attempting to run the child node.  
// If it fails the dice roll, it returns FAILURE without attempting to run the child node.
function bt_status RandFilter()
{
	if( m_eStatus == BTS_RUNNING && RolledValue != INDEX_NONE) // Don't reroll if we've already passed this the first time.
	{
		return m_Child.Run(m_kRef.ObjectID, m_iLastInit);
	}

	RolledValue = `SYNC_RAND(100);
	`LogAIBT("Random Filter decorator rolled a "$RolledValue$".  Child node runs when roll is below "$RandValue$".");
	if( RolledValue < RandValue )
	{
		return m_Child.Run(m_kRef.ObjectID, m_iLastInit);
	}
	return BTS_FAILURE;
}
//------------------------------------------------------------------------------
// Functions used for debugging 
function int SetTraversalIndex(int iIndex)
{
	iIndex = super.SetTraversalIndex(iIndex);
	iIndex = m_Child.SetTraversalIndex(iIndex);
	return iIndex;
}

function GetNodeStatusList(out array<BTDetailedInfo> List, int iFrame)
{
	super.GetNodeStatusList(List, iFrame);
	m_Child.GetNodeStatusList( List, iFrame );
}

function int GetSubNodeCount()
{
	if (m_iSubNodeCount == -1)
	{
		m_iSubNodeCount = 1 + m_Child.GetSubNodeCount();
	}
	return m_iSubNodeCount;
}

function X2AIBTBehavior GetNodeIndex( int iIndex )
{
	if (iIndex == 0)
	{
		return self;
	}

	if (GetSubNodeCount() < iIndex)
	{
		return None;
	}

	return m_Child.GetNodeIndex(iIndex-1);
}

function string GetNodeDetails(const out array<BTDetailedInfo> TraversalData)
{
	local string strText;
	strText = super.GetNodeDetails(TraversalData);
	strText @= "\n Decorator- Type:"@string(m_eDecType) @"\n";
	strText @= "Child: ("$m_Child.m_iTraversalIndex$") "$m_Child.m_strName;
	if( m_eDecType == eDT_RandFilter )
	{
		strText @= "\nChanceToActivate = "$RandValue$"%";
	}
	strText @= "["$TraversalData[m_Child.m_iTraversalIndex].Result$"]\n";
	return strText;
}

//------------------------------------------------------------------------------------------------
defaultproperties
{
	RolledValue = INDEX_NONE;
}