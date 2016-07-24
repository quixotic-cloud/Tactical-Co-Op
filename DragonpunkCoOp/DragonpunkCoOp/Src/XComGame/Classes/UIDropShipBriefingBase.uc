//-----------------------------------------------------------
//
//-----------------------------------------------------------
class UIDropShipBriefingBase extends UIScreen;

var array<int> TipCounters;

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	
	TipCounters.Length = 2;
}

function XComGameState_DropShipTipStore FindOrCreateTipStore(XComGameState NewGameState)
{
	local XComGameState_DropShipTipStore TipStore;

	TipStore = XComGameState_DropShipTipStore(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_DropShipTipStore', true));
	if (TipStore != none)
	{
		return TipStore;
	}

	if (NewGameState != none)
	{
		TipStore = XComGameState_DropShipTipStore(NewGameState.CreateStateObject(class'XComGameState_DropShipTipStore'));
		NewGameState.AddStateObject(TipStore);
	}
	return TipStore;
}

simulated function bool HasSeenTip(ETipTypes eTip, int nTipIndex)
{
	local XComGameState_DropShipTipStore TipStore;
	TipStore = FindOrCreateTipStore(none);
	return (TipStore != none && TipStore.AllTipsSeen[eTip].Tips.Find(nTipIndex) != -1);
}

simulated function ClearSeenTips(ETipTypes eTip)
{
	local XComGameState_DropShipTipStore TipStore;
	local XComGameState NewGameState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;	
	NewGameState = History.GetStartState();
	`assert(NewGameState != none);
	TipStore = FindOrCreateTipStore(NewGameState);

	TipStore.AllTipsSeen[eTip].Tips.Length = 0;
}

simulated function ResetTipCounter(ETipTypes eTip)
{
	TipCounters[eTip] = 0;
}

simulated function AddSeenTip(ETipTypes eTip, int nTipIndex)
{
	local XComGameState_DropShipTipStore TipStore;
	local XComGameState NewGameState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;	
	NewGameState = History.GetStartState();
	`assert(NewGameState != none);
	TipStore = FindOrCreateTipStore(NewGameState);

	`assert(TipStore.AllTipsSeen[eTip].Tips.Find(nTipIndex) == -1);
	TipStore.AllTipsSeen[eTip].Tips.AddItem(nTipIndex);
}

function int GetTipCount( ETipTypes eTip )
{
	local int Cnt;
	switch( eTip )
	{
	case eTip_Strategy:
			Cnt = class'XGLocalizedData'.default.GameplayTips_Strategy.Length;
		break;
	case eTip_Tactical:
			Cnt = class'XGLocalizedData'.default.GameplayTips_Tactical.Length;
		break;
	}

	return Cnt;
}

function string GetTip( ETipTypes eTip )
{
	local string strTip;
	local int nTipIndex;

	nTipIndex = GetNextTip(eTip);
	
	if (nTipIndex != -1)
	{
		switch( eTip )
		{
		case eTip_Strategy:
			strTip = class'XGLocalizedData'.default.m_strTipLabel@class'XGLocalizedData'.default.GameplayTips_Strategy[nTipIndex];
			break;
		case eTip_Tactical:
			strTip = class'XGLocalizedData'.default.m_strTipLabel@class'XGLocalizedData'.default.GameplayTips_Tactical[nTipIndex];
			break;
		}
	}
	
	return strTip;
}

simulated function int GetNextTipInternal( ETipTypes eTip )
{
	local int iTipIndex;

	if (TipCounters[eTip] < GetTipCount(eTip))
	{
		iTipIndex = TipCounters[eTip];
		TipCounters[eTip] += 1;
	}
	else
	{
		iTipIndex = -1;
	}

	return iTipIndex;
}

simulated function int GetNextUnseenTip( ETipTypes eTip )
{
	local int iTipIndex;
	
	do 
	{
		iTipIndex = GetNextTipInternal(eTip);
	} until (iTipIndex == -1 || !HasSeenTip(eTip, iTipIndex));

	return iTipIndex;
}

simulated function int GetNextTip( ETipTypes eTip )
{
	local int iTipIndex;

	iTipIndex = GetNextUnseenTip(eTip);
	if (iTipIndex == -1)
	{
		ClearSeenTips(eTip);
		ResetTipCounter(eTip);

		iTipIndex = GetNextUnseenTip(eTip);
	}

	AddSeenTip(eTip, iTipIndex);

	return iTipIndex;
}

DefaultProperties
{
	bShowDuringCinematic = true;

}