//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2AIJobManager.uc    
//  AUTHOR:  Alex Cheng  --  3/20/2015
//  PURPOSE: AI Job system for assigning jobs, configurable through DefaultAI.ini
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AIJobManager extends Object
	native(AI)
	config(AIJobs);

// JobInfo - defines requirements for a job, based on unit type, invalidating effects, and additional requirements.
struct native AIJobInfo
{
	var Name JobName;						// Name of this job.
	var array<Name> ValidChar;				// Job can only be filled with units of these types, or all types if empty.
	var int MoveOrderPriority;				// Priority value (1 is highest) while selecting move order.
	var array<Name> DisqualifyingEffect;	// Job can not be filled with units under these effects.
	var bool bRequiresEngagement;			// Job can only be filled with units in Red or Orange alert.

	structcpptext
	{
		FAIJobInfo()
		{
			appMemzero(this, sizeof(FAIJobInfo));
		}

		FAIJobInfo(EEventParm)
		{
			appMemzero(this, sizeof(FAIJobInfo));
		}

		FORCEINLINE UBOOL operator==(const FName &Other) const
		{
			return JobName == Other;
		}
	}
};

// MissionJobList - Defines a list of jobs to fill per Mission Type.
struct native AIMissionJobList
{
	var String MissionType;					// Should correspond to an existing mission type from XComTacticalMissionManager
	var array<Name> Job;					// Each name here should correspond to an existing JobListing (AIJobInfo.JobName).
};

var config array<AIJobInfo> JobListings; // Definition of qualifications for each job.
var config array<AIMissionJobList> MissionJobs; // list of jobs to distribute per mission;
var array<int> ActiveJobIndexToKismetJobIndex; // Keep track of which jobs were specified by Kismet.
var private native Map_Mirror CharMap{TMap<FName, TArray<INT>>}; // Maps Character Name to an array of ObjectIDs.

var AIMissionJobList ActiveJobList;				// Active job list for the current tactical mission.
var array<StateObjectReference> JobAssignments;  // Assignments corresponding to the active job list.

const DEFAULT_MISSION_NAME = "default"; // MissionName string used for the default MissionJobs entry.

var bool bJobListDirty;		// Marked true when a job is added or removed from KismetJobs.

//------------------------------------------------------------------------------------------------
native static function X2AIJobManager GetAIJobManager(); // Accessor
native function InitJobs(); // Main function to reset and update job assignments.
native function Name GetJobName(int JobIndex); // Return JobListing name given JobListing index.
native function ResetCharMap();	// Clear mapping of CharacterTemplateName - to - array-of-AI-unit-IDs-of-that-type.
native function AddToCharMap(Name CharacterType, int UnitID); // Add one UnitId to char-map.
native function bool GetIDsOfType(Name CharacterType, out array<int> UnitIDs_out);  // Get all AI unit IDs of type CharacterType.
native function bool IsValidJob(Name JobName);				// IsValidJob checks if JobName is listed in the JobListings array.

function AIJobInfo GetJobListing(Name JobName, optional out int Index)
{
	local AIJobInfo NoJob;
	Index = JobListings.Find('JobName', JobName);
	if( Index != INDEX_NONE )
	{
		return JobListings[Index];
	}
	return NoJob;
}

function EventListenerReturn OnTacticalGameBegin(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	`LogAI("Called AIJobManager::OnTacticalGameBegin");
	RevokeAllKismetJobs();
	return ELR_NoInterrupt;
}

function EventListenerReturn OnTacticalGameEnd(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	`LogAI("Called AIJobManager::OnTacticalGameEnd");
	RevokeAllKismetJobs();
	return ELR_NoInterrupt;
}

//------------------------------------------------------------------------------------------------
// Update ActiveJobList and JobAssignment values.
function Reinit()
{
	local XComGameStateHistory History;
	local XComGameState_AIUnitData AIUnitData;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
	JobAssignments.Length = 0;
	if( ShouldRebuildJobList() )
	{
		RebuildActiveJobList();
	}
	JobAssignments.Length = ActiveJobList.Job.Length;

	if( JobAssignments.Length > 0 )
	{
		foreach History.IterateByClassType(class'XComGameState_AIUnitData', AIUnitData)
		{
			if( AIUnitData.JobIndex != INDEX_NONE 
			   && AIUnitData.JobOrderPlacementNumber >= 0 && AIUnitData.JobOrderPlacementNumber < JobAssignments.Length)
			{
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AIUnitData.m_iUnitObjectID));
				if( IsUnitStateValidForCharMap(UnitState) ) // Ignore green alert non-leaders
				{
					if( JobAssignments[AIUnitData.JobOrderPlacementNumber].ObjectID > 0 )
					{
						`LogAI("Warning, overwriting job assignment #"$AIUnitData.JobOrderPlacementNumber$" - was unit#"$JobAssignments[AIUnitData.JobOrderPlacementNumber].ObjectID@" replacing with Unit#"@AIUnitData.m_iUnitObjectID);
					}
					JobAssignments[AIUnitData.JobOrderPlacementNumber].ObjectID = AIUnitData.m_iUnitObjectID;
				}
			}
		}
	}
}

// On turn init, reassign jobs when units become unsuitable for their current job.
function InitTurn()
{
	local XComGameState NewGameState;
	local int ReassignIndex;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Job Assignment");
	if( ShouldRebuildJobList() )
	{
		Reinit();
	}

	if( ActiveJobList.Job.Length > 0 )
	{
		UpdateCharMap();
		ReassignIndex = AssessCurrentAssignments(NewGameState);
		AssignJobs(ReassignIndex, NewGameState);
	}
	if( NewGameState.GetNumGameStateObjects() > 0 )
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}
}

function int GetJobIndex(Name JobName)
{
	return JobListings.Find('JobName', JobName);
}

function array<KismetPostedJob> GetKismetJobs()
{
	local array<KismetPostedJob> KismetJobs;
	local XComGameState_AIPlayerData AIPlayerData;
	local XGAIPlayer AIPlayer;
	local int AIDataID;

	AIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
	if( AIPlayer != None )
	{
		AIDataID = AIPlayer.GetAIDataID();
		AIPlayerData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(AIDataID));
		KismetJobs = AIPlayerData.KismetJobs;
	}
	return KismetJobs;
}
// Determine based on the active mission what jobs we need to fill.
function RebuildActiveJobList()
{
	local string CurrentMissionType;
	local int MissionIndex;
	local array<KismetPostedJob> KismetJobs;
	local KismetPostedJob KismetJob;
	local int JobListingIndex;
	local int KismetJobIndex, NumJobs;
	CurrentMissionType = `TACTICALMISSIONMGR.ActiveMission.sType;

	// Find a list of jobs for this mission type.
	MissionIndex = MissionJobs.Find('MissionType', CurrentMissionType);

	// If the current mission type is not listed, use the default.
	if( MissionIndex == INDEX_NONE )
	{
		MissionIndex = MissionJobs.Find('MissionType', DEFAULT_MISSION_NAME);
	}

	if( MissionIndex != INDEX_NONE )
	{
		ActiveJobList = MissionJobs[MissionIndex];

		// Fill out the ActiveJobIndexToKismetJobIndex with -1s.
		ActiveJobIndexToKismetJobIndex.Length = 0;
		for( KismetJobIndex = 0; KismetJobIndex < ActiveJobList.Job.Length; ++KismetJobIndex )
		{
			ActiveJobIndexToKismetJobIndex.AddItem(INDEX_NONE);
		}
	}

	KismetJobs = GetKismetJobs();
	NumJobs = KismetJobs.Length;
	// Kismet jobs pass.  Insert into list based on priority values.
	for( KismetJobIndex=0; KismetJobIndex < NumJobs; ++KismetJobIndex )
	{
		KismetJob = KismetJobs[KismetJobIndex];
		JobListingIndex = JobListings.Find('JobName', KismetJob.JobName);
		if( JobListingIndex != INDEX_NONE && KismetJob.PriorityValue >= 0)
		{
			if( KismetJob.PriorityValue >= ActiveJobList.Job.Length )
			{
				ActiveJobList.Job.AddItem(KismetJob.JobName);
				ActiveJobIndexToKismetJobIndex.AddItem(KismetJobIndex);
			}
			else
			{
				ActiveJobList.Job.InsertItem(KismetJob.PriorityValue, KismetJob.JobName);
				ActiveJobIndexToKismetJobIndex.InsertItem(KismetJob.PriorityValue, KismetJobIndex);
			}
		}
	}
	bJobListDirty = false;
}

// Examine the previously assigned units to determine if reassignment is necessary.
// Returns MissionJobs index of first job to be reassigned.
function int AssessCurrentAssignments( XComGameState NewGameState )
{
	local StateObjectReference UnitRef;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local int JobAssignmentIndex;
	local int NumAssignments;
	local int JobListingIndex;
	local int LastValidAssignmentIndex;

	History = `XCOMHISTORY;
	if( ActiveJobList.Job.Length > 0 )
	{
		LastValidAssignmentIndex = INDEX_NONE;
		NumAssignments = JobAssignments.Length;
		// Step through current assignments checking for qualifications.
		for( JobAssignmentIndex = 0; JobAssignmentIndex < NumAssignments; ++JobAssignmentIndex )
		{
			UnitRef = JobAssignments[JobAssignmentIndex];
			if( UnitRef.ObjectID > 0 )
			{
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
				JobListingIndex = JobListings.Find('JobName', ActiveJobList.Job[JobAssignmentIndex]);
				`Assert(JobListingIndex != INDEX_NONE);
				if( !IsSuitableForJob(UnitState, JobListingIndex, JobAssignmentIndex) )
				{
					// Clear all assignments from this job onward.  (Updated to include any previously unassigned jobs since the last valid assignment)
					ResetJobAssignments(LastValidAssignmentIndex+1, NewGameState);
					break;
				}
				LastValidAssignmentIndex = JobAssignmentIndex;
			}
			else // Currently unassigned.  See if this can now be filled.
			{
				if( JobCanBeFilled(JobAssignmentIndex) )
				{
					ResetJobAssignments(LastValidAssignmentIndex + 1, NewGameState);
					break;
				}
			}
		}
		return LastValidAssignmentIndex + 1;
	}
	return INDEX_NONE;
}

// Clear job assignments set in the AIUnitData and in the JobAssignments array.
function ResetJobAssignments(int ResetFromIndex, XComGameState NewGameState)
{
	local int JobAssignmentIndex;
	local int NumAssignments;
	local int ObjectID;
	local XComGameState_AIUnitData AIUnitData;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	NumAssignments = JobAssignments.Length;
	for( JobAssignmentIndex=ResetFromIndex; JobAssignmentIndex < NumAssignments;  ++JobAssignmentIndex )
	{
		ObjectID = JobAssignments[JobAssignmentIndex].ObjectID;
		if( ObjectID > 0 )
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));
			AIUnitData = XComGameState_AIUnitData(NewGameState.CreateStateObject(class'XComGameState_AIUnitData', UnitState.GetAIUnitDataID()));
			// Handle newly-created AI Unit Data.
			if( AIUnitData.m_iUnitObjectID != UnitState.ObjectID )
			{
				AIUnitData.Init(UnitState.ObjectID);
				NewGameState.AddStateObject(AIUnitData);
			}
			else if( AIUnitData.JobIndex != INDEX_NONE ) // Reset job assignment.
			{
				AIUnitData.JobIndex = INDEX_NONE;
				AIUnitData.JobOrderPlacementNumber = INDEX_NONE;
				NewGameState.AddStateObject(AIUnitData);
			}
			else
			{
				NewGameState.PurgeGameStateForObjectID(AIUnitData.ObjectID);
			}
		}
		JobAssignments[JobAssignmentIndex].ObjectID = INDEX_NONE;
	}
}

function bool JobCanBeFilled(int ActiveJobListIndex)
{
	local AIJobInfo JobInfo;
	local Name CharName;
	local array<int> ObjectIDs;
	local int UnitID, CurrentAssignment, JobListingIndex;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
	JobInfo = GetJobListing(ActiveJobList.Job[ActiveJobListIndex], JobListingIndex);
	foreach JobInfo.ValidChar(CharName)
	{
		if( GetIDsOfType(CharName, ObjectIDs) )
		{
			foreach ObjectIDs(UnitID)
			{
				// Only consider unassigned units, or units assigned at a lower priority job than this.
				CurrentAssignment = JobAssignments.Find('ObjectID', UnitID);
				if( CurrentAssignment == INDEX_NONE || CurrentAssignment > ActiveJobListIndex )
				{
					UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitID));
					if( IsSuitableForJob(UnitState, JobListingIndex, ActiveJobListIndex) )
					{
						return true;
					}
				}
			}
		}
	}
	return false;
}

function AssignJobs( int StartIndex, XComGameState NewGameState )
{
	local int NumJobs;
	local array<int> ObjectIDs;
	local AIJobInfo JobInfo;
	local int JobListingIndex;
	local int AssignIndex;
	local int KismetJobIndex;
	local Name CharName;
	local int UnitID;
	local XComGameState_Unit UnitState;
	local bool bJobFilled;
	local XComGameStateHistory History;
	local array<KismetPostedJob> KismetJobs;

	History = `XCOMHISTORY;
	NumJobs = ActiveJobList.Job.Length;

	if( StartIndex > INDEX_NONE && StartIndex < NumJobs )
	{
		KismetJobs = GetKismetJobs();
		// Go through job list and determine who is eligible for this job.
		for( AssignIndex = StartIndex; AssignIndex < NumJobs; ++AssignIndex )
		{
			bJobFilled = false;
			JobInfo = GetJobListing(ActiveJobList.Job[AssignIndex]);
			JobListingIndex = GetJobIndex(JobInfo.JobName);

			if( JobInfo.JobName == ActiveJobList.Job[AssignIndex] )
			{
				KismetJobIndex = ActiveJobIndexToKismetJobIndex[AssignIndex];
				// Fill kismet jobs that specify TargetID, regardless of type.
				if ( KismetJobIndex != INDEX_NONE && KismetJobs[KismetJobIndex].TargetID > 0 )
				{
					UnitState = XComGameState_Unit(History.GetGameStateForObjectID(KismetJobs[KismetJobIndex].TargetID));
					AssignUnitToJob(UnitState.GetAIUnitDataID(), JobListingIndex, AssignIndex, NewGameState);
					bJobFilled = true;
				}
				else
				{
					// Find unit to fill this job listing in order of character priority.
					foreach JobInfo.ValidChar(CharName)
					{
						if( GetIDsOfType(CharName, ObjectIDs) )
						{
							foreach ObjectIDs(UnitID)
							{
								// Only consider unassigned units.
								if( JobAssignments.Find('ObjectID', UnitID) == INDEX_NONE )
								{
									UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitID));
									if( IsSuitableForJob(UnitState, JobListingIndex, AssignIndex) )
									{
										// When unrevealed, set the entire group to the same job.
										if( UnitState.IsUnrevealedAI() )
										{
											AssignGroupToJob(UnitState, JobListingIndex, AssignIndex, NewGameState);
										}
										else
										{
											AssignUnitToJob(UnitState.GetAIUnitDataID(), JobListingIndex, AssignIndex, NewGameState);
										}
										bJobFilled = true;
										break;
									}
								}
							}
						}
						if( bJobFilled )
						{
							break;
						}
					}
				}
			}
		}
	}
}

function AssignGroupToJob(XComGameState_Unit UnitState, int JobListingIndex, int AssignOrder, XComGameState NewGameState)
{
	// Get unit's group data and add job assignment to all units in the group.
	local XComGameState_AIGroup AIGroup;
	local array<int> GroupMemberIDs;
	local int UnitID, GroupIndex;
	local XComGameState_Unit Member;
	local XComGameStateHistory History;
 	History = `XCOMHISTORY;
	AIGroup =  UnitState.GetGroupMembership();
	AIGroup.GetLivingMembers(GroupMemberIDs);
	// Assigned in reverse order so only the leader gets listed with the assignment.
	for( GroupIndex = GroupMemberIDs.Length - 1; GroupIndex >= 0; --GroupIndex )
	{
		UnitID = GroupMemberIDs[GroupIndex];
		Member = XComGameState_Unit(History.GetGameStateForObjectID(UnitID));
		if( Member != None )
		{
			AssignUnitToJob(Member.GetAIUnitDataID(), JobListingIndex, AssignOrder, NewGameState);
		}
	}
}

// Update job assignment data in AIData, and update job assignments array.
function AssignUnitToJob(int AIUnitDataID, int JobListingIndex, int AssignOrder, XComGameState NewGameState)
{
	local XComGameState_AIUnitData AIData;
	local int CurrentAssignmentIndex;
	
	AIData = XComGameState_AIUnitData(NewGameState.CreateStateObject(class'XComGameState_AIUnitData', AIUnitDataID));
	AIData.JobIndex = JobListingIndex;
	AIData.JobOrderPlacementNumber = AssignOrder;

	// Update JobAssignments array.  Clear any old value first.
	CurrentAssignmentIndex = JobAssignments.Find('ObjectID', AIData.m_iUnitObjectID);
	if( CurrentAssignmentIndex != INDEX_NONE )
	{
		JobAssignments[CurrentAssignmentIndex].ObjectID = INDEX_NONE;
	}
	// Update new value if valid index.  (possibly invalid if assigned through cheat manager)
	if(AssignOrder < JobAssignments.Length )
	{
		JobAssignments[AssignOrder].ObjectID = AIData.m_iUnitObjectID;
	}
	NewGameState.AddStateObject(AIData);
}

// Checks if the given unit id has a specific job reserved for it.  If so, checks if the job names match.
// Returns true if no job is assigned, or a job is assigned and the job names match.
function bool PassesKismetRequirements(int ObjectID, Name JobName, int ActiveJobListIndex)
{
	local int KismetIndex;
	local array<KismetPostedJob> KismetJobs;

	KismetIndex = ActiveJobIndexToKismetJobIndex[ActiveJobListIndex];
	// Check if this job index was specified by Kismet.

	KismetJobs = GetKismetJobs();
	if( KismetIndex != INDEX_NONE )
	{
		return (KismetJobs[KismetIndex].TargetID == ObjectID);
	}

	// Check if this ObjectID is already reserved by Kismet.
	KismetIndex = KismetJobs.Find('TargetID', ObjectID);
	if( KismetIndex != INDEX_NONE ) // This unit has been reserved for a kismet job.
	{
		return false; 
	}

	return true; 
}

// Suitability check, based on job listing info.
function bool IsSuitableForJob(XComGameState_Unit UnitState, int JobListingIndex, int ActiveJobListIndex)
{
	local AIJobInfo Job;
	local Name EffectName;
	local int AlertLevel;
	local XGAIBehavior AIBehavior;

	if( UnitState == None )
		return false;

	Job = JobListings[JobListingIndex];

	// Check if there exists a kismet job that requires this specific unit id.
	if( !PassesKismetRequirements(UnitState.ObjectID, Job.JobName, ActiveJobListIndex) )
		return false;

	// Check for death / bleeding out / impairment / etc.
	if( UnitState.IsDead() 
	   || UnitState.IsIncapacitated() 
	   || UnitState.IsImpaired() 
	   || UnitState.IsPanicked() )
	{
		return false;
	}

	// Check unit is under AI control.  (Mind controlled)
	if( !UnitState.ControllingPlayerIsAI() )
	{
		return false;
	}

	// Check ValidChar
	if( Job.ValidChar.Length > 0
	   && Job.ValidChar.Find(UnitState.GetMyTemplateName()) == INDEX_NONE )
	{
		return false;
	}

	// Check DisqualifyingEffect list.
	foreach Job.DisqualifyingEffect(EffectName)
	{
		if( UnitState.IsUnitAffectedByEffectName(EffectName) )
		{
			return false;
		}
	}

	if( Job.bRequiresEngagement )
	{
		AlertLevel = UnitState.GetCurrentStat(eStat_AlertLevel);
		if( UnitState.IsUnrevealedAI() ) // Unrevealed units are not engaged as well.
		{
			return false;
		}
		else if(AlertLevel != `ALERT_LEVEL_RED)
		{
			AIBehavior = XGUnit(UnitState.GetVisualizer()).m_kBehavior;
			if( !AIBehavior.IsOrangeAlert() )
			{
				return false;
			}
		}
	}

	// Ensure only leaders can be selected for unrevealed units (unless unit has a kismet pass).
	return IsUnitStateValidForCharMap(UnitState);
}

// Set up mapping of CharacterTemplateNames-to- All AI Units of that type.
function UpdateCharMap()
{
	local XComGameStateHistory History;
	local XComGameState_AIUnitData AIUnitData;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
	ResetCharMap();
	foreach History.IterateByClassType(class'XComGameState_AIUnitData', AIUnitData)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AIUnitData.m_iUnitObjectID));
		// Update - in green alert, only consider group leaders.  Skip dead and incapacitated.
		if( IsUnitStateValidForCharMap(UnitState) )
		{
			AddToCharMap(UnitState.GetMyTemplateName(), UnitState.ObjectID);
		}
	}
}

// For the purposes of maintaining group members in green alert in close proximity, 
// while in green alert, only pod leaders can be assigned jobs.  
// Remaining units in group are given the same job.
function bool IsUnitStateValidForCharMap(XComGameState_Unit UnitState)
{
	local XComGameState_AIGroup AIGroup;	
	local array<KismetPostedJob> KismetJobs;
	if( UnitState.IsDead() || UnitState.IsIncapacitated() )
	{
		return false;
	}
	KismetJobs = GetKismetJobs();
	// Kismet jobs specifying this unit state get an early-out pass.
	if( KismetJobs.Find('TargetID', UnitState.ObjectID) != INDEX_NONE ) 
	{
		return true;
	}
	// In green alert, only group leaders can be given jobs. Also unrevealed units (can be yellow and unrevealed)
	if( UnitState.IsUnrevealedAI() )
	{
		AIGroup = UnitState.GetGroupMembership();
		if( AIGroup.m_arrMembers[0].ObjectID != UnitState.ObjectID )
			return false;
	}
	return true;
}

function bool ShouldRebuildJobList()
{
	return bJobListDirty || ActiveJobList.Job.Length == 0 || ActiveJobList.MissionType != `TACTICALMISSIONMGR.ActiveMission.sType;
}


// Debugging
function ShowDebugInfo(Canvas kCanvas)
{
	local vector2d ViewportSize;
	local Engine                Engine;
	local int iX, iY;
	local int JobIndex, NumJobs;
	Engine = class'Engine'.static.GetEngine();
	Engine.GameViewport.GetViewportSize(ViewportSize);

	iX = ViewportSize.X - 384;
	iY = 150;

	kCanvas.SetDrawColor(255, 255, 255);
	kCanvas.SetPos(iX, iY);
	iY += 15;
	kCanvas.DrawText("Mission Type="@ActiveJobList.MissionType);
	kCanvas.SetPos(iX, iY);
	iY += 15;

	kCanvas.DrawText("Job Assignments:");
	NumJobs = JobAssignments.Length;
	for( JobIndex = 0; JobIndex < NumJobs; ++JobIndex )
	{
		kCanvas.SetPos(iX + 5, iY);
		iY += 15;
		if( JobAssignments[JobIndex].ObjectID > 0 )
		{
			kCanvas.DrawText(ActiveJobList.Job[JobIndex] $ "-"@JobAssignments[JobIndex].ObjectID);
		}
		else
		{
			kCanvas.DrawText(ActiveJobList.Job[JobIndex] $ "- unassigned.");
		}
	}
	if( ShouldRebuildJobList() )
	{
		iY += 15;
		kCanvas.DrawText("** Jobs System is waiting to rebuild the active job list. **");
	}
}

function AddKismetJob(Name JobName, int Priority=0, int TargetID = 0)
{
	local XComGameState_AIPlayerData AIPlayerData;
	local XGAIPlayer AIPlayer;
	local int AIDataID;

	AIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
	if( AIPlayer != None )
	{
		AIDataID = AIPlayer.GetAIDataID();
		AIPlayerData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(AIDataID));
		AIPlayerData.AddKismetJob(JobName, Priority, TargetID);
	}
}
function RevokeKismetJob(Name JobName, int Count=-1, int TargetID = 0)
{
	local XComGameState_AIPlayerData AIPlayerData;
	local XGAIPlayer AIPlayer;
	local int AIDataID;

	AIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
	if( AIPlayer != None )
	{
		AIDataID = AIPlayer.GetAIDataID();
		AIPlayerData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(AIDataID));
		AIPlayerData.RevokeKismetJob(JobName, Count, TargetID);
	}
}

function RevokeAllKismetJobs()
{
	local XComGameState_AIPlayerData AIPlayerData;
	local XGAIPlayer AIPlayer;
	local int AIDataID;

	AIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
	if( AIPlayer != None )
	{
		AIDataID = AIPlayer.GetAIDataID();
		AIPlayerData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(AIDataID));
		AIPlayerData.RevokeAllKismetJobs();
	}
}

defaultproperties
{
}