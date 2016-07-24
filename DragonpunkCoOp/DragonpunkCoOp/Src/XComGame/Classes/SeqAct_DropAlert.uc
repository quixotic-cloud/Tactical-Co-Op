class SeqAct_DropAlert extends SequenceAction;
var XComGameState_Unit AlertUnit; // Target unit
var XComGameState_InteractiveObject AlertObject;
var Actor AlertActor; // Alert object, used only for it's immediate location.
var Vector AlertLocation;	 // Alert Location.  Used only when alert object is not set.
var() String KismetTag; // Tag for behavior tree assignment to distinguish different alerts (offensive vs defensive, etc)
var() bool bSingleton; // If Singleton, this alert overwrites any other alert data with the same KismetTag.
var() bool bIsHostile; // if bIsHostile, this will cause a Hotile MapwideAlert. Otherwise it will be a Peaceful MapwideAlert

event Activated()
{
	local XComGameState NewGameState;
	local XComGameState_AIUnitData NewUnitAIState, kAIData;
	local XComGameState_Unit kUnitState;
	local XComGameStateHistory History;
	local AlertAbilityInfo AlertInfo;
	local SeqVar_InteractiveObject TargetSeqObj;
	local SeqVar_GameUnit kGameUnit;
	local SeqVar_Object kTargetObj;
	local SeqVar_Vector kTargetLoc;
	local int NumAlerted, NumFailed;
	local EAlertCause AlertCause;

	History = `XCOMHISTORY;

	foreach LinkedVariables(class'SeqVar_GameUnit',kGameUnit,"Alert Unit")
	{
		AlertUnit = XComGameState_Unit(History.GetGameStateForObjectID(kGameUnit.IntValue));
		break;
	}

	foreach LinkedVariables(class'SeqVar_InteractiveObject',TargetSeqObj,"Alert Interactive Object")
	{
		AlertObject = TargetSeqObj.GetInteractiveObject();
		break;
	}

	foreach LinkedVariables(class'SeqVar_Object', kTargetObj, "Alert Actor")
	{
		AlertActor = Actor(kTargetObj.GetObjectValue());
		break;
	}

	foreach LinkedVariables(class'SeqVar_Vector', kTargetLoc, "Alert Location")
	{
		AlertLocation = kTargetLoc.VectValue;
		break;
	}

	if (AlertUnit == None && AlertObject == None && AlertActor == none)
	{
		if (AlertLocation == vect(0,0,0))
		{
			`RedScreen("SeqAct_DropAlert activated with no valid AlertUnit or AlertObject or AlertActor or set with AlertLocation at (0,0,0)");
		}
	}
	else
	{
		if (AlertUnit != None)
			AlertLocation = `XWORLD.GetPositionFromTileCoordinates(AlertUnit.TileLocation);
		else if (AlertObject != None)
			AlertLocation = `XWORLD.GetPositionFromTileCoordinates(AlertObject.TileLocation);
		else
			AlertLocation = AlertActor.Location;
	}

	// Kick off mass alert to location.
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Kismet - DropAlert");
	AlertInfo.AlertTileLocation = `XWORLD.GetTileCoordinatesFromPosition(AlertLocation);
	AlertInfo.AlertRadius = 1000;
	AlertInfo.AlertUnitSourceID = 0;
	AlertInfo.AnalyzingHistoryIndex = History.GetCurrentHistoryIndex(); //NewGameState.HistoryIndex; <- this value is -1.
	foreach History.IterateByClassType(class'XComGameState_AIUnitData', kAIData)
	{
		kUnitState = XComGameState_Unit(History.GetGameStateForObjectID(kAIData.m_iUnitObjectID));
		if (kUnitState != None && kUnitState.IsAlive())
		{
			NewUnitAIState = XComGameState_AIUnitData(NewGameState.CreateStateObject(kAIData.Class, kAIData.ObjectID));

			AlertCause = eAC_MapwideAlert_Hostile;
			if( !bIsHostile )
			{
				AlertCause = eAC_MapwideAlert_Peaceful;
			}

			if( NewUnitAIState.AddAlertData(kAIData.m_iUnitObjectID, AlertCause, AlertInfo, NewGameState, KismetTag, bSingleton) )
			{
				NewGameState.AddStateObject(NewUnitAIState);
				++NumAlerted;
			}
			else
			{
				NewGameState.PurgeGameStateForObjectID(NewUnitAIState.ObjectID);
				++NumFailed;
			}
		}
	}
	`LogAI("AddAlertData for KismetAlert ("$KismetTag$") to"@NumAlerted@"AI units. ("@NumFailed@" failures)");

	if( NewGameState.GetNumGameStateObjects() > 0 )
	{
		`GAMERULES.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

defaultproperties
{
	ObjCategory="Gameplay"
	ObjName="Drop Alert"
	bConvertedForReplaySystem=true
	bSingleton=true
	bIsHostile=true

	VariableLinks.Empty;
	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Alert Unit")
	VariableLinks(1)=(ExpectedType=class'SeqVar_InteractiveObject', LinkDesc="Alert Interactive Object")
	VariableLinks(2)=(ExpectedType=class'SeqVar_Object',LinkDesc="Alert Actor")
	VariableLinks(3)=(ExpectedType=class'SeqVar_Vector',LinkDesc="Alert Location")
}