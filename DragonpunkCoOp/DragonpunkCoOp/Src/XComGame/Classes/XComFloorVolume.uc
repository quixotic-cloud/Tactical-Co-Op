class XComFloorVolume extends Volume
	hidecategories(Object)
	placeable
	native(Level);

enum EFloorVolumeType
{
	eFloor_Default,
	eFloor_Stair,
	eFloor_Invalid_MoveCursorUp,
	eFloor_Invalid_MoveCursorDown
};

var() bool             m_bUseForBuildingReveal <DisplayName="UseForBuildingReveal"|ToolTip="True means that units/cursor present in this floor will trigger building reveal.">;
var() bool             m_bIsEmptyFloor <ToolTip="True means this volume has no actual floor and is instead open to the floor below it.">;
var() float            m_FloorCursorUpperZFactor <ToolTip="This is a factor of the volume extent starting from the middle of the volume. Controls maximum Z height of the cursor in a volume.">;
var() EFloorVolumeType m_FloorVolumeType <ToolTip="Default means it applies to both building shader and cursor. Stair means just shader. Invalid means move cursor to a valid volume above or below, if possible">;

var() bool          m_bCanHideBuildingIfBlockingVisibility <DisplayName="Hide Building if Blocking Visibility"|ToolTip="If TRUE, then if a ray from the camera to the cursor intersects this floor volume, then the building can drop visibility to the first floor">;
var() bool          m_bDisableCutout <DisplayName="Disable Cutout"|ToolTip="If the POI is inside this volume, disable the cutoutbox. Useful for slanted roofs">;

var() array<Actor> m_aInclusionActors <DisplayName="Inclusion Actors"|ToolTip="Additional Actors that should always be considered part of this floor volume">;
var() array<Actor> m_aExclusionActors <DisplayName="Exclusion Actors"|ToolTip="Actors that should never be considered part of this floor volume">;

// Variables for proxy
var() bool	            m_bNonEnterableBuildingPiece <DisplayName="Non Enterable Building">;
var() XComLevelActor	m_kProxyGeometry <DisplayName="Non Enterable Proxy Geometry"|ToolTip="If none then cached geometry will go scanlined instead.">;
var bool	            m_bSimplifiedGeometryMode;
var Material	        m_kProxyGeometryMaterial;

var bool bOccludingCursor;
var bool bPrevOccludingCursor;

// NOTE: This property is kept in-sync when things are changed in XComBuildingVolume
var() editconst int FloorNumber <ToolTip="Which Floor Number this is. This is auto-calculated based on the BuildingVolume.">;

// note: ONLY CACHE DURING GAME. Do NOT allow setting in editor to avoid cyclic dependencies
var transient XComBuildingVolume CachedBuildingVolume;

cpptext
{
	virtual void	        PreSave();
	void	                CacheActors( TArray<FFloorActorInfo>& OutCachedActors, TArray<AEmitter*>& OutCachedEmitters, TArray<AAmbientSound*>& OutCachedSounds  );
	void                    CacheStreamedInActors( TArray<FFloorActorInfo>& OutCachedActors, TArray<AEmitter*>& OutCachedEmitters );
}
native function SetSimplifiedGeometryMode(bool bEnableSimplifiedGeometry);

simulated event PostBeginPlay()
{
	if (m_bNonEnterableBuildingPiece && m_kProxyGeometry != none) {
		m_kProxyGeometry.SetHidden(true);
	}
	super.PostBeginPlay();
}

// MHU - As per Jake, Civilians do not trigger building reveals. 
function bool IsValidUnit(ETeam inputTeam)
{
	switch (inputTeam)
	{
		case eTeam_None:
		case eTeam_Neutral:
			return false;
		default:
			return true;
	}
}

// MHU - TODO - Nativize below function post XGUnit & Pawn unification.
function bool ContainsValidUnit()
{
	local Actor kActor;
	local XComUnitPawnNativeBase kPawn;
	local XComBuildingVisPOI kPOI;
	local XGUnit kUnit;
	local bool bResult;

	foreach Touching (kActor)
	{
		if (kActor.IsA('XComUnitPawnNativeBase'))
		{	
			kPawn = XComUnitPawnNativeBase(kActor);
			if (kPawn != none)
			{
				kUnit = XGUnit(kPawn.GetGameUnit());
			}

			if (kUnit != none &&
				IsValidUnit(kUnit.m_eTeam))
			{
				// We should reveal a unit on a floor if:
				// 1. The unit is playing a pod reveal
				// 2. The unit is visible to players
				bResult = kUnit.IsVisible() && kUnit.IsAliveAndWell();

				if (bResult)
				{
					// Check if the pawn is actually inside. Because of the way Touching actors are updated, 
					// the pawn may be present even though an event has been triggered suggesting that it isn't.
					if( kPawn.IsInside() )
					{
						return true;
					}
				}
			}
		}
		else if( kActor.IsA('XComBuildingVisPOI') )
		{
			kPOI = XComBuildingVisPOI(kActor);

			if( kPOI.IndoorInfo.GetCurrentFloorNumber() == self.FloorNumber )
			{
				return true;
			}
		}
	}

	return false;
}

defaultproperties
{
	m_FloorVolumeType=eFloor_Default
	m_FloorCursorUpperZFactor=0.25f
	m_bUseForBuildingReveal=true
	m_bIsEmptyFloor=false
	m_kProxyGeometryMaterial=Material'FX_Visibility.Materials.m_ProxyGeometry'
	m_bCanHideBuildingIfBlockingVisibility=true
	m_bDisableCutout=false;

	BrushColor=(R=255,G=199,B=6,A=255)
	bColored=TRUE
	CachedBuildingVolume=none
}