class UILeaderboard_ListItem extends UIPanel;

var TLeaderboardEntry m_Entry;

simulated function UILeaderboard_ListItem InitListItem(optional name InitName, optional name InitLibID)
{
	InitPanel(InitName, InitLibID);
	return self;
}

simulated function UpdateData(TLeaderboardEntry entry)
{
	m_Entry = entry;

	SetData(string(m_Entry.iRank), m_Entry.strPlayerName, string(m_Entry.iWins), string(m_Entry.iLosses), string(m_entry.iDisconnects));
}

function SetData(string rank,
						 string playerName, string Wins,  
						 string Losses, string Disconnects)
{
	mc.BeginFunctionOp("setData");
	mc.QueueString(rank);
	mc.QueueString(playerName);
	mc.QueueString(Wins);
	mc.QueueString(Losses);
	mc.QueueString(Disconnects);
	mc.EndOp();
}

defaultproperties
{
	LibID = "LeaderboardListItem";

	width = 1265;
	height = 43;
}