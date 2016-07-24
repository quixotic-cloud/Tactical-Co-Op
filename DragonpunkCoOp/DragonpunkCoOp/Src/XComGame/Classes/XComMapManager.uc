//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComMapManager
//  AUTHOR:  Justin Boswell, Ryan McFall
//
//  PURPOSE: Provides script level access for the streaming / loading of UE3 map content, as
//			 as well as responding to engine queries for what maps should be loaded in a given
//			 situation.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComMapManager extends Object
	native(Core)
	config(Maps);

struct native ShellMapDefinition
{	
	var string MapName;	//The name of the map to load as the shell screen
	var string MissionType; //Specify if the player must have gone on this mission type
	var array<string> arrPlotTypes;	//Which plot types does this match to?
	var array<string> arrBiomeTypes; //Which biome types does this match to?		
};

var config privatewrite array<ShellMapDefinition> arrShellMapDefs;

struct native DropshipMapImageDefinition
{
	var string MapName; //Name of the objective parcel for this mission
	var string ImagePath; //The path of the image to use
	var string Biome; //Biome supported by this definition
};

var config privatewrite array<DropshipMapImageDefinition> arrMapImageDefs;

struct native StreamMapData
{
	var string MapName;
	var Vector Loc;
	var Rotator Rot;
};

// Map Data for facilities
struct AuxMapInfo
{
	var bool   InitiallyVisible;
	var string MapName;
};

const MaxDynamicAliens = 2;


struct native MapHistory
{
	var int     iFamilyID;
	var int	    iPlayed;

	var float   fChance;            
	var float   fGain;
};

// jboswell: content loading info
struct native XComMapMetaData
{
	var name MapFamily;

	var init string Name;
	var init string DisplayName;
	var EMissionType MissionType;
	var bool bInRotation;
	var EMissionTime TimeOfDay;
	var EShipType ShipType;
	var EMissionRegion eRegion;

	var bool NewMap;
	var float InitialChance;
	var float InitialGain;

	var name DynamicAliens[MaxDynamicAliens];
	var init array<StreamMapData> StreamingMaps;

	var int PlayCount<FGDEIgnore=true>;
	var int FamilyID<FGDEIgnore=true>;
	var float Gain<FGDEIgnore=true>;
	var float Chance<FGDEIgnore=true>;


	structdefaultproperties
	{
		DynamicAliens[0]=None;
		DynamicAliens[1]=None;

		NewMap = false;
		InitialChance = 20;
		InitialGain = 1.05
	}

};

//By default the seamless travel manager allows the destination map to load up while seamless travelling.This is done because some maps, seed maps, guide the generation
//of the final destination map.SeamlessTravelCustomSeedMaps allows custom maps to be added to the list of seed maps so that the seed map doesn't HAVE to be the travel destination.
var config privatewrite array<string> SeamlessTravelCustomSeedMaps;
var config privatewrite bool bUseSeamlessTravelToTactical;
var config privatewrite bool bUseSeamlessTravelToStrategy;
var config protected array<XComMapMetaData> Maps;
var config privatewrite array<string> GlamCamMaps;

var const transient array<Level> PreloadedLevels;

var config int TurnsToParity;
var config int MinChance;
var config float MinimumGain;

var bool bSeamlessTravelBeginLoadAdditionalMaps;

cpptext
{
	void Init();
	static void AsyncLevelLoadCallback(UObject *LoadedPackage, void *UserData);

	//Serialization
	/**
	* Callback used to allow object register its direct object references that are not already covered by
	* the token stream.
	*
	* @param ObjectArray	array to add referenced objects to via AddReferencedObject
	* - this is here to keep the navmesh from being GC'd at runtime
	*/
	virtual void AddReferencedObjects(TArray<UObject*>& ObjectArray);
	virtual void Serialize(FArchive& Ar);

	virtual void CrashDump(FCrashDumpArchive &Ar);	
}

native function String SelectShellMap();
native function PreloadTransitionLevels(optional bool bBlockOnLoad=false);
native function PreloadMap(const out string Mapname);
native function ClearPreloadedLevels();

native function SetTransitionMap(string MapName);
native function string GetTransitionMap();
native function ResetTransitionMap();

native static function bool DoesMapPackageExist(const string MapName);

// There can be more than one map meta data per map name
simulated native static function bool GetMapInfosFromMapName(const out string MapName, out array<XComMapMetaData> aMapData);

// Display name should be unique key into map meta data
simulated native static function bool GetMapInfoFromDisplayName(const out string MapDisplayName, out XComMapMetaData MapData);
simulated native static function bool GetMapDisplayNames(EMissionType MissionType, out array<string> MapDisplayNames, optional bool bAllMaps = false, optional bool bIncludeStrategyMaps = true);
simulated native static function string GetRandomMapDisplayName(EMissionType MissionType, EMissionTime TimeOfDay, EShipType eUFO, EMissionRegion Region, int Country, out array<MapHistory> MapPlayCount, out int PlayCount);
simulated native static function string InternalGetRandomMapDisplayName(out array<string> MapDisplayNames, EMissionTime TimeofDay, EShipType eUFO, EMissionRegion Region, int Country, out array<MapHistory> MapPlayCount, out int PlayCount);
simulated native static function IncrementMapPlayHistory(string MapName, out array<MapHistory> MapPlayCount, out int PlayCount);
simulated native static function DecrementMapPlayHistory(string MapName, out array<MapHistory> MapPlayCount, out int PlayCount);

simulated native static function UpdateMapHistory(array<XComMapMetaData> MapDatas, out array<MapHistory> MapPlayCount);


// jboswell: These are only valid in SP. If you hit these in MP, blame Casey ;)
simulated native static function SetCurrentMapMetaData(XComMapMetaData MapMetaData);
simulated native static function XComMapMetaData GetCurrentMapMetaData();

simulated native static function ResetMapCounts(out array<MapHistory> histories);
simulated native static function DumpMapCounts(array<MapHistory> histories);

simulated native static function bool IsTacticalMap(const out string MapName);

simulated native static function bool IsLevelLoaded(name MapName, optional bool bRequireVisible = false);

simulated static native function string GetMapCommandLine( string strMapDisplayName, bool bFromStrategy, optional bool bSeamless, optional XGBattleDesc BattleDesc);

simulated native static function LogMapSelection(string LogMsg);

simulated static function AddMapDynamicContent(string MapDisplayName)
{
	local XComMapMetaData MapData;

	GetMapInfoFromDisplayName(MapDisplayName, MapData);
}


delegate LevelVisibleDelegate(name LevelPackageName, optional LevelStreaming LevelStreamedIn = new class'LevelStreaming');
simulated native static function LevelStreaming AddStreamingMap(string MapName, optional vector vOffset = vect(0,0,0), optional Rotator rRot = Rot(0,0,0), optional bool bBlockOnLoad = true, optional bool bAllowDuplication = false, optional bool bVisible = true, optional delegate<LevelVisibleDelegate> LevelVisibleDel = none);

// Removes the streaming level that has offset vOffset.
simulated native static function RemoveStreamingMap(vector vOffset);

simulated native static function RemoveStreamingMapByName(string MapName, optional bool RebuildWorldData = true);

simulated native static function RemoveStreamingMapByNameAndLocation(coerce string MapName, vector vOffset, optional bool RebuildWorldData = true);

simulated native static function RemoveAllStreamingMaps();

simulated native static function int NumStreamingMaps();

simulated native static function bool IsStreamingComplete();

simulated function bool GetCinematicMapNameByCharacterType(name charType, out string strCinematicMapName, bool bMultiplayer)
{
	local string strCinematicCharName;

	strCinematicCharName = string(charType);
	if (len(strCinematicCharName) > 0)
	{
		strCinematicMapName = "CIN_" $ strCinematicCharName;

		// we now have enough memory to load the full maps instead of the minimal '_GC' maps which is good because the artists have not been keeping them in sync. -tsmith 7.23.2013
		//if (bMultiplayer)
		//{
		//	// Multiplayer maps don't need Pod reveals, so to save memory we created maps with only glam cams / death cams in them
		//	strCinematicMapName = strCinematicMapName $ "_GC";
		//}

		return true;
	}
	return false;
}

simulated function OnGlamCamMapVisible(name LevelName, optional LevelStreaming LevelStreamedIn = new class'LevelStreaming')
{
	//`BATTLE.m_kGlamMgr.OnGlamCamMapLoaded(LevelName);
}

simulated function AddGlamCamMaps(bool bBlockOnLoad)
{
	local string StreamingMap;
	local name MapName;
	local array<string> RequiredGlamCamMaps;
	local LevelStreaming LvlStreaming;
	
	if(class'Engine'.static.GetCurrentWorldInfo().NetMode != NM_Standalone)
	{
		bBlockOnLoad = false;
	}

	GetRequiredGlamCamMaps(RequiredGlamCamMaps);
	foreach RequiredGlamCamMaps(StreamingMap)
	{
		`log("AddGlamCamMaps - "$StreamingMap @ `ShowVar(bBlockOnLoad),,'DevStreaming');

		LvlStreaming = AddStreamingMap(StreamingMap, , , bBlockOnLoad );
		MapName = name(StreamingMap);
		if (!LvlStreaming.bIsVisible)
		{
			LvlStreaming.LevelVisibleDelegate = OnGlamCamMapVisible;
		}
		else
		{
			OnGlamCamMapVisible(MapName);
		}
	}
}

simulated event GetRequiredGlamCamMaps(out array<string> RequiredGlamCamMaps, optional XGBattleDesc kDesc)
{
	if (`TACTICALGRI == none)
		return;

	RequiredGlamCamMaps.AddItem("CIN_Soldier");
	RequiredGlamCamMaps.AddItem("CIN_MEC");
}

//Toggles the visibility of a streaming level
static native function SetStreamingLevelVisible(LevelStreaming SetLevel, bool bVisible);

// Don't use this function for Multiplayer as it will find the maps with Pod reveals in them.
simulated function FindStreamingMap( name nCharType, out array<string> arrStreaming )
{
	local string strMap;

	if( nCharType == '' )
		return;
	
	if( !GetCinematicMapNameByCharacterType( nCharType, strMap, false ) )
		return;

	if( arrStreaming.Find( strMap ) != INDEX_NONE )
		return;

	arrStreaming.AddItem( strMap );
}

function string SelectMapImage(string MapName)
{
	local int Index;
	local int IndexBestMatch;	
	local XComGameStateHistory History;	
	local XComGameState_BattleData BattleDataState;

	//Get the biome data straight out of the battle data
	History = `XCOMHISTORY;
	BattleDataState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData', true));

	IndexBestMatch = 0;
	for(Index = 0; Index < arrMapImageDefs.Length; ++Index)
	{
		//We have a potential match
		if(arrMapImageDefs[Index].MapName == MapName)
		{
			IndexBestMatch = Index;
			if(arrMapImageDefs[Index].Biome == BattleDataState.MapData.Biome)
			{
				break; //We found a perfect match, exit
			}
		}
	}

	return arrMapImageDefs[IndexBestMatch].ImagePath;
}

function string SelectMPMapImage(string MapName, string Biome)
{
	local int Index;
	local int IndexBestMatch;	

	IndexBestMatch = 0;
	for(Index = 0; Index < arrMapImageDefs.Length; ++Index)
	{
		//We have a potential match
		if(arrMapImageDefs[Index].MapName == MapName)
		{
			IndexBestMatch = Index;
			if(arrMapImageDefs[Index].Biome == Biome)
			{
				break; //We found a perfect match, exit
			}
		}
	}

	return arrMapImageDefs[IndexBestMatch].ImagePath;
}

//Equivalent to the parcel manager map generation process, but for strategy
event NativeGenerateStrategyMap()
{	
	AddStreamingMap(class'XGBase'.default.BaseMapName, , , true, false, true, GenerateStrategyMapPhase1); //This map will load and direct the loading of additional maps
	bSeamlessTravelBeginLoadAdditionalMaps = true;	
}

//This works just like it does for tactical, where we load the maps during the steamless loading map and then when the logic runs to 'load' the maps 
//in the strategy game they are already resident and ready to use
function GenerateStrategyMapPhase1(name LevelPackageName, optional LevelStreaming LevelStreamedIn = new class'LevelStreaming')
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_FacilityXCom Facility;
	local string LoadMapName;
	local Vector vLoc;
	local Vector ZeroVector;
	local DynamicPointInSpace TimerActor;
	local int idx;	
	local AuxMapInfo MapInfo;

	`MAPS.SetStreamingLevelVisible(LevelStreamedIn, false); //Needs to start out hidden or else it will be inside the sky ranger transition map
	
	TimerActor = class'WorldInfo'.static.GetWorldInfo().Spawn(class'DynamicPointInSpace');

	History = `XCOMHISTORY;

	//Load in the basic environment maps
	vLoc = ZeroVector;
		
	//Time of day map - we do not load the time of day map during seamless travel, since it can change once we get into the strategy game ( the time may be changed by game mechanics )

	//Biome map
	LoadMapName = class'XGBase'.static.GetBiomeTerrainMap();
	AddStreamingMap(LoadMapName, vLoc, , true, false);

	//Avenger cap map
	AddStreamingMap(class'XGBase'.default.BaseCapMapName, vLoc, , true, false);
		
	//Per room maps
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for(idx = 0; idx < XComHQ.Rooms.Length; idx++)
	{
		Room = XComHQ.GetRoom(idx);
		vLoc = class'XGBase'.static.GetRoomLocation(TimerActor, idx);

		//Basic room map
		LoadMapName = class'XGBase'.static.GetMapname(Room);
		AddStreamingMap(LoadMapName, vLoc, , true, true, true);
			
		//Room animations ( personnel walking around, matinee scenes, etc. )
		LoadMapName = class'XGBase'.static.GetAnimMapname(Room);
		if(LoadMapName != "")
		{
			AddStreamingMap(LoadMapName, vLoc, , true, true, true);
		}

		//See if there is a facility built in the room, and add additional maps for that
		Facility = Room.GetFacility();
		if(Facility != none)
		{
			//Room constructed matinee scene
			LoadMapName = class'XGBase'.static.GetFlyInMapName(Facility);	
			if(LoadMapName != "")
			{
				AddStreamingMap(LoadMapName, vLoc, , true, true, true);
			}				

			//Any other maps that may be needed for unique / special cases
			foreach Facility.GetMyTemplate().AuxMaps(MapInfo)
			{
				if(MapInfo.MapName != "")
				{
					AddStreamingMap(MapInfo.MapName, vLoc, , true, true, MapInfo.InitiallyVisible);
				}
			}
		}
	}

	//Special cinematic maps
	vLoc = ZeroVector;
	AddStreamingMap("CIN_PostMission1", vLoc, , true, false, , );
	AddStreamingMap("CIN_PreMission", vLoc, , true, false, , );

	class'Engine'.static.GetEngine().SeamlessTravelSignalStageComplete();	
}

simulated native static function AddStreamingMaps(const string MapDisplayName, optional bool bAllowDropshipIntro=true);
simulated native static function AddStreamingMapsFromURL(const string URL, optional bool bAllowDropshipIntro=true);

function bool IsInitialized()
{
	if(class'WorldInfo'.static.GetWorldInfo().NetMode == NM_Client)
	{
		return class'WorldInfo'.static.GetWorldInfo().GRI != none && `BATTLE != none && XGBattle_MP(`BATTLE).m_bCharacterTypesUsedInfoReceived;
	}
	else
	{
		return true;
	}
}

defaultproperties
{
}
