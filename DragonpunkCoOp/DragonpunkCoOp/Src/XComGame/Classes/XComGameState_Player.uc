//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Player.uc
//  AUTHOR:  Ryan McFall  --  10/10/2013
//  PURPOSE: This object represents the instance data for a player in the tactical game for
//           X-Com
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_Player extends XComGameState_BaseObject native(Core)
	dependson(XComOnlineStatsUtils)
	implements(X2VisualizedInterface);

var() Name				PlayerClassName;
var() ETeam				TeamFlag;
var() string			PlayerName;
var() bool				bPlayerReady;       // Is the player sync'd and ready to progress?
var() bool				bAuthority;
var() bool				bSquadIsConcealed;	// While true, the entire squad for this player is considered concealed against the enemy player.
var() int				SquadCohesion;      // Only relevant to single player XCom team
var() int				TurnsSinceCohesion;
var() array<name>       SoldierUnlockTemplates;
var() int				SquadPointValue;
var() bool              MicAvailable;
var() string			SquadName;
var() int		        MissStreak;
var() int			    HitStreak;
var() privatewrite int  TurnsSinceEnemySeen; // set to 0 when an enemy is seen 

var int                 PlayerTurnCount;

var int                 PlayerUniqueNetIdA, PlayerUniqueNetIdB; // Would have made this a UniqueNetId, however, the native struct does not get serialized properly and will erase the value. Instead using this int HACK.
var array<MatchData>    PlayerOnlineMatchData;

struct native ability_player_cooldown
{
	var name strAbility; 
	var int  iCooldown;
};
var() array<ability_player_cooldown> m_arrCooldownList;

function SetInitialState(XGPlayer Visualizer)
{
	PlayerClassName = Name( string(Visualizer.Class) );
	TeamFlag = Visualizer.m_eTeam;
}

function OnBeginTacticalPlay()
{
	local X2EventManager EventManager;
	local Object ThisObj;

	super.OnBeginTacticalPlay();

	XGPlayer(GetVisualizer()).OnBeginTacticalPlay();

	EventManager = class'X2EventManager'.static.GetEventManager();
	ThisObj = self;
	EventManager.RegisterForEvent(ThisObj, 'ObjectVisibilityChanged', OnObjectVisibilityChanged, ELD_OnStateSubmitted);
	EventManager.RegisterForEvent(ThisObj, 'PlayerTurnBegun', OnPlayerTurnBegun, ELD_OnStateSubmitted);
}

function Actor FindOrCreateVisualizer( optional XComGameState Gamestate = none )
{
	return none;
}

function SyncVisualizer(optional XComGameState GameState = none)
{
	local XGAIPlayer_Civilian Civilian;
	local XGAIPlayer PlayerVisualizer;
	local XGAIGroup CurrentGroup;

	// Handle Civilian Pod Idles
	Civilian = XGAIPlayer_Civilian(GetVisualizer());
	if( Civilian != None )
	{
		Civilian.UpdatePodIdles();
	}

	// Handle AIGroup Pod Idles
	PlayerVisualizer = XGAIPlayer(GetVisualizer());

	if (PlayerVisualizer != none)
	{
		// Ensure our groups are setup
		PlayerVisualizer.Init();
		if (PlayerVisualizer.m_kNav != none)
			PlayerVisualizer.m_kNav.RefreshGroups();
	}

	// Now loop through and find all the groups that belong to us
	foreach `XWORLDINFO.AllActors(class'XGAIGroup', CurrentGroup)
	{
		if( CurrentGroup.m_kPlayer.ObjectID == ObjectID )
		{
			CurrentGroup.RefreshMembers();
			CurrentGroup.UpdatePodIdles();
		}
	}
}

function AppendAdditionalSyncActions( out VisualizationTrack BuildTrack )
{
}

private function EventListenerReturn OnObjectVisibilityChanged(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local X2GameRulesetVisibilityInterface SourceObject;
	local XComGameState_Unit SeenUnit;
	local XComGameState_Unit SourceUnit;
	local GameRulesCache_VisibilityInfo VisibilityInfo;
	local X2GameRulesetVisibilityManager VisibilityMgr;
	local XComGameState NewGameState;
	local XComGameState_Player UpdatedPlayerState;
	
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;

	SourceObject = X2GameRulesetVisibilityInterface(EventSource); 
	if(SourceObject.GetAssociatedPlayerID() == ObjectID)
	{
		SeenUnit = XComGameState_Unit(EventData); // we only care about enemy units
		if(SeenUnit != none && SourceObject.TargetIsEnemy(SeenUnit.ObjectID))
		{
			SourceUnit = XComGameState_Unit(SourceObject);
			if(SourceUnit != none && GameState != none)
			{
				VisibilityMgr.GetVisibilityInfo(SourceUnit.ObjectID, SeenUnit.ObjectID, VisibilityInfo, GameState.HistoryIndex);
				if(VisibilityInfo.bVisibleGameplay)
				{
					if(TurnsSinceEnemySeen > 0 && SeenUnit.IsAlive())
					{
						NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("PlayerRecordEnemiesSeen");
						UpdatedPlayerState = XComGameState_Player(NewGameState.CreateStateObject(Class, ObjectID));
						UpdatedPlayerState.TurnsSinceEnemySeen = 0;
						NewGameState.AddStateObject(UpdatedPlayerState);
						`GAMERULES.SubmitGameState(NewGameState);
					}

					//Inform the units that they see each other
					class'XComGameState_Unit'.static.UnitASeesUnitB(SourceUnit, SeenUnit, GameState);
				}
				else if (VisibilityInfo.bVisibleBasic)
				{
					//If the target is not yet gameplay-visible, it might be because they are concealed.
					//Check if the source should break their concealment due to the new conditions.
					//(Typically happens in XComGameState_Unit when a unit moves, but there are edge cases,
					//like blowing up the last structure between two units, when it needs to happen here.)
					if (SeenUnit.IsConcealed() && SeenUnit.UnitBreaksConcealment(SourceUnit) && VisibilityInfo.TargetCover == CT_None)
					{
						if (VisibilityInfo.DefaultTargetDist <= Square(SeenUnit.GetConcealmentDetectionDistance(SourceUnit)))
						{
							SeenUnit.BreakConcealment(SourceUnit, VisibilityInfo.TargetCover == CT_None);
						}
					}
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

private function EventListenerReturn OnPlayerTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState NewGameState;
	local XComGameState_Player UpdatedPlayerState;
	local XComGameState_Player TurnEndingPlayer;
	local array<StateObjectReference> VisibleUnits;

	TurnEndingPlayer = XComGameState_Player(EventSource);
	if(TurnEndingPlayer.ObjectID == ObjectID)
	{	
		// while we update this value when object visibility changes, it's possible to go the turn without losing
		// visibility. So one extra check to make sure that we only update the not seen flag if we currently can't see
		// any enemies
		class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemiesForPlayer(TurnEndingPlayer.ObjectID, VisibleUnits);
		if(VisibleUnits.Length == 0)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("IncrementTurnsSinceEnemySeen");
			UpdatedPlayerState = XComGameState_Player(NewGameState.CreateStateObject(Class, ObjectID));
			UpdatedPlayerState.TurnsSinceEnemySeen = ++TurnsSinceEnemySeen;
			NewGameState.AddStateObject(UpdatedPlayerState);
			`GAMERULES.SubmitGameState(NewGameState);
		}
		else if(TurnEndingPlayer.TurnsSinceEnemySeen > 0)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("EnemiesSeenAtEndOfTurn");
			UpdatedPlayerState = XComGameState_Player(NewGameState.CreateStateObject(Class, ObjectID));
			UpdatedPlayerState.TurnsSinceEnemySeen = 0;
			NewGameState.AddStateObject(UpdatedPlayerState);
			`GAMERULES.SubmitGameState(NewGameState);
		}
	}

	return ELR_NoInterrupt;
}

/// <summary>
/// Iterates through the game history to find the first owned unit that is 
/// still in play and living, then bails after refreshing the bHasUnitInPlay flag.
/// </summary>
function bool HasUnitsInPlay()
{
    local XComGameStateHistory History;
    local XComGameState_Unit Unit;
    local bool TempHasUnitInPlay;

    History = `XCOMHISTORY;
    TempHasUnitInPlay = false;

    foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
    {
        if (Unit.ControllingPlayer.ObjectID == self.ObjectID // This player owns the unit
            && !Unit.bRemovedFromPlay && Unit.IsAlive())
        {
            TempHasUnitInPlay = true;
            break;
        }
    }
	
	return TempHasUnitInPlay;
}

function bool HasCooldownAbilities()
{
	local ability_player_cooldown kCooldown;
	foreach m_arrCooldownList(kCooldown)
	{
		if (kCooldown.iCooldown > 0)
			return true;
	}
	return false;
}

function UpdateCooldownAbilities()
{
	local int iCooldown;
	for (iCooldown=0; iCooldown<m_arrCooldownList.Length; iCooldown++)
	{
		if (m_arrCooldownList[iCooldown].iCooldown > 0)
			m_arrCooldownList[iCooldown].iCooldown--;
	}
}

function int GetCooldown( name strAbilityName )
{
	local int iIdx;
	// For debug only
	if (`CHEATMGR != None && `CHEATMGR.strAIForcedAbility ~= string(strAbilityName))
		return 0;

	iIdx = m_arrCooldownList.Find('strAbility', strAbilityName);
	if (iIdx >= 0)
	{
		return m_arrCooldownList[iIdx].iCooldown;
	}
	return 0;
}

function SetCooldown( name strAbilityName, int iCooldown )
{
	local int iIdx;
	local ability_player_cooldown kCooldown;
	iIdx = m_arrCooldownList.Find('strAbility', strAbilityName);
	if (iIdx >= 0)
	{
		m_arrCooldownList[iIdx].iCooldown = iCooldown;
	}
	else
	{
		kCooldown.strAbility = strAbilityName;
		kCooldown.iCooldown = iCooldown;
		m_arrCooldownList.AddItem(kCooldown);
	}

	// We may need to notify the visualizer about this cooldown instantly.  For AI that moves multiple units simultaneously,
	// all units need to know this option is no longer available once anyone uses it.
	XGPlayer(GetVisualizer()).OnPlayerAbilityCooldown(strAbilityName, iCooldown);
}


static function XComGameState_Player CreatePlayer(XComGameState NewGameState, ETeam NewTeam)
{
	local XComGameState_Player NewPlayerState;
	NewPlayerState = XComGameState_Player(NewGameState.CreateStateObject(class'XComGameState_Player'));
	NewPlayerState.TeamFlag = NewTeam;

	switch (NewTeam)
	{
	case eTeam_XCom:
		NewPlayerState.PlayerClassName = Name( "XGPlayer" );
		break;
	case eTeam_Alien:
		NewPlayerState.PlayerClassName = Name( "XGAIPlayer" );
		break;
	case eTeam_Neutral:
		NewPlayerState.PlayerClassName = Name( "XGAIPlayer_Civilian" );
		break;
	default:
		// unhandled team specifier
		`ASSERT(FALSE);
		break;
	}

	return NewPlayerState;
}

simulated function ETeam GetTeam()
{
	return TeamFlag;
}

simulated event ETeam GetEnemyTeam()
{
	local ETeam MyTeam;

	MyTeam = GetTeam();
	switch(MyTeam)
	{
	case eTeam_XCom:
		return eTeam_Alien;
	case eTeam_Alien:
		return eTeam_XCom;
	case eTeam_One:
		return eTeam_Two;
	case eTeam_Two:
		return eTeam_One;
	}
	return eTeam_None;
}

simulated function bool IsEnemyPlayer(XComGameState_Player IsEnemy)
{
	return IsEnemy.GetTeam() == GetEnemyTeam();
}

native function bool IsAIPlayer();

function bool IsLocalPlayer()
{
	local XGPlayer Player;
	Player = XGPlayer(GetVisualizer());
	return !IsAIPlayer() && !Player.IsRemote();
}

function SetGameStatePlayerName(string strPlayerName)
{
	PlayerName = strPlayerName;
}

function string GetGameStatePlayerName()
{
	return PlayerName;
}

function SetGameStatePlayerNetId(UniqueNetId NetId)
{
	PlayerUniqueNetIdA = NetId.Uid.A;
	PlayerUniqueNetIdB = NetId.Uid.B;
}

function UniqueNetId GetGameStatePlayerNetId()
{
	local UniqueNetId PlayerUniqueNetId;
	PlayerUniqueNetId.Uid.A = PlayerUniqueNetIdA;
	PlayerUniqueNetId.Uid.B = PlayerUniqueNetIdB;
	return PlayerUniqueNetId;
}

function bool Synchronize()
{
	return bPlayerReady;
}

function int GetSquadPointValue() { return SquadPointValue; }
function SetSquadPointValue(int PointValue)
{
	SquadPointValue = PointValue;
}
function int CalcSquadPointValue()
{
	local XComGameState_Unit kLoadoutUnit;
	local int iTotalSquadCost;

	iTotalSquadCost = 0;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', kLoadoutUnit)
	{
		if (kLoadoutUnit.ControllingPlayer.ObjectID == ObjectId)
		{
			iTotalSquadCost += kLoadoutUnit.GetUnitPointValue();
		}
    }
	return iTotalSquadCost;
}
function int CalcSquadPointValueFromGameState(XComGameState GameState)
{
	local XComGameState_Unit UnitState;
	local int iTotalSquadCost;

	SquadName = XComGameStateContext_SquadSelect(GameState.GetContext()).strLoadoutName;
	iTotalSquadCost = 0;
	if (GameState != none)
	{
		foreach GameState.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			iTotalSquadCost += UnitState.GetUnitPointValue();
		}
	}

	SquadPointValue = iTotalSquadCost;
	return iTotalSquadCost;
}

function SetSquadConcealment(bool bNewSquadConceal, optional name TriggerEventName)
{
	local XComGameState NewGameState;

	if( bNewSquadConceal != bSquadIsConcealed )
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Set Squad Concealment" @ bNewSquadConceal);
		SetSquadConcealmentNewGameState(bNewSquadConceal, NewGameState);
		if (TriggerEventName != '')
		{
			`XEVENTMGR.TriggerEvent(TriggerEventName, self, self, NewGameState);
		}
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

private function BuildVisualizationForConcealment_Entered_Squad(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{	class'XComGameState_Unit'.static.BuildVisualizationForConcealmentChanged(VisualizeGameState, OutVisualizationTracks, true);	}

private function BuildVisualizationForConcealment_Broken_Squad(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{	class'XComGameState_Unit'.static.BuildVisualizationForConcealmentChanged(VisualizeGameState, OutVisualizationTracks, false);	}

function SetSquadConcealmentNewGameState(bool bNewSquadConceal, XComGameState NewGameState)
{
	local XComGameState_Player NewPlayerState;
	local XComGameState_Unit UnitState, NewUnitState;
	local XComGameStateHistory History;
	local X2EventManager EventManager;
	local Object ThisObj;

	if( bNewSquadConceal != bSquadIsConcealed )
	{
		if (bNewSquadConceal)
			NewGameState.GetContext().PostBuildVisualizationFn.AddItem(BuildVisualizationForConcealment_Entered_Squad);
		else
			NewGameState.GetContext().PostBuildVisualizationFn.AddItem(BuildVisualizationForConcealment_Broken_Squad);

		History = `XCOMHISTORY;

		NewPlayerState = XComGameState_Player(NewGameState.CreateStateObject(class'XComGameState_Player', ObjectID));
		NewGameState.AddStateObject(NewPlayerState);
		NewPlayerState.bSquadIsConcealed = bNewSquadConceal;

		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if( UnitState.ControllingPlayer.ObjectID == ObjectID && UnitState.IsIndividuallyConcealed() != bNewSquadConceal )
			{
				NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
				NewGameState.AddStateObject(NewUnitState);
				NewUnitState.SetIndividualConcealment(bNewSquadConceal, NewGameState);
			}
		}

		EventManager = `XEVENTMGR;
		ThisObj = self;

		if( !bNewSquadConceal )
		{
			EventManager.TriggerEvent('SquadConcealmentBroken', ThisObj, ThisObj, NewGameState);
		}
	}
}

function SetMatchData(const out MatchData Data, name OnlineMatchType)
{
	local int MatchTypeIndex;
	MatchTypeIndex = GetOnlineMatchTypeIndex(OnlineMatchType);
	PlayerOnlineMatchData[MatchTypeIndex].Rank				= Data.Rank;
	PlayerOnlineMatchData[MatchTypeIndex].MatchesPlayed		= Data.MatchesPlayed;
	PlayerOnlineMatchData[MatchTypeIndex].MatchesWon		= Data.MatchesWon;
	PlayerOnlineMatchData[MatchTypeIndex].MatchesLost		= Data.MatchesLost;
	PlayerOnlineMatchData[MatchTypeIndex].MatchesTied		= Data.MatchesTied;
	PlayerOnlineMatchData[MatchTypeIndex].Disconnects		= Data.Disconnects;
	PlayerOnlineMatchData[MatchTypeIndex].SkillRating		= Data.SkillRating;
	PlayerOnlineMatchData[MatchTypeIndex].LastMatchStarted  = Data.LastMatchStarted;
}
function GetMatchData(out MatchData Data, name OnlineMatchType)
{
	local int MatchTypeIndex;
	MatchTypeIndex = GetOnlineMatchTypeIndex(OnlineMatchType);
	Data = PlayerOnlineMatchData[MatchTypeIndex];
}

function int GetOnlineMatchTypeIndex(name OnlineMatchType)
{
	local int i;
	for( i = 0; i < PlayerOnlineMatchData.Length; ++i )
	{
		if( PlayerOnlineMatchData[i].MatchType == OnlineMatchType )
		{
			return i;
		}
	}
	return -1;
}

function FinishMatch(name OnlineMatchType, XComGameState_Player Opponent, MatchResultType MatchResult)
{
	local bool bMatchResultHandled;
	local int MatchTypeIndex;

	`log(`location @ `ShowVar(OnlineMatchType) @ `ShowVar(Opponent) @ `ShowEnum(MatchResultType, MatchResult),,'XCom_Online');
	bMatchResultHandled = true;
	MatchTypeIndex = GetOnlineMatchTypeIndex(OnlineMatchType);
	if( MatchTypeIndex > -1 )
	{
		switch( MatchResult )
		{
		case EOMRT_Loss:
			PlayerOnlineMatchData[MatchTypeIndex].MatchesLost++;
			break;
		case EOMRT_Tie:
			PlayerOnlineMatchData[MatchTypeIndex].MatchesTied++;
			break;
		case EOMRT_Win:
			if( !`ONLINEEVENTMGR.bAcceptedInviteDuringGameplay )
			{
				`ONLINEEVENTMGR.UnlockAchievement(AT_WinMultiplayerMatch); // Win an online match!  
			}// Intentionally fall through
		case EOMRT_AbandonedWin:
			PlayerOnlineMatchData[MatchTypeIndex].MatchesWon++;
			break;
		case EOMRT_AbandonedLoss:
			PlayerOnlineMatchData[MatchTypeIndex].Disconnects++;
			break;
		default:
			bMatchResultHandled = false;
			break;
		}
		if( bMatchResultHandled )
		{
			PlayerOnlineMatchData[MatchTypeIndex].LastMatchStarted = false; // Make sure to clear the match started flag, otherwise risk getting disconnects added.
			PlayerOnlineMatchData[MatchTypeIndex].MatchesPlayed++;
			PlayerOnlineMatchData[MatchTypeIndex].SkillRating = class'XComOnlineStatsUtils'.static.CalculateSkillRatingForPlayer(PlayerOnlineMatchData[MatchTypeIndex], Opponent.PlayerOnlineMatchData[MatchTypeIndex], MatchResult);
		}
	}
}

DefaultProperties
{
	MicAvailable=false
	bPlayerReady=false
	bAuthority=true
	PlayerTurnCount=0
	PlayerOnlineMatchData(0)=(MatchType="Ranked",Rank=0,MatchesPlayed=0,MatchesWon=0,MatchesLost=0,MatchesTied=0,Disconnects=0,SkillRating=0,LastMatchStarted=false)
}
