//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    IUISortableScreen
//  AUTHOR:  Brit Steiner       -- 7/15/11
//  PURPOSE: Interface class for any element which interacts with a UI sorting screen. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

interface IUISortableScreen;

function bool GetFlipSort(); 
function int GetSortType(); 

function SetFlipSort(bool bFlip);
function SetSortType(int eSortType);

// BRW: changed this to RefreshData so the screens can implement UpdateData for specialized data update and UpdateList for specialized list population
//      and RefreshData can then do UpdateData, SortData, then UpdateList. this allows the more concrete types of UIPersonnel etc to override UpdateData completely
//      without having to know they should also sort and update the list
function RefreshData();