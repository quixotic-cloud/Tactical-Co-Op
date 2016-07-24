class XComGameStateContext_XpEvent extends XComGameStateContext native(Core);

var private XpEventData EventData;

function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

function XComGameState ContextBuildGameState()
{
	// this class is not used to build a game state, the XpManager handles it internally
	`assert(false);
	return none;
}

protected function ContextBuildVisualization(out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray)
{
	local XComGameStateHistory History;
	local XComCheatManager CheatMan;
	local XComGameState_XpManager IterateXpMan, OldXpMan, NewXpMan;
	local XComGameState_Unit UnitState;
	local string DebugString;
	local float SquadShareDiff, UnitShareDiff;
	local int EarnedPoolDiff, UnitXpIdx, i, j;
	local X2Action_PlaySoundAndFlyOver DebugFlyover;
	local VisualizationTrack BuildTrack;

	CheatMan = `CHEATMGR;
	if (CheatMan.bDebugXp)
	{
		History = `XCOMHISTORY;
		foreach AssociatedState.IterateByClassType(class'XComGameState_XpManager', IterateXpMan)
		{
			History.GetCurrentAndPreviousGameStatesForObjectID(IterateXpMan.ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
			OldXpMan = XComGameState_XpManager(BuildTrack.StateObject_OldState);
			NewXpMan = XComGameState_XpManager(BuildTrack.StateObject_NewState);
			if (OldXpMan.EarnedPool != NewXpMan.EarnedPool)
			{
				EarnedPoolDiff = NewXpMan.EarnedPool - OldXpMan.EarnedPool;
				DebugString = (EarnedPoolDiff > 0 ? "+" : "") $ EarnedPoolDiff @ "Earned Pool";
			}
			UnitXpIdx = INDEX_NONE;
			for (i = 0; i < NewXpMan.UnitXpShares.Length; ++i)
			{
				if (i >= OldXpMan.UnitXpShares.Length)
				{
					UnitXpIdx = i;
					UnitShareDiff = NewXpMan.UnitXpShares[i].Shares;
					break;
				}
				if (NewXpMan.UnitXpShares[i].Shares != OldXpMan.UnitXpShares[i].Shares)
				{
					UnitXpIdx = i;
					UnitShareDiff = NewXpMan.UnitXpShares[i].Shares - OldXpMan.UnitXpShares[i].Shares;
					break;
				}
			}
			if (UnitXpIdx != INDEX_NONE)
			{
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(NewXpMan.UnitXpShares[UnitXpIdx].UnitRef.ObjectID));
				DebugString @= (UnitShareDiff > 0 ? "+" : "") $ UnitShareDiff  @ "Shares";
			}
			else
			{
				//  If the unit didn't earn shares, the xp event was still tracked so find the different unit count.
				for (i = 0; i < NewXpMan.TrackedXpEvents.Length; ++i)
				{
					for (j = 0; j < NewXpMan.TrackedXpEvents[i].UnitCounts.Length; ++j)
					{
						if (j >= OldXpMan.TrackedXpEvents[i].UnitCounts.Length)
						{
							UnitXpIdx = NewXpMan.TrackedXpEvents[i].UnitCounts[j].ObjRef.ObjectID;
							break;
						}
						if (NewXpMan.TrackedXpEvents[i].UnitCounts[j].Count != OldXpMan.TrackedXpEvents[i].UnitCounts[j].Count)
						{
							UnitXpIdx = NewXpMan.TrackedXpEvents[i].UnitCounts[j].ObjRef.ObjectID;
							break;
						}
					}
				}
				if (UnitXpIdx != INDEX_NONE)
				{
					UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitXpIdx));
				}
			}
			if (OldXpMan.SquadXpShares != NewXpMan.SquadXpShares)
			{
				SquadShareDiff = NewXpMan.SquadXpShares - OldXpMan.SquadXpShares;
				DebugString @= (SquadShareDiff > 0 ? "+" : "") $ SquadShareDiff @ "Squad Shares";
			}			

			if (UnitState == none)
			{
				`RedScreen("XpEvent generated with no associated unit state!");
			}
			else
			{
				BuildTrack.StateObject_OldState = UnitState;
				BuildTrack.StateObject_NewState = UnitState;
				BuildTrack.TrackActor = History.GetVisualizer(UnitState.ObjectID);
				DebugFlyover = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, self));
				DebugFlyover.SetSoundAndFlyOverParameters(None, DebugString, '', eColor_Good);
				VisualizationTracks.AddItem(BuildTrack);
				`log("XpEvent:" @ DebugString);
			}
		}
	}
}

function string SummaryString()
{
	return "XComGameStateContext_XpEvent";
}