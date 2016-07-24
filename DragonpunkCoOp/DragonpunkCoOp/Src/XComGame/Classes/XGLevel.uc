//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XGLevel extends XGLevelNativeBase
	dependson(XGBuildingVisParam)
	native(Level);

var XComBuildingVisManager m_kBuildingVisManager;

var protected XComBuildingVolume    m_kDropship;
var protected array<XComAlienPod>   m_arrPods;
var XComVis m_kVis;

var array<XComBuildingVolume>   m_kBuildingVolumeHistory;

var private float                   m_fLevelTime;

// These arrays are for the XTraceAndHideXComHideableFlaggedLevelActors function,
var array<Actor> m_aHideableFlaggedLevelActors_CurrentlyHiddenByRaycast;

// This is the number of elements in m_aHideableFlaggedLevelActors_CurrentlyHiddenByRaycast that are not NULL.
var int m_iNumLevelActorsCurrentlyHiddenByRaycast;

// This keeps track of when to do a raycast into the scene to determine which hideable level actors to hide.
var float m_fNextHidePropsAndBuildingsCheck;

var bool m_bStreamingLevelsComplete;
var bool m_bLoadingSaveGame;
var bool m_bIsCameraPitching;

var XComLevelVolume   LevelVolume;
var XComWorldData VisibilityMap;

// We use this for restoring the camera for debugging purposes.
var	TCameraCache        SavedCameraCache;

var transient int SleepFrames;

var array<TriggerVolume>    m_arrWaterVolumes;

function AddToBuildingVolumeHistory(XComBuildingVolume kBVolume)    
{
	if (m_kBuildingVolumeHistory.Find(kBVolume) == -1)
			m_kBuildingVolumeHistory.AddItem(kBVolume);
}

function HideBuildingVolumeHistory(optional bool bBuildingWithinABuildingOnly = false)
{
	local XComBuildingVolume kBVolume;
	local int iFloorToHide;
	local array<XComBuildingVolume> arrForDelete;

	foreach m_kBuildingVolumeHistory(kBVolume)
	{
		if (bBuildingWithinABuildingOnly &&
			!kBVolume.m_bIsInternalBuilding)
			continue;

		iFloorToHide = kBVolume.GetLowestOccupiedFloor();

		if (iFloorToHide == kBVolume.Floors.Length)
		{
			kBVolume.HideFloors_ScriptDebug(false);
		}
		else
		{
			// Avoid single frame artfiacts when exiting a building...
			// If the building is blocking the cursor and the cursor is outside, then the building vis
			// drops to the first floor.  This condition ensures we do not reveal the building if it will
			// get immediately hidden again the next frame.
			// epace
			if (!kBVolume.bOccludingCursor)
				kBVolume.ShowFloor_ScriptDebug( iFloorToHide+1);
		}

		arrForDelete.AddItem(kBVolume);
	}

	foreach arrForDelete(kBVolume)
	{
		m_kBuildingVolumeHistory.RemoveItem(kBVolume);
	}

}

event PreBeginPlay()
{
	super.PreBeginPlay();
	
	m_kBuildingVisManager = Spawn(class'XComBuildingVisManager', self);

	SubscribeToOnCleanupWorld();
}

function SetupXComFOW(bool bEnable)
{
	local PlayerController kPC;
	local LocalPlayer LP;
	local PostProcessChain PPChain;
	local XComFOWEffect FOWEffect;
	local XComWorldData WorldData;

	local int ChainIdx;
	local int EffectIdx;

	kPC = GetALocalPlayerController();
	LP = LocalPlayer(kPC.Player);
	WorldData = class'XComWorldData'.static.GetWorldData();

	if( kPC != none && LP != none && WorldData != none )
	{
		for (ChainIdx = 0; ChainIdx < LP.PlayerPostProcessChains.Length; ++ChainIdx)
		{
			PPChain = LP.PlayerPostProcessChains[ChainIdx];

			if( PPChain != none )
			{
				for ( EffectIdx = 0; EffectIdx < PPChain.Effects.Length; EffectIdx++)
				{
					if (PPChain.Effects[EffectIdx] != none && XComFOWEffect(PPChain.Effects[EffectIdx]) != none )
					{
						FOWEffect = XComFOWEffect(PPChain.Effects[EffectIdx]);

						//Even if we don't turn it on, set all its variables so that it will be ready if we DO turn it on
						FOWEffect.bShowFOW = bEnable && WorldData.NumX != 0 && WorldData.bEnableFOW && WorldData.bDebugEnableFOW;			
						FOWEffect.LevelVolumePosition = WorldData.WorldBounds.Min;
						FOWEffect.LevelVolumeDimensions.X = 1.0/(WorldData.NumX * class'XComWorldData'.const.WORLD_StepSize);
						FOWEffect.LevelVolumeDimensions.Y = 1.0/(WorldData.NumY * class'XComWorldData'.const.WORLD_StepSize); 
						FOWEffect.LevelVolumeDimensions.Z = 1.0/(WorldData.NumZ * class'XComWorldData'.const.WORLD_FloorHeight);
						FOWEffect.VoxelSizeUVW.X = 1.0/(WorldData.NumX); 
						FOWEffect.VoxelSizeUVW.Y = 1.0/(WorldData.NumY); 
						FOWEffect.VoxelSizeUVW.Z = 1.0/(WorldData.NumZ);	

						break;
					}
				}
			}
		}	
	}
}

function SetupXComVis()
{
	if( m_kVis == none )
	{
		m_kVis = Spawn(class'XComVis', self);
		m_kVis.InitResources();
	}

}

function Init()
{
	local XComTacticalGRI TacticalGRI;

	TacticalGRI = `TACTICALGRI;
	if (TacticalGRI == none)
		return;

	// Reserve space for XComLevelActors that needs to be hidden.
	m_aHideableFlaggedLevelActors_CurrentlyHiddenByRaycast.Insert(0, 32);

	// Find the level volume, and the visibility map if there is one
	foreach WorldInfo.AllActors(class 'XComLevelVolume', LevelVolume )
	{
		VisibilityMap = LevelVolume.WorldData;
		break;
	}
}

function LoadInit()
{
	InitFloorVolumes();
	InitWaterVolumes();

	// TODO: need to call this again if we replicate objects that have obstacles that can effect pathing. -tsmith 
	//InitCover();
	//`COVERSYSTEM.BuildCover();
	//InitPathing();

	// Reserve space for XComLevelActors that needs to be hidden.
	m_aHideableFlaggedLevelActors_CurrentlyHiddenByRaycast.Insert(0, 32);

	// Find the level volume, and the visibility map if there is one
	foreach WorldInfo.AllActors(class 'XComLevelVolume', LevelVolume )
	{
		VisibilityMap = LevelVolume.WorldData;
		break;
	}

	if(m_kVis == none)
	{
		m_kVis = Spawn(class'XComVis', self);
	}

	m_kVis.InitResources();
}

function InitFloorVolumes()
{
	local XComBuildingVolume kVolume;

	foreach WorldInfo.AllActors(class 'XComBuildingVolume', kVolume )
	{
		if( kVolume != none )   // Hack to eliminate tree break
		{
			kVolume.CacheBuildingVolumeInChildrenFloorVolumes();
			kVolume.CacheFloorCenterAndExtent();

			if( kVolume.IsDropShip )
				m_kDropship = kVolume;
			else
				m_arrBuildings.AddItem( kVolume ); 
		}
	}
}

function InitWaterVolumes()
{
	local TriggerVolume kVolume;

	foreach WorldInfo.AllActors(class'TriggerVolume', kVolume)
	{
		if (kVolume != none && kVolume.bWaterVolume && m_arrWaterVolumes.Find(kVolume) == -1)
			m_arrWaterVolumes.AddItem(kVolume);
	}
}

simulated function AdjustForAbductorBrokenFloor(out Floor kFloor, int iFloorIndex)
{
	local string strMapName;

	if(iFloorIndex == 1 && kFloor.fExtent > 151 && kFloor.fExtent < 153) // float == 152, small range in case there is rounding error
	{
		strMapName = class'Engine'.static.GetCurrentWorldInfo().GetMapName();
		if(InStr(strMapName, "Abductor", false, true) >= 0)
		{
			// there is one floor in the abductor with a very strange shape, patch it
			// up so that it behaves well with the PC interface.
			kFloor.fCenterZ += 248;
			kFloor.fExtent = 96;
		}
	}
}

event bool ShouldUseMouseStyleReveals()
{
	local XComTacticalController kController;

	kController = XComTacticalController(GetALocalPlayerController());

	return kController != none 
		&& kController.IsMouseActive() 
		&& kController.m_XGPlayer == `BATTLE.m_kActivePlayer
		&& `CAMERASTACK.AllowBuildingCutdown();
}

simulated function XGUnit GetActiveUnit()
{
	local XGPlayer kPlayerController;
	kPlayerController = `BATTLE.m_kActivePlayer;
	if (kPlayerController != none)
		return kPlayerController.GetActiveUnit();
	return none;
}

simulated function bool IsCinematic()
{
	local XComTacticalController kTacticalController;

	kTacticalController = XComTacticalController(GetALocalPlayerController());

	return kTacticalController.m_bInCinematicMode;
}

simulated function LoadStreamingLevels(bool bLoadingSaveGame)
{
	m_bStreamingLevelsComplete = false;
	m_bLoadingSaveGame = bLoadingSaveGame;
	GotoState('Streaming');
}

simulated function OnStreamingFinished()
{
	InitFractureSystems();

	WorldInfo.MyKismetVariableMgr.RebuildVariableMap(); //Streaming levels can include kismet, so rebuild the map here
	WorldInfo.MyKismetVariableMgr.RebuildClassMap();

	// If we are in single player and starting a new level, break the collectibles as specified by
	// the battle desc artifacts list	
	//@TODO - rmcfall/jbouscher - collectibles are toast, make something new

	m_bStreamingLevelsComplete = true; // XGBattle checks this before proceeding -- jboswell
}

state Streaming
{
	function InitDynamicElements()
	{
		if (WorldInfo.NetMode != NM_DedicatedServer)
		{
			XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl();
		}
	}

	function bool IsLevelStreamingReplicated()
	{
		local bool bAllDataReplicated;
		local XComTacticalGRI kTacticalGRI;

		bAllDataReplicated = false;
		if (WorldInfo.NetMode != NM_Client)
		{
			bAllDataReplicated = true;
		}
		else
		{
			kTacticalGRI = XComTacticalGRI(WorldInfo.GRI);
			if (WorldInfo.GRI != none && kTacticalGRI.GetBattle() != none)
			{
				bAllDataReplicated = true;
			}
		}

		`log(self $ "::" $ GetStateName() $ "::" $ GetFuncName() $ ": " $ `ShowVar(bAllDataReplicated), true, 'XCom_Net');

		return bAllDataReplicated;
	}

Begin:
	// jboswell: only do this in SP, MP doesn't get Dropship Intros or kismet
	// queue up dynamically streamed maps
	// If the map was loaded by seamless travel, the maps will have already been loaded and this
	// will do nothing. Otherwise, it's just a question of whether or not we include the dropship
	// intros map, which we only do if you are not loading from a save
	if (WorldInfo.NetMode == NM_Standalone)
	{
		`MAPS.AddStreamingMaps(`MAPS.GetCurrentMapMetaData().DisplayName, !m_bLoadingSaveGame);		
		if( m_bLoadingSaveGame )
		{
			//If we are loading a save, then the streaming levels must be loaded before we can proceed
			GetALocalPlayerController().ClientFlushLevelStreaming();
			while( WorldInfo.bRequestedBlockOnAsyncLoading )
			{
				Sleep( 0.1f );
			}
		}
	}

	// Glam Cam Maps are always added post-load, as they are not needed right away
	if(`MAPS != none)
	{
		SleepFrames = 0;
		while(!`MAPS.IsInitialized())
		{
			Sleep(0.1);
			SleepFrames++;
		}
		`log("LOADING: XGLevel waited" @ SleepFrames @ "frames for MapManager init",,'DevStreaming');
		`MAPS.AddGlamCamMaps(WorldInfo.NetMode != NM_Standalone || m_bLoadingSaveGame);
	}

	// Make sure streaming data is replicated before we proceed
	`log("LOADING: Waiting for level streaming to replicate",,'DevStreaming');
	SleepFrames = 0;
	while (!IsLevelStreamingReplicated())
	{
		Sleep(0.1);
		SleepFrames++;
	}
	`log("LOADING: XGLevel waited" @ SleepFrames @ "frames for Level Streaming Replication",,'DevStreaming');

	`log("LOADING: Initializing dynamic world elements",,'DevStreaming');
	InitDynamicElements();

	// Wait for the streaming+package loading to finish
	`log("LOADING: Waiting for streaming to finish",,'DevStreaming');
	SleepFrames = 0;
	do
	{
		Sleep(0.0);
		SleepFrames++;
	} until(IsStreamingComplete());
	`log("LOADING: XGLevel waited" @ SleepFrames @ "frames for Level Streaming",,'DevStreaming');

    // No loading operations should be initiated past this point, if possible.
    // Beyond this, the texture streamer kicks in and seeking will be a nightmare.
	`log("LOADING: Streaming complete",,'DevStreaming');
	OnStreamingFinished();

	`log("########### Finished loading streaming levels",,'DevStreaming');

	if( m_bLoadingSaveGame )
	{
		//If we are loading from a save, send an event to the loaded streaming levels 
		//so they can respond appropriately ( hide dropship, etc. )
		GetALocalPlayerController().RemoteEvent('CIN_DS_OnLoadedSaveGame');
	}

	GotoState('');
}

// Height/Width of level in meters
function int GetWidth()
{
	return 410;
}
function int GetHeight()
{
	return 410;
}

// Is this world point inside of the level boundaries?
simulated function bool IsInBounds( Vector vLoc )
{
	if( vLoc.X < GetLeft() )
		return false;

	if( vLoc.X > GetRight() )
		return false;

	if( vLoc.Y < GetBottom() )
		return false;

	if( vLoc.Y > GetTop() )
		return false;

	if( vLoc.Z > `METERSTOUNITS( 20 ) )
		return false;

	if( vLoc.Z < -`METERSTOUNITS( 5 ) )
		return false;

	return true;
}

simulated function float GetTop()
{
	return `METERSTOUNITS( GetWidth() )/2;
}
simulated function float GetBottom()
{
	return -`METERSTOUNITS( GetWidth() )/2;
}
simulated function float GetLeft()
{
	return -`METERSTOUNITS( GetHeight() )/2;
}
simulated function float GetRight()
{
	return `METERSTOUNITS( GetHeight() )/2;
}

function XComBuildingVolume GetDropship()
{
	return m_kDropship;
}

simulated function XComBuildingVolume GetBuildingByUnit( XGUnit kUnit )
{
	if( !kUnit.IsInside() )
		return none;

	return kUnit.GetPawn().IndoorInfo.CurrentBuildingVolume;
}

function array<XComBuildingVolume> GetBuildings()
{
	return m_arrBuildings;
}

function bool IsInsideBuilding( vector vLoc, optional out XComBuildingVolume kVolume )
{
	local XComBuildingVolume kBuilding;
	foreach m_arrBuildings(kBuilding)
	{
		if (kBuilding.EncompassesPoint(vLoc))
		{
			kVolume = kBuilding;
			return true;
		}
	}
	return false;
}
//------------------------------------------------------------------------------------------------
function bool IsTileInsideBuilding( const out TTile kTile )
{
	local Vector vLoc;
	vLoc = `XWORLD.GetPositionFromTileCoordinates(kTile);
	return IsInsideBuilding(vLoc);
}
simulated function HideAllFloors(bool bUseFade)
{
	local XComBuildingVolume kBuilding;

	if( m_kDropship != none )
		m_kDropship.HideFloors_ScriptDebug(bUseFade);

	foreach m_arrBuildings( kBuilding )
	{
		kBuilding.HideFloors_ScriptDebug(bUseFade);
	}
}

// This updates all necessary actors (level,destructable,frac)
// flagged with HideableWhenBlockingObjectOfInterest to go hidden if they block visibility
// from the camera to the cursor.
//
// Additionally, hides buildings to the first floor if they block visibility from the camera to cursor.

simulated native function DisablePropHiding();

function OnEnteredTile(XComUnitPawn kPawn, const vector TileLocation)
{
	local TriggerVolume kVolume;

	if(kPawn != None)
	{
		// Clear water volume, will be set if we find one we are currently inside
		kPawn.m_kLastWaterVolume = none;

		foreach m_arrWaterVolumes(kVolume)
		{
			if(kVolume != none && kVolume.EncompassesPoint(TileLocation))
			{
				kPawn.m_kLastWaterVolume = kVolume;
				break;
			}
		}

		if(kPawn.m_kLastWaterVolume != none)
		{
			kPawn.SetInWater(true, kPawn.m_kLastWaterVolume.fWaterZ, kPawn.m_kLastWaterVolume.InWaterParticles);
		}
		else
		{
			kPawn.SetInWater(false);
		}
	}
}

event Tick( float fDeltaT )
{	
	m_fLevelTime += fDeltaT;
}

// A little more complex than plain hiding.  Use this for building walls/etc
// This function:
// 1) Uses the special shader alpha to fade out over the Actor over time, if available
// 2) Deals correctly with collision + visibility (so you can't shoot through buildings even if hidden)
// NOTE: To use the special shader stuff, you need the target alpha parameter in the material.
// See XComFloorComponent.FadeIn/Out() for more info


function AddPod( XComAlienPod kPod )
{
	m_arrPods.AddItem(kPod);
}
function RemovePod( XComAlienPod kPod )
{
	m_arrPods.RemoveItem(kPod);
}
//------------------------------------------------------------------------------------------------

simulated event OnCleanupWorld()
{
	super.OnCleanupWorld();
	CleanupLocalization();
}

native function CleanupLocalization();

//------------------------------------------------------------------------------------------------
defaultproperties
{
}
