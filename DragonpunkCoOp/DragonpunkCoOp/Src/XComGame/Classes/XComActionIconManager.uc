class XComActionIconManager extends Actor
	native(Level)
	config(GameCore)
	dependson(XComWorldData);

const ACTION_ICON_POOL_SIZE = 32;

struct native IconPoolEntry
{
	var StaticMeshComponent Component;
	var float FadeInTime;
	var float FadeDir;
	var bool bActive;
};

struct native CoverIcon extends IconPoolEntry
{
	var MaterialInstanceConstant HighCoverMaterial;
	var MaterialInstanceConstant LowCoverMaterial;
	var MaterialInstanceConstant ActiveMaterial;
	var bool bHighlighted;
};

struct native LadderIcon extends IconPoolEntry
{
	var TTile LowerTile;
};

// Config values
var const config LinearColor NormalColor; // Default color of cover icons
var const config LinearColor FlankedColor; // Color of icons on flanked cover locations, usually red
var const config LinearColor DisabledColor; // Color of icons outside of pathable range
var const config int CoverIconTileRange; // Number of tiles away from the path destination to draw tiles

var transient CoverIcon CoverIconPool[ACTION_ICON_POOL_SIZE];
var native transient MultiMap_Mirror ActiveCoverIcons{TMultiMap<FVector,INT>};

var const StaticMesh HighCoverMesh;
var const StaticMesh LowCoverMesh;
var const StaticMesh LadderUpMesh;
var const StaticMesh LadderDownMesh;

var const SoundCue CoverIconHighlightSound;

struct native InteractiveIcon extends IconPoolEntry
{	 
};

// pool of icons that are usable for showing interactive icons, and which ones are currently in use by intercative level actors
var transient InteractiveIcon InteractiveIconPool[ACTION_ICON_POOL_SIZE];
var transient native Map_Mirror ActiveInteractiveIcons { TMap<AXComInteractiveLevelActor*, INT> };

var transient LadderIcon LadderIconPool[ACTION_ICON_POOL_SIZE];
var native transient MultiMap_Mirror ActiveLadderIcons{TMultiMap<FTTile, INT>};

// used to prevent unneeded updates
var TTile LastCursorTile;
var TTile LastPathDestination;
var XGUnitNativeBase LastActiveUnit;

cpptext
{
	virtual void PostBeginPlay();
	virtual void TickSpecial(FLOAT DeltaTime);

private:
	FCoverIcon *FindFreeCoverIcon(INT &PoolIdx, const FVector &CursorLocation);
	FLadderIcon* FindFreeLadderIcon(INT &PoolIdx, const FVector &CursorLocation);
	void UpdateCoverIcons(const FVector &CursorLocation, const UBOOL bForceRefresh, AXGUnitNativeBase *ActiveUnit, FVector &ClosestLocation);
	void UpdateLadderIcons(AXGUnitNativeBase *ActiveUnit, TMultiMap<FTTile,INT> &ActiveIcons, const FVector &CursorLocation);
	void FreeCoverIcon(INT Index);
	void FreeLadderIcon(INT Index);
}

native function ShowIcons(const bool bShow);
native function UpdateInteractIcons();

native function UpdateCursorLocation(optional const bool bForceRefresh=false, optional const bool bNonPathing=false);

native function ClearCoverIcons();
native function ClearLadderIcons();

defaultproperties
{
	HighCoverMesh=StaticMesh'UI_3D.Cover.CoverFull'
	LowCoverMesh=StaticMesh'UI_3D.Cover.CoverHalf'
	LadderUpMesh=StaticMesh'UI_3D.Climbing.Climb_Up'
	LadderDownMesh=StaticMesh'UI_3D.Climbing.Climb_Down'

	CollisionType=COLLIDE_NoCollision
	bCollideActors=false
	bBlockActors=false

	CoverIconHighlightSound=SoundCue'SoundTacticalUI.CoverHighlightCue'
}
