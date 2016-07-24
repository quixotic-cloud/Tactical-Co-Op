// Leaf node actions are the nodes that actually modify variables in the behavior class.
// i.e. select ability, find shot target, find path to flank, find path to improve aim, find path to target, etc.
class X2AIBTDefaultActions extends X2AIBTLeafNode
	native(AI)
	dependson(XGAIBehavior);

var delegate<BTActionDelegate> m_dActionFn;
var name m_MoveProfile;

delegate bt_status BTActionDelegate();       

protected function OnInit( int iObjectID, int iFrame )
{
	super.OnInit(iObjectID, iFrame);
	// Fill out parameters based on ParamList strings
	if( FindBTStatActionDelegate(m_ParamList, m_dActionFn) )
	{
		if( m_ParamList.Length > 0 )
		{
			`LogAI("Found stat action delegate - "$m_ParamList[0]);
		}
	}
	// Fill out delegate, ability name, and move profile as needed.
	else if (!FindBTActionDelegate(m_strName, m_dActionFn, SplitNameParam, m_MoveProfile))
	{
		`WARN("X2AIBTDefaultActions- No delegate action defined for node"@m_strName);
	}
	// For nodes with ability names, check unit if ability exists and replace with an equivalent ability if needed.
	if( SplitNameParam != '' )
	{
		ResolveAbilityNameWithUnit(SplitNameParam, m_kBehavior);
	}
}

protected function bt_status Update()
{
	local bt_status eStatus;
	// Early exit if this has already been evaluated.
	if (m_eStatus == BTS_SUCCESS || m_eStatus == BTS_FAILURE)
		return m_eStatus;

	X2AIBTBehaviorTree(Outer).ActiveNode = self;

	if (m_dActionFn != None)
	{
		eStatus = m_dActionFn();
		return eStatus;
	}
	return BTS_FAILURE;
}

static function bool IsValidMoveProfile(name MoveProfile, optional out int MoveTypeIndex_out)
{
	MoveTypeIndex_out = class'XGAIBehavior'.default.m_arrMoveWeightProfile.Find('Profile', MoveProfile);
	if( MoveTypeIndex_out != INDEX_NONE )
	{
		return true;
	}
	return false;
}

static function bool IsValidAoEProfile(name AoEProfile)
{
	if( class'XGAIBehavior'.default.AoEProfiles.Find('Profile', AoEProfile) == INDEX_NONE )
	{
		return false;
	}
	return true;
}

static event bool FindBTStatActionDelegate(array<Name> ParamList, optional out delegate<BTActionDelegate> dOutFn )
{
	if( ParamList.Length == 3 )
	{
		if( ParamList[0] == 'SetBTVar' )
		{
			dOutFn = SetBTVar;
			return true;
		}
	}
	return false;
}

static event bool FindBTActionDelegate(name strName, optional out delegate<BTActionDelegate> dOutFn, optional out name NameParam, optional out name MoveProfile)
{
	// Was hoping to use a hash map for names to delegates, but that may not be valid.
	// using switch statement for now.
	dOutFn = None;

	if (ParseNameForNameAbilitySplit(strName, "SelectAbility-", NameParam))
	{
		dOutFn = SelectAbility;
		return true;
	}
	if (ParseNameForNameAbilitySplit(strName, "SetTargetStack-", NameParam))
	{
		dOutFn = SetTargetStack;
		return true;
	}
	if (ParseNameforNameAbilitySplit(strName, "SetAbilityForFindDestination-", NameParam))
	{
		dOutFn = SetAbilityForFindDestination;
		return true;
	}
	if (ParseNameforNameAbilitySplit(strName, "FindDestination-", MoveProfile))
	{
		if (IsValidMoveProfile(MoveProfile))
		{
			dOutFn = FindDestination;
			return true;
		}
	}
	if( ParseNameforNameAbilitySplit(strName, "FindRestrictedDestination-", MoveProfile) )
	{
		if( IsValidMoveProfile(MoveProfile) )
		{
			dOutFn = FindRestrictedDestination;
			return true;
		}
	}
	if( ParseNameforNameAbilitySplit(strName, "FindClosestPointToTarget-", NameParam) )
	{
		dOutFn = FindClosestPointToTarget;
		return true;
	}
	if( ParseNameForNameAbilitySplit(strName, "RestrictToAbilityRange-", NameParam) )
	{
		dOutFn = RestrictMoveToAbilityRange;
		return true;
	}
	if( ParseNameForNameAbilitySplit(strName, "RestrictToAlliedAbilityRange-", NameParam) )
	{
		dOutFn = RestrictMoveToAlliedAbilityRange;
		return true;
	}
	if( ParseNameForNameAbilitySplit(strName, "RestrictToPotentialTargetRange-", NameParam) )
	{
		dOutFn = RestrictMoveToPotentialTargetRange;
		return true;
	}
	if( ParseNameforNameAbilitySplit(strName, "FindDestinationWithLoS-", MoveProfile) )
	{
		if (IsValidMoveProfile(MoveProfile))
		{
			dOutFn = FindDestinationWithLoS;
			return true;
		}
	}
	if (ParseNameforNameAbilitySplit(strName, "SelectAoETarget-", NameParam))
	{
		if( IsValidAoEProfile(NameParam) )
		{
			dOutFn = SelectAoETarget;
			return true;
		}
	}
	if (ParseNameforNameAbilitySplit(strName, "FindPotentialAoETargets-", NameParam))
	{
		if( IsValidAoEProfile(NameParam) )
		{
			dOutFn = FindPotentialAoETarget;
			return true;
		}
	}
	if( ParseNameForNameAbilitySplit(strName, "AddAbilityRangeWeight-", NameParam) )
	{
		dOutFn = AddAbilityRangeWeight;
		return true;
	}

	if( ParseNameForNameAbilitySplit(strName, "TargetScoreByScaledMaxStat-", NameParam) )
	{
		dOutFn = TargetScoreByScaledMaxStat;
		return true;
	}

	if( ParseNameForNameAbilitySplit(strName, "TargetScoreByScaledCurrStat-", NameParam) )
	{
		dOutFn = TargetScoreByScaledCurrStat;
		return true;
	}

	if( ParseNameForNameAbilitySplit(strName, "SetTargetAsPriority-", NameParam) )
	{
		dOutFn = SetTargetAsPriority;
		return true;
	}

	if( ParseNameForNameAbilitySplit(strName, "RestrictFromAlliesWithEffect-", NameParam) )
	{
		dOutFn = RestrictFromAlliesWithEffect;
		return true;
	}

	if( ParseNameForNameAbilitySplit(strName, "TargetScoreByScaledDistance-", NameParam) )
	{
		dOutFn = TargetScoreByScaledDistance;
		return true;
	}

	if( ParseNameForNameAbilitySplit(strName, "TargetScoreByHitChanceValue-", NameParam) )
	{
		dOutFn = TargetScoreByHitChanceValue;
		return true;
	}

	if( ParseNameForNameAbilitySplit(strName, "SetRandUnitValue-", NameParam) )
	{
		dOutFn = SetRandUnitValue;
		return true;
	}

	if( ParseNameForNameAbilitySplit(strName, "SetUnitValue-", NameParam) )
	{
		dOutFn = SetUnitValue;
		return true;
	}

	if( ParseNameForNameAbilitySplit(strName, "SetTargetPotential-", NameParam) )
	{
		dOutFn = SetTargetPotential;
		return true;
	}

	if( ParseNameForNameAbilitySplit(strName, "DoRedScreenFailure-", NameParam) )
	{
		dOutFn = DoRedScreenFailure;
		return true;
	}

	switch( strName )
	{
		case 'RestrictFromKnownEnemyLoS':
			dOutFn = RestrictFromKnownEnemyLoS;
		return true;
		case 'DisableGroupMove':
			dOutFn = DisableGroupMove;
			return true;
		break;
		case 'FindClosestPointToAxisGround':
			dOutFn = FindClosestPointToAxisGround;
			return true;
		break;
		case 'RestrictToGroundTiles':
			dOutFn = RestrictToGroundTiles;
			return true;
		break;
		
		case 'RestrictToAxisLoS':
			dOutFn = RestrictToAxisLoS;
			return true;
		break;

		case 'IncludeAlliesAsMeleeTargets':
			dOutFn = IncludeAlliesAsMeleeTargets;
			return true;
		break;

		case 'RestrictToFlanking':
			dOutFn = RestrictMoveToFlanking;
		return true;
		break;

		case 'RestrictToEnemyLoS':
			dOutFn = RestrictMoveToEnemyLoS;
			return true;
		break;
		case 'RestrictToAllyLoS':
			dOutFn = RestrictMoveToAllyLoS;
			return true;
		break;
		case 'ResetDestinationSearch':
			dOutFn = ResetDestinationSearch;
			return true;
		break;

		case 'SetPotentialTargetStack':
			dOutFn = SetPotentialTargetStack;
			return true;
			break;

		case 'SetVisiblePotentialTargetStack':
			dOutFn = SetVisiblePotentialTargetStack;
			return true;
			break;

		case 'SetPotentialAllyTargetStack':
			dOutFn = SetPotentialAllyTargetStack;
			return true;
			break;

		case 'SetNextTarget':
			dOutFn = SetNextTarget;
			return true;
			break;
		case 'SetOverwatcherStack':
			dOutFn = SetOverwatcherStack;
			return true;
			break;

		case 'SetNextOverwatcher':
			dOutFn = SetNextOverwatcher;
			return true;
			break;
		case 'SetSuppressorStack':
			dOutFn = SetSuppressorStack;
			return true;
			break;

		case 'SetNextSuppressor':
			dOutFn = SetNextSuppressor;
			return true;
			break;
		case 'AddToTargetScore':
			dOutFn = AddToTargetScore;
			return true;
		break;
		case 'UpdateBestTarget':
			dOutFn = UpdateBestTarget;
			return true;
		break;
		case 'SelectOrangeAlertAction':
			dOutFn = OrangeAlertMovement;
			return true;
		break;
		case 'SelectYellowAlertAction':
			dOutFn = YellowAlertMovement;
			return true;
		break;
		case 'SelectGreenAlertAction':
		case 'GenericMovement':
			dOutFn = GenericMovement;
			return true;
		break;
		case 'SkipMove':
			dOutFn = SkipMove;
			return true;
		break;
		case 'SetAlertDataStack':
			dOutFn = SetAlertDataStack;
			return true;
		break;
		case 'SetNextAlertData':
			dOutFn = SetNextAlertData;
			return true;
		break;
		case 'DeleteCurrentAlertData':
			dOutFn = DeleteCurrentAlertData;
			return true;
		break;
		case 'AddToAlertDataScore':
			dOutFn = AddToAlertDataScore;
			return true;
		break;
		case 'UpdateBestAlertData':
			dOutFn = UpdateBestAlertData;
			return true;
		break;
		case 'AlertDataMovementUseCover':
			dOutFn = AlertDataMovementUseCover;
			return true;
			break;
		case 'AlertDataMovementIgnoreCover':
			dOutFn = AlertDataMovementIgnoreCover;
			return true;
			break;
		case 'FindAlertDataMovementDestination':
			dOutFn = FindAlertDataMovementDestination;
			return true;
		break;
		case 'UseDashMovement':
			dOutFn = UseDashMovement;
			return true;
		break;
		case 'SetCiviliansAsEnemiesInMoveCalculation':
			dOutFn = SetCiviliansAsEnemiesInMoveCalculation;
			return true;
		case 'SetNoCoverMovement':
			dOutFn = SetNoCoverMovement;
			return true;
		case 'DoNoiseAlert':
			dOutFn = DoNoiseAlert;
			return true;
		break;
		case 'CivilianExitMap':
			dOutFn = RunCivilianExitMap;
			return true;
		break;
		case 'IgnoreHazards':
			dOutFn = IgnoreHazards;
			return true;
		break;
		case 'HeatSeekNearestUnconcealed':
			dOutFn = HeatSeekNearestUnconcealed;
			return true;
			break;
		case 'SetPotentialTargetAsCurrentTarget':
			dOutFn = SetPotentialTargetAsCurrentTarget;
			return true;
			break;
		default:
			`WARN("Unresolved behavior tree Action name with no delegate definition:"@strName);
		break;

	}
	return false;
}

function bt_status DoRedScreenFailure()
{
	local string DebugDetail;
	DebugDetail = m_kUnitState.GetMyTemplateName() @ " - Unit# "$m_kUnitState.ObjectID;
	`RedScreen(String(SplitNameParam) @ DebugDetail );
	if( m_ParamList.Length >= 1 )
	{
		`RedScreen(String(m_ParamList[0]));
	}
	return BTS_FAILURE;
}

function bt_status SetTargetPotential()
{
	local AvailableTarget Target;
	if( m_kBehavior.BT_HasTargetOption('Potential', Target) )
	{
		if( m_kBehavior.BT_SetTargetOption(SplitNameParam, Target) )
		{
			return BTS_SUCCESS;
		}
		else
		{
			`LogAIBT("Unable to set ability"@SplitNameParam@"to Potential target- Failed in SetTargetOption.");
		}
	}
	else
	{
		`LogAIBT("Unable to set ability"@SplitNameParam@"to Potential target: Potential Target does not exist.");
	}
	return BTS_FAILURE;
}

function bt_status RestrictFromKnownEnemyLoS()
{
	m_kBehavior.BT_RestrictMoveFromEnemyLoS();
	return BTS_SUCCESS;
}



function bt_status HeatSeekNearestUnconcealed()
{
	if( m_kBehavior.BT_HeatSeekNearestUnconcealed() )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetRandUnitValue()
{
	local string RandMaxString;
	local float RandMaxFloat, RandFloat;
	local EUnitValueCleanup CleanupType;

	if( m_ParamList.Length >= 1 )
	{
		RandMaxString = String(m_ParamList[0]);
		RandMaxFloat = float(RandMaxString);
		// Set new value.
		RandFloat = `SYNC_FRAND() * RandMaxFloat;
		`LogAIBT("SetRandUnitValue Rand("$RandMaxFloat$") returned:"@RandFloat);
		// Allow optional second parameter to specify when to clear the unit value.
		if( m_ParamList.Length == 2 && m_ParamList[1] != '0' )
		{
			// Param[1] set == CleanUpTurn.
			CleanupType = eCleanup_BeginTurn;
		}
		else
		{
			CleanupType = eCleanup_BeginTactical;
		}

		SetUnitValue_Internal(SplitNameParam, RandFloat, CleanupType);
		return BTS_SUCCESS;
	}
	`LogAIBT("SetRandUnitValue failed - No Param[0] defined for max rand value!");
	return BTS_FAILURE;
}

function bt_status SetUnitValue()
{
	local EUnitValueCleanup CleanupType;
	local string StringParam;
	local float FloatValue;
	if( m_ParamList.Length >= 1 )
	{
		// Allow optional second parameter to specify when to clear the unit value.
		if( m_ParamList.Length == 2 && m_ParamList[1] != '0' )
		{
			// Param[1] set == CleanUpTurn.
			CleanupType = eCleanup_BeginTurn;
		}
		else
		{
			CleanupType = eCleanup_BeginTactical;
		}

		StringParam = String(m_ParamList[0]);
		FloatValue = float(StringParam);
		SetUnitValue_Internal(SplitNameParam, FloatValue, CleanupType);
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function SetUnitValue_Internal( Name ValueName, float FloatValue, EUnitValueCleanup CleanupType )
{
	local XComGameState NewGameState;
	local XComGameState_Unit NewUnitState;

	`LogAIBT("Setting Unit Value"@ValueName@" to "$FloatValue);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("BehaviorTree - SetUnitValue");
	NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', m_kUnitState.ObjectID));
	NewUnitState.SetUnitFloatValue(ValueName, FloatValue, CleanupType);
	NewGameState.AddStateObject(NewUnitState);
	`GAMERULES.SubmitGameState(NewGameState);
}

function bt_status TargetScoreByHitChanceValue()
{
	local float ScaleValue, HitChance;
	local string strParam;
	HitChance = m_kBehavior.BT_GetHitChanceOnTarget();

	if( m_ParamList.Length >= 1 ) // Check for a scalar value.
	{
		if( m_ParamList.Length == 2 ) // Find hit chance on alternate ability.
		{
			HitChance = m_kBehavior.BT_GetHitChanceOnTarget(m_ParamList[1]);
			`LogAIBT("Hit Chance on ability "$m_ParamList[1]$"= "$HitChance@"\n");
		}
		strParam = String(m_ParamList[0]);
		ScaleValue = float(strParam);
		HitChance *= ScaleValue;
		`LogAIBT("Multiplied by param[0] ("$ScaleValue$")");
	}
	`LogAIBT("Scaled HitChance = "$HitChance@"\n");
	m_kBehavior.BT_AddToTargetScore(HitChance, m_strName);
	return BTS_SUCCESS;
}
function bt_status TargetScoreByScaledDistance()
{
	local float ScaleValue, DistMeters;
	local string strParam;
	local XComGameState_Unit TargetUnitState;
	local GameRulesCache_VisibilityInfo VisInfo;
	if( m_ParamList.Length == 1 )
	{
		if( m_kBehavior.BT_GetTarget(TargetUnitState) )
		{
			strParam = String(m_ParamList[0]);
			ScaleValue = float(strParam);
			if (`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(m_kUnitState.ObjectID, TargetUnitState.ObjectID, VisInfo)
				&& VisInfo.bClearLOS ) // DefaultTargetDist isn't valid if visibility check fails.
			{
				DistMeters = Sqrt(VisInfo.DefaultTargetDist);
			}
			else
			{
				DistMeters = m_kBehavior.GetDistanceFromEnemy(TargetUnitState);
			}
			DistMeters = `UNITSTOMETERS(DistMeters);
			`LogAIBT("TargetScoreByScaledDistance: Distance = "@DistMeters@"\nScale value="$ScaleValue);
			DistMeters *= ScaleValue;
			m_kBehavior.BT_AddToTargetScore(DistMeters, m_strName);
			return BTS_SUCCESS;
		}
		else
		{
			`LogAIBT("BT ERROR: TargetScoreByScaledDistance failed: No Target specified!  (Within SetTargetStack?)");
		}
	}
	`LogAIBT("BT ERROR: TargetScoreByScaledDistance failed: No scalar Param value specified!");
	return BTS_FAILURE;
}

function bt_status TargetScoreByScaledMaxStat()
{
	local int nScore;
	local float ScaleValue;
	local ECharStatType StatType;
	local string strParam;
	local XComGameState_Unit TargetUnitState;
	if( m_ParamList.Length == 1 )
	{
		if( m_kBehavior.BT_GetTarget(TargetUnitState) )
		{
			strParam = String(m_ParamList[0]);
			ScaleValue = float(strParam);
			strParam = String(SplitNameParam);
			StatType = FindStatByName(strParam);
			nScore = TargetUnitState.GetMaxStat(StatType);
			`LogAIBT("TargetScoreByScaledMaxStat: MaxStat("$strParam$")="@nScore@"\nScale value="$ScaleValue);
			nScore *= ScaleValue;
			m_kBehavior.BT_AddToTargetScore(nScore, m_strName);
			return BTS_SUCCESS;
		}
		else
		{
			`LogAIBT("BT ERROR: TargetScoreByScaledMaxStat failed: No Target specified!  (Within SetTargetStack?)");
		}
	}
	`LogAIBT("BT ERROR: TargetScoreByScaledMaxStat failed: No scalar Param value specified!");
	return BTS_FAILURE;
}

function bt_status RestrictFromAlliesWithEffect()
{
	local float MinDistance;
	local string strParam;
	if( m_ParamList.Length == 1 )
	{
		strParam = String(m_ParamList[0]);
		MinDistance = float(strParam);
		m_kBehavior.BT_RestrictFromAlliesWithEffect(SplitNameParam, MinDistance);
		return BTS_SUCCESS;
	}
	`LogAIBT("BT ERROR: RestrictFromAlliesWithEffect failed: No DISTANCE Param value specified!");

	return BTS_FAILURE;
}

function bt_status RestrictToAxisLoS()
{
	m_kBehavior.BT_RestrictToAxisLoS();
	return BTS_SUCCESS;
}

function bt_status RestrictToGroundTiles()
{
	m_kBehavior.BT_RestrictToGroundTiles();
	return BTS_SUCCESS;
}

function bt_status SetTargetAsPriority()
{
	if (m_kBehavior.BT_SetTargetAsPriority(SplitNameParam))
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status TargetScoreByScaledCurrStat()
{
	local int nScore;
	local float ScaleValue;
	local ECharStatType StatType;
	local string strParam;
	local XComGameState_Unit TargetUnitState;
	if( m_ParamList.Length == 1 )
	{
		if( m_kBehavior.BT_GetTarget(TargetUnitState) )
		{
			strParam = String(m_ParamList[0]);
			ScaleValue = float(strParam);
			strParam = String(SplitNameParam);
			StatType = FindStatByName(strParam);
			nScore = TargetUnitState.GetCurrentStat(StatType);
			`LogAIBT("TargetScoreByScaledCurrStat: CurrStat("$strParam$")="@nScore@"\nScale value="$ScaleValue);
			nScore *= ScaleValue;
			m_kBehavior.BT_AddToTargetScore(nScore, m_strName);
			return BTS_SUCCESS;
		}
		else
		{
			`LogAIBT("BT ERROR: TargetScoreByScaledMaxStat failed: No Target specified!  (Within SetTargetStack?)");
		}
	}
	`LogAIBT("BT ERROR: TargetScoreByScaledCurrStat failed: No scalar Param value specified!");
	return BTS_FAILURE;
}

function bt_status AddAbilityRangeWeight()
{
	local string ParamString;
	local float Weight;
	if( m_ParamList.Length == 1 )
	{
		ParamString = String(m_ParamList[0]);
		Weight = float(ParamString);
	}
	else
	{
		Weight = 1.0f;
	}
	if( m_kBehavior.BT_AddAbilityRangeWeight(SplitNameParam, Weight) )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}


function bt_status IgnoreHazards()
{
	m_kBehavior.BT_IgnoreHazards();
	return BTS_SUCCESS;
}

function bt_status SkipMove()
{
	m_kBehavior.BT_SkipMove();
	return BTS_SUCCESS;
}

function bt_status FindPotentialAoETarget()
{
	if (m_kBehavior.BT_FindPotentialAoETarget(SplitNameParam))
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SelectAoETarget()
{
	if (m_kBehavior.BT_SelectAoETarget(SplitNameParam))
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}
// Handle any movement for non-red-alert units.
function bt_status GenericMovement()
{
	if (m_kBehavior.BTHandleGenericMovement())
	{
		return BTS_SUCCESS;
	}
	// This is an acceptable failure for units that have nothing to do now.  (i.e. guards on green alert.)
	return BTS_FAILURE;
}

function bt_status SetBTVar()
{
	if( m_kBehavior.BT_SetBTVar(String(m_ParamList[1]), int(String(m_ParamList[2])) ))
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SelectAbility()
{
	local String DebugText;
	if (m_kBehavior.IsValidAbility(SplitNameParam, DebugText))
	{
		if( m_ParamList.Length > 0 && m_ParamList[0] == 'UseDestination' )
		{
			if( m_kBehavior.m_bBTDestinationSet )
			{
				m_kBehavior.bSetDestinationWithAbility = true;
			}
			else
			{
				`LogAIBT("Attempted to SelectAbility with param[0] UseDestination, when no destination has been set!");
				m_kBehavior.bSetDestinationWithAbility = false;
				return BTS_FAILURE;
			}
		}
		else
		{
			m_kBehavior.bSetDestinationWithAbility = false;
		}

		// Wait until next tick to execute the ability.
		if( !m_kBehavior.WaitForExecuteAbility )
		{
			m_kBehavior.WaitForExecuteAbility = true;
			return BTS_RUNNING;
		}

		m_kBehavior.WaitForExecuteAbility = false;
		// Mark ability as selected.
		m_kBehavior.m_strBTAbilitySelection = SplitNameParam;
		
		return BTS_SUCCESS;
	}
	else
	{
		`LogAIBT("IsValidAbility-"$SplitNameParam@"returned false!  Reason:"@DebugText);
	}
	return BTS_FAILURE;
}

function bt_status SetAbilityForFindDestination()
{
	local AvailableAction kAbility;
	kAbility = m_kBehavior.GetAvailableAbility(string(SplitNameParam), true);
	if (kAbility.AbilityObjectRef.ObjectID > 0)
	{
		m_kBehavior.BT_SetAbilityForDestination(kAbility);
		return BTS_SUCCESS;
	}
	`LogAIBT("SetAbilityForFindDestination failed - Ability not found:"$SplitNameParam);
	return BTS_FAILURE;
}

function bt_status SetTargetStack()
{
	if( m_kBehavior.BT_SetTargetStack(SplitNameParam) )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

// SetPotentialTargetStack - Consider all enemies. Certain target functions (i.e. TargetHitChance) won't be applicable for this.
function bt_status SetPotentialTargetStack()
{
	if( m_kBehavior.BT_SetPotentialTargetStack() )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

// SetVisiblePotentialTargetStack - Consider all visible enemies (within LoS).
function bt_status SetVisiblePotentialTargetStack()
{
	if( m_kBehavior.BT_SetPotentialTargetStack(true) )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

// SetPotentialAllyTargetStack - Consider all Allies. Certain target functions (i.e. TargetHitChance) won't be applicable for this.
function bt_status SetPotentialAllyTargetStack()
{
	if( m_kBehavior.BT_SetPotentialAllyTargetStack() )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetNextTarget()
{
	if (m_kBehavior.BT_SetNextTarget())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetOverwatcherStack()
{
	if( m_kBehavior.BT_SetOverwatcherStack() )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetNextOverwatcher()
{
	if( m_kBehavior.BT_SetNextOverwatcher() )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetSuppressorStack()
{
	if( m_kBehavior.BT_SetSuppressorStack() )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetNextSuppressor()
{
	if( m_kBehavior.BT_SetNextSuppressor() )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status FindDestination()
{
	local int MoveTypeIndex;
	if( IsValidMoveProfile(m_MoveProfile, MoveTypeIndex) )
	{
		return m_kBehavior.BT_FindDestination(MoveTypeIndex);
	}
	return BTS_FAILURE;
}

function bt_status ResetDestinationSearch()
{
	m_kBehavior.BT_ResetDestinationSearch();
	return BTS_SUCCESS;
}

function bt_status FindRestrictedDestination()
{
	local int MoveTypeIndex;
	if (IsValidMoveProfile(m_MoveProfile, MoveTypeIndex))
	{
		return m_kBehavior.BT_FindDestination(MoveTypeIndex, true);
	}
	return BTS_FAILURE;
}

function bt_status FindClosestPointToTarget()
{
	if( m_kBehavior.BT_FindClosestPointToTarget(SplitNameParam) )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status DisableGroupMove()
{
	m_kBehavior.BT_DisableGroupMove();
	return BTS_SUCCESS;
}

function bt_status FindClosestPointToAxisGround()
{
	if( m_kBehavior.BT_FindClosestPointToAxisGround() )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status RestrictMoveToAbilityRange()
{
	if( m_kBehavior.BT_RestrictMoveToAbilityRange(SplitNameParam) )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status RestrictMoveToAlliedAbilityRange()
{
	local string strParam;
	local int MinTargetCount;
	if( m_ParamList.Length == 1 )
	{
		strParam = string(m_ParamList[0]);
		MinTargetCount = int(strParam);
	}
	if( m_kBehavior.BT_RestrictMoveToAbilityRange(SplitNameParam, MinTargetCount) )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status RestrictMoveToPotentialTargetRange()
{
	if( m_kBehavior.BT_RestrictMoveToPotentialTargetRange(SplitNameParam) )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status IncludeAlliesAsMeleeTargets()
{
	m_kBehavior.BT_IncludeAlliesAsMeleeTargets();
	return BTS_SUCCESS;
}

function bt_status RestrictMoveToFlanking()
{
	m_kBehavior.BT_RestrictMoveToFlanking();
	return BTS_SUCCESS;
}

function bt_status RestrictMoveToEnemyLoS()
{
	m_kBehavior.BT_RestrictMoveToEnemyLoS();
	return BTS_SUCCESS;
}

function bt_status RestrictMoveToAllyLoS()
{
	m_kBehavior.BT_RestrictMoveToAllyLoS();
	return BTS_SUCCESS;
}

function bt_status FindDestinationWithLoS()
{
	local int MoveTypeIndex;
	if (IsValidMoveProfile(m_MoveProfile, MoveTypeIndex))
	{
		return m_kBehavior.BT_FindDestinationWithLOS(MoveTypeIndex);
	}
	return BTS_FAILURE;
}

function bt_status AddToTargetScore()
{
	local int nScore;
	local string strParam;
	if (m_ParamList.Length == 1)
	{
		strParam = string(m_ParamList[0]);
		nScore = int(strParam);
		m_kBehavior.BT_AddToTargetScore(nScore);
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status UpdateBestTarget()
{
	m_kBehavior.BT_UpdateBestTarget();
	return BTS_SUCCESS;
}

function bt_status SetAlertDataStack()
{
	if (m_kBehavior.BT_SetAlertDataStack())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetNextAlertData()
{
	if (m_kBehavior.BT_SetNextAlertData())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status DeleteCurrentAlertData()
{
	m_kBehavior.BT_MarkAlertDataForDeletion();
	return BTS_SUCCESS;
}

function bt_status AddToAlertDataScore()
{
	local int nScore;
	local string strParam;
	if (m_ParamList.Length == 1)
	{
		strParam = string(m_ParamList[0]);
		nScore = int(strParam);
		m_kBehavior.BT_AddToAlertDataScore(nScore);
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status UpdateBestAlertData()
{
	m_kBehavior.BT_UpdateBestAlertData();
	return BTS_SUCCESS;
}

function bt_status AlertDataMovementUseCover()
{
	m_kBehavior.BT_AlertDataMovementUseCover();
	return BTS_SUCCESS;
}

function bt_status AlertDataMovementIgnoreCover()
{
	m_kBehavior.m_bAlertDataMovementUseCover = false;
	return BTS_SUCCESS;
}

function bt_status FindAlertDataMovementDestination()
{
	if (m_kBehavior.BT_FindAlertDataMovementDestination())
	{
		return BTS_SUCCESS;
	}

	return BTS_FAILURE;
}

function bt_status UseDashMovement()
{
	m_kBehavior.BT_SetCanDash();
	return BTS_SUCCESS;
}

function bt_status SetCiviliansAsEnemiesInMoveCalculation()
{
	m_kBehavior.BT_SetCiviliansAsEnemiesInMoveCalculation();
	return BTS_SUCCESS;
}

function bt_status SetNoCoverMovement()
{
	m_kBehavior.BT_SetNoCoverMovement();
	return BTS_SUCCESS;
}

function bt_status DoNoiseAlert() // contents basically stolen from SeqAct_DropAlert
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local AlertAbilityInfo AlertInfo;
	local XComGameState_Unit kUnitState;
	local XComGameState_AIUnitData NewUnitAIState, kAIData;

	History = `XCOMHISTORY;

	// Kick off mass alert to location.
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "BehaviorTree - DoNoiseAlert" );

	AlertInfo.AlertTileLocation = m_kUnitState.TileLocation;
	AlertInfo.AlertRadius = 1000;
	AlertInfo.AlertUnitSourceID = m_kUnitState.ObjectID;
	AlertInfo.AnalyzingHistoryIndex = History.GetCurrentHistoryIndex( ); //NewGameState.HistoryIndex; <- this value is -1.

	foreach History.IterateByClassType( class'XComGameState_AIUnitData', kAIData )
	{
		kUnitState = XComGameState_Unit( History.GetGameStateForObjectID( kAIData.m_iUnitObjectID ) );
		if (kUnitState != None && kUnitState.IsAlive( ))
		{
			NewUnitAIState = XComGameState_AIUnitData( NewGameState.CreateStateObject( kAIData.Class, kAIData.ObjectID ) );
			if( NewUnitAIState.AddAlertData( kAIData.m_iUnitObjectID, eAC_AlertedByYell, AlertInfo, NewGameState ) )
			{
				NewGameState.AddStateObject(NewUnitAIState);
			}
			else
			{
				NewGameState.PurgeGameStateForObjectID(NewUnitAIState.ObjectID);
			}
		}
	}

	if( NewGameState.GetNumGameStateObjects() > 0 )
	{
		`GAMERULES.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	return BTS_SUCCESS;
}

function bt_status RunCivilianExitMap()
{
	return CivilianExitMap(m_kUnitState);
}

function bt_status SetPotentialTargetAsCurrentTarget()
{
	local AvailableTarget TargetChoice;
	TargetChoice = m_kBehavior.BT_GetBestTarget('Potential');
	if( TargetChoice.PrimaryTarget.ObjectID > 0 )
	{
		m_kBehavior.BT_InitNextTarget(TargetChoice);
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

static function bt_status CivilianExitMap( XComGameState_Unit UnitState ) 
{
	local XComParcelManager ParcelManager;
	local XComWorldData WorldData;
	local XGUnit UnitVisualizer;
	local array<Vector> SpawnLocations;
	local array<TTile> PathTiles;
	local XComGameState NewGameState;
	local XComGameState NewGameState2;
	local TTile EndTile;
	local XComGameStateHistory History;
	local X2TacticalGameRuleset TacticalRules;

	local int HistoryIndex;
	local XComGameState AssociatedGameStateFrame;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit CurrentRescuerUnit;
	local XComGameState_Unit NewRescuerUnit;



	History = `XCOMHISTORY;
	TacticalRules = `TACTICALRULES;

	// Find the soldier that rescued the civilian, and setup and submit a new XComGameState
	// for that soldier, with an associated visualization function.
	for( HistoryIndex = History.GetCurrentHistoryIndex(); HistoryIndex >= History.GetEventChainStartIndex(); --HistoryIndex )
	{
		AssociatedGameStateFrame = History.GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);
		AbilityContext = XComGameStateContext_Ability(AssociatedGameStateFrame.GetContext());
		if( AbilityContext != none )
		{
			if( AbilityContext.InputContext.AbilityTemplateName == 'StandardMove' || AbilityContext.InputContext.AbilityTemplateName == 'Grapple' )
			{
				CurrentRescuerUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

				NewGameState2 = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Behavior Tree - CivilianExitMap: " @ CurrentRescuerUnit.GetVisualizer( ) @ " (" @ CurrentRescuerUnit.ObjectID @ ")" );

				NewRescuerUnit = XComGameState_Unit(NewGameState2.CreateStateObject(class'XComGameState_Unit',CurrentRescuerUnit.ObjectID));
				NewGameState2.AddStateObject(NewRescuerUnit);
				NewGameState2.GetContext().PreBuildVisualizationFn.AddItem(NewRescuerUnit.SoldierRescuesCivilian_BuildVisualization);

				`XEVENTMGR.TriggerEvent('CivilianRescued', NewRescuerUnit, UnitState, NewGameState2);
				TacticalRules.SubmitGameState(NewGameState2);
				break;
			}
		}
	}

	if( CurrentRescuerUnit == none )
	{
		`Redscreen("Behavior Tree - CivilianExitMap: Unable to find the rescuing xcom soldier.  Speak to mdomowicz.");
	}

	if( UnitState.GetTeam() != eTeam_Neutral )
	{
		`Redscreen("Behavior Tree - CivilianExitMap: Attempting to rescue a non-civilian unit.");
		return BTS_FAILURE;
	}

	// find the spawn location tile
	ParcelManager = `PARCELMGR;
	ParcelManager.SoldierSpawn.GetValidFloorLocations( SpawnLocations );

	WorldData = `XWORLD;
	WorldData.GetFloorTileForPosition( SpawnLocations[ 0 ], EndTile );

	UnitVisualizer = XGUnit(UnitState.GetVisualizer());
	if( UnitVisualizer != none )
	{
		// have them run toward the spawn location if there is a way to get there
		if( !class'X2PathSolver'.static.BuildPath(UnitState, UnitState.TileLocation, EndTile, PathTiles, false) )
		{
			// If the unit can't find a path, then just path anywhere it can.
			UnitVisualizer.m_kReachableTilesCache.GetAllPathableTiles(PathTiles);
			if( PathTiles.Length > 0 )
			{
				EndTile = PathTiles[PathTiles.Length - 1];
				PathTiles.Length = 0;
				if( !class'X2PathSolver'.static.BuildPath(UnitState, UnitState.TileLocation, EndTile, PathTiles, false) )
				{
					`Warn("CivilianExitMap - could not build path to destination!  Rescue movement will be skipped.");
				}
			}
			else
			{
				`Warn("CivilianExitMap - Unit has no pathable tiles!  Rescue movement will be skipped.");
			}
		}

		// truncate it to just the beginning part of the path. They don't need to go the entire way, just enough to
		// see them move
		if( PathTiles.Length > 0 )
		{
			PathTiles.Length = min(PathTiles.Length, 6);
			XComTacticalController(UnitVisualizer.GetOwningPlayerController()).GameStateMoveUnitSingle(UnitVisualizer, PathTiles);
		}
		// Since this moves the unit for the AI, we don't need the AI to process anything further.
		if( UnitVisualizer.m_kBehavior != None )
		{
			UnitVisualizer.m_kBehavior.BT_SkipMove();
		}

		// and then they exit the level
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Behavior Tree - CivilianExitMap: " @ UnitState.GetVisualizer() @ " (" @ UnitState.ObjectID @ ")");
		UnitState.EvacuateUnit(NewGameState);

		TacticalRules.SubmitGameState(NewGameState);

		if( PathTiles.Length > 0 )
		{
			return BTS_SUCCESS;
		}
	}
	else
	{
		`RedScreen("CivilianExitMap - Unit visualizer not found!");
	}
	return BTS_FAILURE;
}

function bt_status OrangeAlertMovement()
{
	if (m_kBehavior.BT_HandleOrangeAlertMovement())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status YellowAlertMovement()
{
	if (m_kBehavior.BT_HandleYellowAlertMovement())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}
//------------------------------------------------------------------------------
// Functions used for debugging 
function string GetNodeDetails(const out array<BTDetailedInfo> TraversalData)
{
	local string strText;
	local name Param;
	local int iParam;
	strText = super.GetNodeDetails(TraversalData);

	strText @= "ACTION    Param count="$m_ParamList.Length$"\n";

	if (m_dActionFn != None)
	{
		strText @= "delegate="$string(m_dActionFn)$"\n";
	}

	if (SplitNameParam != '')
	{
		strText @= "Ability Name="$string(SplitNameParam)@"\n";
	}

	for (iParam=0; iParam<m_ParamList.Length; iParam++)
	{
		Param = m_ParamList[iParam];
		strText @= "(Param "$iParam$")"@Param@"\n";
	}
	return 	strText;
}
//------------------------------------------------------------------------------------------------
defaultproperties
{
}