//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComMCPEventListener.uc
//  AUTHOR:  Todd Smith  --  2/16/2012
//  PURPOSE: Interface to received notifications about the MCP
//---------------------------------------------------------------------------------------
//  Copyright (c) 2012 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
interface XComMCPEventListener
	dependson(XComMCPTypes);

/**
 * Received when the MCP system is initialized.
 * @param eInitStatus - status code for initialization. success, disabled via commandline, swallowed by a black hole, etc.
 */
simulated event OnMCPInitialized(EMCPInitStatus eInitStatus);

/**
 * Received when the MP INI data has been read.
 * 
 * @param bSuccess, was the read successful.
 * @param strINIContents, the complete contents of the INI file.
 */
simulated event OnGetINIFromServerCompleted(bool bSuccess, string INIFilename, string strINIContents);