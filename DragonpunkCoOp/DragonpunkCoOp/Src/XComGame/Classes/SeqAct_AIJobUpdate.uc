//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_AIJobUpdate.uc
//  AUTHOR:  Alex Cheng  --  3/24/2015
//  PURPOSE: Posts and revokes Jobs from the active job listings in the AIJobManager.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class SeqAct_AIJobUpdate extends SequenceAction;

enum EJobUpdateType
{
	PostJob,				// Posts new job with given name and priority value.
	RevokeJob,				// Revokes a single job with given name.
	RevokeAllJobsWithName,	// Revokes all jobs with given name.
	RevokeAllMissionJobs,	// Revokes all mission jobs.
};

var() Name JobName;		// Job Name must correspond with an existing Job listing in DefaultAIJobs.ini
var() int JobPriority;	// Default 0 = Top priority.  Otherwise, inserts this job into Job Queue in this position.
var() EJobUpdateType UpdateType;  // Post / Revoke - single with name / Revoke all with Name / Revoke All kismet jobs
var XComGameState_Unit TargetUnit; // Target unit

event Activated()
{
	local X2AIJobManager JobMgr;
	local SeqVar_GameUnit GameUnit;
	local int TargetID;

	JobMgr = `AIJobMgr;

	TargetID = 0;
	foreach LinkedVariables(class'SeqVar_GameUnit', GameUnit, "Target Unit")
	{
		TargetID = GameUnit.IntValue;
		break;
	}

	if( UpdateType == RevokeAllMissionJobs )
	{
		JobMgr.RevokeAllKismetJobs();
	}
	else
	{
		// Check job name validity.
		if( JobMgr.IsValidJob(JobName) )
		{
			if( UpdateType == PostJob )
			{
				JobMgr.AddKismetJob(JobName, JobPriority, TargetID);
			}
			else if( UpdateType == RevokeJob )
			{
				JobMgr.RevokeKismetJob(JobName, 1, TargetID);
			}
			else if( UpdateType == RevokeAllJobsWithName )
			{
				JobMgr.RevokeKismetJob(JobName);
			}
		}
		else
		{
			`RedScreen("SeqAct_AIJobUpdate has invalid JobName listed:"@JobName);
		}
	}
}

defaultproperties
{
	ObjCategory="Gameplay"
	ObjName="AI Job Update"
	bConvertedForReplaySystem=true

	VariableLinks.Empty;
	VariableLinks(0) = (ExpectedType = class'SeqVar_GameUnit', LinkDesc = "Target Unit")
}