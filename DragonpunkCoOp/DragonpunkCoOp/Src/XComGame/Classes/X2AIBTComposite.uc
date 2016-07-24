class X2AIBTComposite extends X2AIBTBehavior
	native(AI);

var private array<X2AIBTBehavior> m_arrChildren;
var private int m_iActiveChild;

// Randomizer values
var private bool m_bRandomized;
var array<int> m_arrChildWeight;
var array<int> m_arrClosedList; // indices of children we have already visited.

protected function OnInit( int iObjectID, int iFrame )
{
	m_arrClosedList.Length = 0; // Reset closed list on every run.
	m_iActiveChild=NextUnitIndex(true);
	if (m_iActiveChild == -1) // -1 happens when this is a randomized list and sum of weights <= 0.
	{
		`RedScreen("Behavior Tree Error- zero sum weights on children of Randomized Node:"@m_strName);
	}
	super.OnInit(iObjectID, iFrame);
}

protected function int NextUnitIndex(bool bOnInit=false)
{
	if (m_bRandomized)
	{
		return NextUnitIndex_Random();
	}

	if (bOnInit)
		return 0;

	return m_iActiveChild+1;
}

protected function X2AIBTBehavior GetActiveChild()
{
	if (m_iActiveChild >= 0 && m_iActiveChild < m_arrChildren.Length)
	{
		return m_arrChildren[m_iActiveChild];
	}
	return None;
}

protected function X2AIBTBehavior AdvanceToNextChild()
{
	m_iActiveChild = NextUnitIndex();
	return GetActiveChild();
}

function AddChild( X2AIBTBehavior Behavior )
{
	m_arrChildren.AddItem(Behavior);
}

function RemoveChild( X2AIBTBehavior Behavior )
{
	m_arrChildren.RemoveItem(Behavior);
}

function ClearChildren()
{
	m_arrChildren.Length = 0;
}

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
// Support for randomized composites and weighted random composites.
//------------------------------------------------------------------------------------------------
protected function int NextUnitIndex_Random()
{
	local int iTotalWeight, iRand, iIndex;
	iTotalWeight = GetTotalWeight();
	if (iTotalWeight <= 0)
		return -1;

	iRand = `SYNC_RAND(iTotalWeight);
	`LogAIBT("NODE:"@m_strName@`ShowVar(iRand)@`ShowVar(iTotalWeight)$"\n");
	iIndex = GetChildIndexForWeight(iRand);
	m_arrClosedList.AddItem(iIndex);
	return iIndex;
}

function int GetTotalWeight()
{
	local int iRunningTotal, iChildIndex, iWeight;
	iRunningTotal = 0;

	for (iChildIndex=0; iChildIndex<m_arrChildren.Length; ++iChildIndex)
	{
		iWeight = (m_arrChildWeight.Length > iChildIndex)?m_arrChildWeight[iChildIndex]:1;// Set weight to 1 for any uninitialized weights.
		if (m_arrClosedList.Find(iChildIndex) == -1)
		{
			iRunningTotal += MAX(1, iWeight); // Set weight to 1 for any uninitialized weights.
		}
	}
	return iRunningTotal;
}

function int GetChildIndexForWeight( int iWeightVal )
{
	local int iRunningTotal, iChildIndex, iWeight;
	iRunningTotal = 0;

	for (iChildIndex=0; iChildIndex<m_arrChildren.Length; ++iChildIndex)
	{
		iWeight = (m_arrChildWeight.Length > iChildIndex)?m_arrChildWeight[iChildIndex]:1;// Set weight to 1 for any uninitialized weights.
		if (m_arrClosedList.Find(iChildIndex) == -1)
		{
			iRunningTotal += iWeight;
			if (iWeightVal < iRunningTotal)
				return iChildIndex;
		}
	}
	`Warn("Error - Exceeded total weight of random list!");
	return 0;
}

//------------------------------------------------------------------------------
// Functions used for debugging 
function int SetTraversalIndex(int iIndex)
{
	local int iChild;
	iIndex = super.SetTraversalIndex(iIndex);
	for (iChild=0; iChild < m_arrChildren.Length; iChild++)
	{
		iIndex = m_arrChildren[iChild].SetTraversalIndex(iIndex);
	}
	return iIndex;
}

function GetNodeStatusList(out array<BTDetailedInfo> List, int iFrame)
{
	local X2AIBTBehavior kChild;
	super.GetNodeStatusList(List, iFrame);
	foreach m_arrChildren(kChild)
	{
		kChild.GetNodeStatusList( List, iFrame );
	}
}
function int GetSubNodeCount()
{
	local X2AIBTBehavior kChild;
	if (m_iSubNodeCount == -1)
	{
		m_iSubNodeCount = m_arrChildren.Length;
		foreach m_arrChildren(kChild)
		{
			m_iSubNodeCount += kChild.GetSubNodeCount();
		}
	}
	return m_iSubNodeCount;
}

function X2AIBTBehavior GetNodeIndex( int iIndex )
{
	local X2AIBTBehavior kChild;
	local int nSubNodes;

	if (iIndex == 0)
		return self;

	foreach  m_arrChildren(kChild)
	{
		iIndex--;
		nSubNodes = kChild.GetSubNodeCount();
		if (iIndex <= nSubNodes)
		{
			return kChild.GetNodeIndex(iIndex);
		}
		else
		{
			iIndex -= nSubNodes;
		}
	}

	return None;
}

function string GetNodeDetails(const out array<BTDetailedInfo> TraversalData)
{
	local string strText;
	local X2AIBTBehavior kChild;
	local int iChild;
	strText = super.GetNodeDetails(TraversalData);

	strText @= "\n Composite- Type:";
	if (m_bRandomized)
	{
		strText @= "Random ";
	}
	if (IsA('X2AIBTSelector'))
	{
		strText @= "SELECTOR \n";
	}
	else if (IsA('X2AIBTSequence'))
	{
		strText @= "SEQUENCE \n";
	}
	else
	{
		strText @= "UNKNOWN TYPE???\n";
	}


	strText @= "\nChildren: \n";
	for (iChild=0; iChild<m_arrChildren.Length; iChild++)
	{
		kChild = m_arrChildren[iChild];
		strText @= "("$kChild.m_iTraversalIndex$")";
		strText @= kChild.m_strName;
		if ( m_bRandomized )
		{
			if (iChild >= m_arrChildWeight.Length)
			{
				strText @= "       Weight=1";
			}
			else
			{
				strText @= "       Weight="$m_arrChildWeight[iChild]$"";
			}
		}
		strText @= "["$TraversalData[kChild.m_iTraversalIndex].Result$"]\n";
	}

	return strText;
}

//------------------------------------------------------------------------------------------------
defaultproperties
{
	m_iSubNodeCount = -1;
}