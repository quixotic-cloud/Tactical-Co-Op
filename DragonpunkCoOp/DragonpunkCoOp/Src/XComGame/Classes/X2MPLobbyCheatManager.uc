//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MPLobbyCheatManager.uc
//  AUTHOR:  Todd Smith  --  8/13/2015
//  PURPOSE: Cheat manager for the lobby
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MPLobbyCheatManager extends XComShellCheatManager;

exec function Help(optional string tok)
{	
	super.Help(tok);

	HelpDESC("SetPlayername", "Updates the Local Player's Name.");
	HelpDESC("X2MPRandomizePlayerOrder", "Randomizes the starting player order.");

	OutputMsg("====================================================");
}

//=================================================================
// ToggleLobbyFull
//=================================================================
exec function ToggleLobbyFull(optional bool bSetSessionSettings=true)
{
	local int iNumPlayers;
	local OnlineGameInterface GameInterface;
	local OnlineGameSettings GameSettings;
	GameInterface = class'GameEngine'.static.GetOnlineSubsystem().GameInterface;
	GameSettings = GameInterface.GetGameSettings('Game');
	iNumPlayers = X2MPLobbyGame(WorldInfo.Game).GetNumPlayers();
	OutputMsg("Previous Player Count:" @ `ShowVar(iNumPlayers,NumPlayers));
	if(bSetSessionSettings)
	{
		OutputMsg("Previous Session Player Count:" @ `ShowVar(GameSettings.NumOpenPublicConnections) @ `ShowVar(GameSettings.NumPublicConnections));
	}
	if(iNumPlayers >= 2)
	{
		iNumPlayers = 1;
	}
	else
	{
		iNumPlayers = 2;
	}
	X2MPLobbyGame(WorldInfo.Game).SetNumPlayers(iNumPlayers);
	OutputMsg("New Player Count:" @ `ShowVar(X2MPLobbyGame(WorldInfo.Game).GetNumPlayers(),NumPlayers));
	if(bSetSessionSettings)
	{
		WorldInfo.Game.NumPlayers = iNumPlayers;
		GameSettings.NumOpenPublicConnections = 2 - iNumPlayers;
		GameInterface.UpdateOnlineGame('Game', GameSettings, true);
		GameSettings = GameInterface.GetGameSettings('Game');
		OutputMsg("New Session Player Count:" @ `ShowVar(GameSettings.NumOpenPublicConnections) @ `ShowVar(GameSettings.NumPublicConnections));
	}
}

exec function X2MPRandomizePlayerOrder()
{
	// @TODO tsmith: make this work with the new UI
	// need to call this XComGameState_BattleDataMP m_BattleData.PlayerTurnOrder.RandomizeOrder();
}

defaultproperties
{
/*
	GiveGeneMod_LocationHelp(0)=(iLocation=1, sDescription="Chest")
	GiveGeneMod_LocationHelp(1)=(iLocation=2, sDescription="Brain")
	GiveGeneMod_LocationHelp(2)=(iLocation=3, sDescription="Eyes")
	GiveGeneMod_LocationHelp(3)=(iLocation=4, sDescription="Skin")
	GiveGeneMod_LocationHelp(4)=(iLocation=5, sDescription="Legs")

	GiveGeneMod_PerkTypeHelp(0)=(ePerk=ePerk_GeneMod_SecondHeart,    sDescription="Chest")
	GiveGeneMod_PerkTypeHelp(1)=(ePerk=ePerk_GeneMod_Adrenal,		 sDescription="Chest")
	GiveGeneMod_PerkTypeHelp(2)=(ePerk=ePerk_GeneMod_BrainDamping,	 sDescription="Brain")
	GiveGeneMod_PerkTypeHelp(3)=(ePerk=ePerk_GeneMod_BrainFeedback,	 sDescription="Brain")
	GiveGeneMod_PerkTypeHelp(4)=(ePerk=ePerk_GeneMod_Pupils,		 sDescription="Eyes")
	GiveGeneMod_PerkTypeHelp(5)=(ePerk=ePerk_GeneMod_DepthPerception,sDescription="Eyes")
	GiveGeneMod_PerkTypeHelp(6)=(ePerk=ePerk_GeneMod_BioelectricSkin,sDescription="Skin")
	GiveGeneMod_PerkTypeHelp(7)=(ePerk=ePerk_GeneMod_MimeticSkin,	 sDescription="Skin")
	GiveGeneMod_PerkTypeHelp(8)=(ePerk=ePerk_GeneMod_BoneMarrow,	 sDescription="Legs")
	GiveGeneMod_PerkTypeHelp(9)=(ePerk=ePerk_GeneMod_MuscleFiber,	 sDescription="Legs")
*/
}