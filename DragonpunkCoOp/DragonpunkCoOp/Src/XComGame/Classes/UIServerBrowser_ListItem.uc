class UIServerBrowser_ListItem extends UIPanel;

var TServerInfo m_Entry;
var public int    metadataInt;    // int variable for gameplay use

simulated function UIServerBrowser_ListItem InitListItem(optional name InitName, optional name InitLibID)
{
	InitPanel(InitName, InitLibID);
	return self;
}

simulated function UpdateData(TServerInfo entry)
{
	m_Entry = entry;

	SetData(m_Entry.strHost, m_Entry.strPoints, m_Entry.strTurnTime, m_Entry.strMapPlotType, string(m_entry.iPing));
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

simulated function OnReceiveFocus()
{
	if(!bIsFocused)
	{		
		Invoke("bg.onReceiveFocus");
		MC.FunctionVoid("realizeBGFocus");
	}		

	Super.OnReceiveFocus();
}

simulated function OnLoseFocus()
{
	if(bIsFocused)
	{
		Invoke("bg.onLoseFocus");
		MC.FunctionVoid("realizeBGFocus");
	}

	Super.OnLoseFocus();
}

defaultproperties
{
	LibID = "ServerListItem";

	width = 1265;
	height = 43;
}