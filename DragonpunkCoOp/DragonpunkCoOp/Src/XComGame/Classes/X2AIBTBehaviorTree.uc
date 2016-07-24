class X2AIBTBehaviorTree extends Object
	native(AI)
	config(AI);

var private config array<BehaviorTreeNode> Behaviors;
var private native Map_Mirror BehaviorsMap{TMap<FName, INT>};  //  maps table name to index into Behaviors array

var config array<EquivalentAbilityNames> EquivalentAbilities;
var int ActiveObjectID; // Currently-running behavior tree on this unit.  Clears this value when done.
/* 
EquivalentAbilities is configured alongside the BehaviorTree nodes, and maps any equivalent ability names to a key ability name.
Allows for reuse of a BT node using an ability KeyName without having to duplicate the same nodes for other equivalent abilities.
i.e.
 EquivalentAbilities sample config entry:
 EquivalentAbilities=( KeyName=StandardShot, EquivalentAbilityName[0]=AssaultRifleStandardShot, 
											EquivalentAbilityName[1]=ShotgunStandardShot, 
											EquivalentAbilityName[2]=CannonStandardShot, 
											EquivalentAbilityName[3]=SniperStandardFire )

Hence, nodes like the following can be generalized for any 'StandardShot' types and can be used for all unit with any standard-shot weapon:
 Behaviors=(BehaviorName=ShootIfAvailable, NodeType=Sequence, Child[0]=IsAbilityAvailable-StandardShot, Child[1]=HasAmmo, Child[2]=SelectTargetForStandardShot, Child[3]=SelectAbility-StandardShot)
*/

//  Behavior Tree Queue data.
var int ActiveQueueID;  // ID of the unit from the ActiveBTQueue that is set to run a specified behavior tree N times.
var bool bBTQueueTimerActive; // Set when there is an active timer running to process the entries in the BT queue.

// Flag to wait on an EndMove event trigger before proceeding with the behavior tree run.
var bool bWaitingOnEndMoveEvent;
var bool bWaitingOnSquadConcealment; // Wait for enemy squad concealment to break before proceeding with BT run.

struct native BTQueueEntry		// Struct for keeping track of units whose behavior tree are queued up to run.
{
	var int ObjectID;			// ID of unit whose Behavior Tree is queued up.
	var int RunCount;			// Number of times to run this unit's behavior tree, in a row.
	var int HistoryIndex;		// Minimum history index to wait before kicking off behavior tree.
	var Name Node;				// Name of root node of behavior tree to run.
	var bool bSurprisedScamper; // True if this unit should run behavior tree with the SurprisedScamper condition.
	var bool bFirstScamper;		// True if this unit is the first in its group to scamper. Used to set the AI begin reveal.
	var bool bScamperEntry;		// True if this entry is for a scamper action.
	var bool bInitFromPlayerEachRun; // True to reset more behavior tree vars on each run as if it is the start of the player turn. BTVars & ErrorChecking.
};
var array<BTQueueEntry> ActiveBTQueue;  // List of behavior trees to kick off.
var BTQueueEntry ActiveBTQueueEntry; //Currently active behavior tree queue entry

// Debug data
var X2AIBTBehavior ActiveNode;
var String ActiveCharacterName;

struct native BTCustomNodeEntry
{
	var Name NodeTypeString;
	var Name ExtendsFromType;
	var String ClassName;
};
var config array<BTCustomNodeEntry> CustomNodes;

// Cached conditions here so that we don't allocate a zillion of these check conditions.
var transient array<X2Condition> CachedActiveWithAPConditions;  
var transient array<X2Condition> CachedActiveDamagedConditions;

native function Name GetNodeName(int Index);
native function int GetNodeIndex(Name BehaviorName);
native static function X2AIBTBehaviorTree GetBehaviorTreeManager();
native function bool HasCycle(int Index, array<int> ParentIndices);
native function OutputRedScreenCycle(array<int> CyclicIndices);

native function InitBehaviors();
native function X2AIBTBehavior GenerateBehaviorTree(Name RootName, Name CharName);
native function X2AIBTBehavior GenerateBehaviorTreeFromIndex(int RootIndex, Name CharName);
native function X2AIBTBehavior CreateBehaviorNode(BehaviorTreeNode kNodeData);
native function X2AIBTBehavior CreateScoringNode( Name strScore, Name strNodeName, Name ParentName );
native function int FindBehaviorIndex(Name NodeName);
native function bool IsScoringBehavior(Name BehaviorName, optional out Name strScore, optional out Name strNodeName);

native function bool IsValidBehavior( Name RootName );

native function Name GetNodeTypeOverride(BehaviorTreeNode NodeData, out X2AIBTDecorator Dec, out X2AIBTDefaultConditions Cond, out X2AIBTDefaultActions Act);
native function Class ConstructBTNodeObject(BehaviorTreeNode NodeData, out Name NodeTypeName);

function ClearQueue()
{
	ActiveBTQueue.Length = 0;
	bBTQueueTimerActive = false;
	ActiveQueueID = INDEX_NONE;
}

function LogNodeDetailText(string strLog)
{
	ActiveNode.LogDetailText(strLog);
}
function String GetLeafParentName()
{
	return ActiveNode.GetLeafParentName();
}

// Prevent more than one behavior tree from running at a time, as this can cause conflicting results.
function bool IsReady()
{
	return ActiveObjectID == INDEX_NONE;
}

function BeginBehaviorTree( int ObjectID )
{
	if( (ActiveNode != None && ActiveNode.m_eStatus == BTS_RUNNING) || (ActiveObjectID != ObjectID && !IsReady()) )
	{
		`RedScreen("Attempting to start new behavior tree when one is already running! @acheng");
	}
	ActiveObjectID = ObjectID;
}

function EndBehaviorTree(int ObjectID)
{
	if( IsReady() )
	{
		`RedScreen("Attempting to end behavior tree run when none is actively running! @acheng");
	}
	if( ActiveObjectID != ObjectID )
	{
		`RedScreen("Attempting to end behavior tree - object ID mismatch! @acheng");
	}
	ActiveNode = None;

	if( ActiveBTQueueEntry.RunCount > 0 )
	{
		TryStartBehaviorTreeRun();
	}
	else
	{
		ActiveObjectID = INDEX_NONE;

		//If this is the last unit in the queue, then null out the active scamper unit ID
		ActiveQueueID = ActiveBTQueue.Length == 0 ? INDEX_NONE : ActiveQueueID;
	}
}

private function AddToActiveBTQueue(BTQueueEntry QEntry)
{
	if( ActiveBTQueue.Find('ObjectID', QEntry.ObjectID) == INDEX_NONE )
	{
		ActiveBTQueue.AddItem(QEntry);
	}
}

function TryUpdateBTQueue()
{
	if( !bBTQueueTimerActive )
	{
		UpdateBTQueue();
	}
}

private function UpdateBTQueue()
{
	local XGUnit Unit;
	local XGAIBehavior Behavior;
	bBTQueueTimerActive = true;

	if( !IsReady() )
	{
		`BATTLE.SetTimer(0.1f, false, nameof(UpdateBTQueue), self);
		return;
	}

	if( ActiveQueueID > 0 )
	{
		// Check status of currently active BT.
		Unit = XGUnit(`XCOMHISTORY.GetVisualizer(ActiveQueueID));
		if( Unit != None )
		{
			Behavior = Unit.m_kBehavior;
			if( Behavior.WaitingForBTRun() )
			{
				`BATTLE.SetTimer(0.1f, false, nameof(UpdateBTQueue), self);
				return;
			}
		}

		// Not running currently active BT.  Advance.
		ActiveQueueID = INDEX_NONE;
	}

	if( ActiveBTQueue.Length > 0 )
	{
		if( bWaitingOnSquadConcealment )
		{
			if( !XComPlayerIsConcealed() )
			{
				bWaitingOnSquadConcealment = false;
			}
		}
		if( bWaitingOnEndMoveEvent || bWaitingOnSquadConcealment )
		{
			`BATTLE.SetTimer(0.1f, false, nameof(UpdateBTQueue), self);
			return;
		}
		ActiveBTQueueEntry = ActiveBTQueue[0];
		ActiveBTQueue.Remove(0, 1);
		ActiveQueueID = ActiveBTQueueEntry.ObjectID;
		TryStartBehaviorTreeRun();
		`BATTLE.SetTimer(0.1f, false, nameof(UpdateBTQueue), self);
	}
	else
	{
		`LogAI("ActiveBTQueue run complete.");
		bBTQueueTimerActive = false;
	}
}

function bool XComPlayerIsConcealed()
{
	local XComGameStateHistory History;
	local XComGameState_Player XComPlayer;
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Player', XComPlayer)
	{
		if( XComPlayer.GetTeam() == eTeam_XCom )
		{
			return XComPlayer.bSquadIsConcealed;
		}
	}
	return false;
}

// Updating to have BehaviorTreeRuns all kicked off from here.  Handle multiple runs, delays, etc here.
function TryStartBehaviorTreeRun()
{
	local XComGameStateHistory History;
	local int CurrHistoryIndex;
	local XGUnit Unit;
	local XGAIBehavior Behavior;

	History = `XCOMHISTORY;
	// Check history index restriction.  Delay start of BT if we are not yet at this history index.
	CurrHistoryIndex = History.GetCurrentHistoryIndex();
	if( CurrHistoryIndex >= ActiveBTQueueEntry.HistoryIndex )
	{
		`LogAI("BTQUEUE: Starting unit #"@ActiveBTQueueEntry.ObjectID@": "$ActiveBTQueueEntry.Node@"RunCount="$ActiveBTQueueEntry.RunCount);
		// Kick off behavior tree, and set the next BT run to start on a delay.
		if( ActiveBTQueueEntry.RunCount > 1 )
		{
			ActiveBTQueueEntry.RunCount -= 1;
		}
		else
		{
			ActiveBTQueueEntry.RunCount = 0;
		}
		`Assert(ActiveQueueID == ActiveBTQueueEntry.ObjectID);
		Unit = XGUnit(History.GetVisualizer(ActiveQueueID));
		Behavior = Unit.m_kBehavior;
		Behavior.InitTurn(false);
		if( ActiveBTQueueEntry.bSurprisedScamper )
		{
			Behavior.UseSurprisedScamperMovement();
		}
		Behavior.StartRunBehaviorTree(ActiveBTQueueEntry.Node,,ActiveBTQueueEntry.bInitFromPlayerEachRun);
	}
	else
	{
		`BATTLE.SetTimer(0.01f, false, nameof(TryStartBehaviorTreeRun), self);
	}
}

function bool IsFirstScamperUnitActive(optional out int ActiveID_out)
{
	if( ActiveQueueID > 0 && ActiveBTQueueEntry.bFirstScamper )
	{
		ActiveID_out = ActiveQueueID;
		return true;
	}
	return false;
}

simulated function bool QueueBehaviorTreeRun(XComGameState_Unit UnitState, string BTRootNode, int RunCount = 1, int StartHistoryIndex = -1, bool bScamperEntry = false, bool bFirstScamper = false, bool bSurprisedScamper = false, bool bInitFromPlayerEachRun=false)
{
	local XGUnit UnitVisualizer;
	local XComGameStateHistory History;
	local BTQueueEntry QEntry;

	History = `XCOMHISTORY;
	`assert(UnitState != none);

	UnitVisualizer = XGUnit(History.GetVisualizer(UnitState.ObjectID));
	if( UnitVisualizer == none )
	{
		`RedScreen("Error- Queued behavior tree on unit with no XGUnit visualizer!"@UnitState.GetMyTemplateName()@UnitState.ObjectID@"-acheng");
		return false;
	}
	// Attempt to initialize behavior class if not already set up.
	if( UnitVisualizer.m_kBehavior == None )
	{
		UnitVisualizer.InitBehavior();
	}
	if( UnitVisualizer.m_kBehavior == None )
	{
		`RedScreen("Error- Queued behavior tree on unit with no Behavior class!"@UnitState.GetMyTemplateName()@UnitState.ObjectID@"-acheng");
		return false;
	}

	// Force patrol group to update alertness values.
	if( UnitVisualizer.m_kBehavior.m_kPatrolGroup != None )
	{
		UnitVisualizer.m_kBehavior.m_kPatrolGroup.UpdateLastAlertLevel();
	}

	QEntry.Node = name(BTRootNode);
	QEntry.RunCount = RunCount;
	QEntry.ObjectID = UnitState.ObjectID;
	QEntry.HistoryIndex = StartHistoryIndex;
	QEntry.bScamperEntry = bScamperEntry;
	QEntry.bFirstScamper = bFirstScamper;
	QEntry.bSurprisedScamper = bSurprisedScamper;
	QEntry.bInitFromPlayerEachRun = bInitFromPlayerEachRun;
	AddToActiveBTQueue(QEntry);

	return true;
}

function bool IsQueued(int UnitID)
{
	local int Index;
	Index = ActiveBTQueue.Find('ObjectID', UnitID);
	return Index != INDEX_NONE;
}

function RemoveFromBTQueue(int UnitID, bool bScamperEntryOnly=false)
{
	local int Index;
	Index = ActiveBTQueue.Find('ObjectID', UnitID);
	if( Index != INDEX_NONE )
	{
		if( !bScamperEntryOnly || ActiveBTQueue[Index].bScamperEntry )
		{
			ActiveBTQueue.Remove(Index, 1);
		}
	}
}

function bool IsScampering(int ScamperID=INDEX_NONE, bool bLookInQueue=true)
{
	local int Index;
	local BTQueueEntry QEntry;
	if( ScamperID > 0 )
	{
		if( ActiveQueueID == ScamperID )
		{
			return ActiveBTQueueEntry.bScamperEntry;
		}

		if( bLookInQueue )
		{
			Index = ActiveBTQueue.Find('ObjectID', ScamperID);
			if( Index != INDEX_NONE )
			{
				return ActiveBTQueue[Index].bScamperEntry;
			}
		}
	}
	else
	{
		if( ActiveQueueID > 0 )
		{
			return ActiveBTQueueEntry.bScamperEntry;
		}

		if( bLookInQueue )
		{
			foreach ActiveBTQueue(QEntry)
			{
				if( QEntry.bScamperEntry )
				{
					return true;
				}
			}
		}
	}
	return false;
}

function bool IsGroupScampering(XComGameState_AIGroup GroupState)
{
	local BTQueueEntry QEntry;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_AIGroup UnitGroup;
	History = `XCOMHISTORY;
	foreach ActiveBTQueue(QEntry)
	{
		if( QEntry.bScamperEntry )
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(QEntry.ObjectID));
			UnitGroup = UnitState.GetGroupMembership();
			if( UnitGroup.ObjectID == GroupState.ObjectID )
			{
				return true;
			}
		}
	}
	return false;
}

//------------------------------------------------------------------------------------------------
defaultproperties
{
	ActiveObjectID = INDEX_NONE;
}