//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIEndGameStats
//  AUTHOR:  Sam Batista
//  PURPOSE: This file controls the summary of players achievements
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIEndGameStatsPage extends UIPanel;

simulated function UIEndGameStatsPage InitStatsPage(int PageNum, optional bool bIsFirstPage)
{
	InitPanel(name('EndGameStatsPage_' $ PageNum));

	SetTitle( class'UIEndGameStats'.default.GameSummary );
	SetPage( (PageNum + 1) $ "/" $ class'UIEndGameStats'.const.NUM_PAGES, class'UIEndGameStats'.default.Page );
	SetHeaderLabels( class'UIEndGameStats'.default.Stats, class'UIEndGameStats'.default.You, class'UIEndGameStats'.default.World );
	SetDoomStats( bIsFirstPage ? class'UIEndGameStats'.default.Doom : "", bIsFirstPage ? class'UIUtilities_Strategy'.static.GetAlienHQ( ).Doom : -1 );

	if(bIsFirstPage)
		MC.ChildFunctionVoid("cover", "Hide");

	return self;
}

simulated function UpdateStats(array<TEndGameStat> Stats, bool NoWorldColumn)
{
	local int i;
	MC.BeginFunctionOp("setStats");
	for (i = 0; i < Stats.Length; i++)
	{
		MC.QueueString(Stats[i].Label);

		if (NoWorldColumn)
		{
			MC.QueueString(" ");
			MC.QueueString(Stats[i].YouValue);
		}
		else
		{
			MC.QueueString(Stats[i].YouValue);
			MC.QueueString(Stats[i].WorldValue != "" ? Stats[i].WorldValue : "--");
		}
	}
	MC.EndOp();
}

simulated function SetTitle( string TitleLabel )
{
	MC.FunctionString( "setTitle", TitleLabel );
}

simulated function SetPage( string PageNum, string PageLabel )
{
	MC.BeginFunctionOp( "setPage" );
	MC.QueueString( PageNum );
	MC.QueueString( PageLabel );
	MC.EndOp( );
}

simulated function SetHeaderLabels( string StatsLabel, string YouLabel, string WorldLabel )
{
	MC.BeginFunctionOp( "setStatHeader" );
	MC.QueueString( StatsLabel );
	MC.QueueString( YouLabel );
	MC.QueueString( WorldLabel );
	MC.EndOp( );
}

simulated function SetDoomStats( string DoomLabel, float NumDoom )
{
	MC.BeginFunctionOp( "setDoomStats" );
	MC.QueueString( DoomLabel );
	MC.QueueNumber( NumDoom );
	MC.EndOp( );
}


defaultproperties
{
	LibID = "EndGameStatsPanel";
	bAnimateOnInit = false;
}