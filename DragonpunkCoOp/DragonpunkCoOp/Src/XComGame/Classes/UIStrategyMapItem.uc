
class UIStrategyMapItem extends UIPanel;


var string m_sImage;
var Vector2D m_vLoc;
var string m_strLabel;
var string m_strLabel2;
var string m_strSource;
var string m_strSource2;
var string m_strReward;
var string m_strReward2;
var string m_strFlavorText;
var float m_rotation; //in degrees for Flash, may also be negative or larger than 360 and will resolve appropriately
var float m_fAlpha; //zero to 100 for Flash
var bool m_bIsRegionView; 

var int m_iLevel; //Only for Missions
var bool m_bIsExpiring; //Only for Missions
var bool m_bVIP; //Only for Missions

var float m_fWidth; //Only for Regions 
var float m_fHeight; //Only for Regions 

var Vector2D m_vLoc2;//Only for Cones 
var Vector2D m_vLoc3;//Only for Cones 

var float m_fScale; // Only for Targeting lock, 0.0 to 1.0
var float m_fPercent; // Only for Targeting lock, 0.0 to 1.0

var int m_iPopularity; //Popularity level 

var bool b_delayedRemoval;

// True while this mission pin is displaying Hover text display
var bool ShowingHoverText;

var bool bFadeWhenZoomedOut;
var bool bDisableHitTestWhenZoomedOut;

// The Geoscape entity that this UI Item is representing.
var StateObjectReference GeoscapeEntityRef;

// The History index from the last time this visualizer was updated based on the associated GeoscapeEntity game state.
var int HistoryIndexOnLastUpdate;

// Localized header string for this pin type
var localized string MapPin_Header;

// Localized tooltip for this pin type
var localized string MapPin_Tooltip;

// 3D UI
var UIStrategyMapItem3D MapItem3D;
var UIStrategyMapItemAnim3D AnimMapItem3D;

var vector2D Cached2DWorldLocation; //Stored world location so we don't need to continuously convert from 2d to 3d coords
var vector CachedWorldLocation; //Stored world location so we don't need to continuously convert from 2d to 3d coords

// Constructor
simulated function UIStrategyMapItem InitMapItem(out XComGameState_GeoscapeEntity Entity)
{
	local string PinImage;

	// Initialize static data
	InitPanel(Name(Entity.GetUIWidgetName()), Name(Entity.GetUIWidgetFlashLibraryName()));

	PinImage = Entity.GetUIPinImagePath();
	if( PinImage != "" )
	{
		SetImage(PinImage);
	}

	InitFromGeoscapeEntity(Entity);

	return self;
}

simulated function OnInit()
{
	super.OnInit();
	if( b_DelayedRemoval )
		Remove();
}

// ==========================================================================
// ==========================================================================

// General -----------------------------------

simulated function SetLoc( Vector2D vec )
{
	if( m_vLoc != vec )
	{
		m_vLoc = vec;
		mc.BeginFunctionOp("SetLocation");
		mc.QueueNumber(m_vLoc.X);
		mc.QueueNumber(m_vLoc.Y);
		mc.EndOp();
	}
}
	
public function SetLabel( string Label, 
						 optional string Label2 = "", 
						 optional string Source = "", 
						 optional string Source2 = "", 
						 optional string Reward = "", 
						 optional string Reward2 = "", 
						 optional string FlavorText = "")
{
	if( m_strLabel != Label || 
		m_strLabel2 != Label2 ||
		m_strSource != Source || 
		m_strSource2 != Source2 ||
		m_strReward != Reward ||
		m_strReward2 != Reward2 || 
		m_strFlavorText != FlavorText )
	{
		m_strLabel = Label;
		m_strLabel2 = Label2;
		m_strSource = Source;
		m_strSource2 = Source2;
		m_strReward = Reward;
		m_strReward2 = Reward2;
		m_strFlavorText = FlavorText;
		mc.BeginFunctionOp("SetLabel");
		mc.QueueString(m_strLabel);
		mc.QueueString(m_strLabel2);
		mc.QueueString(m_strSource);
		mc.QueueString(m_strSource2);
		mc.QueueString(m_strReward);
		mc.QueueString(m_strReward2);
		mc.QueueString(m_strFlavorText);
		mc.EndOp();
	}
}
simulated function SetRot( float rot )
{
	if( m_rotation != rot )
	{
		m_rotation = rot;
		mc.FunctionNum("SetRotation", m_rotation);
	}
}

simulated function SetImage( string img )
{
	if( m_sImage != img )
	{
		m_sImage = img;
		mc.FunctionString("SetImage", m_sImage);
	}
}

simulated function UpdateRegionView(bool bIsRegionView)
{
	if( m_bIsRegionView != bIsRegionView )
	{
		m_bIsRegionView = bIsRegionView;
		mc.FunctionBool("UpdateRegionView", m_bIsRegionView );
	}
}

// Mission: ---------------------------------------------

public function SetLevel( int _level )
{
	if( m_iLevel != _level )
	{
		m_iLevel = _level; 
		mc.FunctionNum("SetLevel", m_iLevel);
	}
}
	
public function UpdateExpiration( bool bShow )
{
	if( m_bIsExpiring != bShow )
	{
		m_bIsExpiring = bShow; 
		mc.FunctionBool("UpdateExpiration", m_bIsExpiring);
	}
}
	
public function UpdateVIP( bool bShow )
{
	if( m_bVIP != bShow )
	{
		m_bVIP = bShow;
		mc.FunctionBool("UpdateVIP", m_bVIP);
	}
}

// Region ------------------------------------------------

public function UpdateSize( float w, optional float h = -1 )
{
	if(h == -1) h = w;

	if( m_fWidth != w || m_fHeight != h )
	{
		m_fWidth = w;
		m_fHeight = h;
		mc.BeginFunctionOp("UpdateSize");
		mc.QueueNumber(m_fWidth);
		mc.QueueNumber(m_fHeight);
		mc.EndOp();
	}
}

public function UpdatePopularity( int iPop )
{
	if( m_iPopularity != iPop )
	{
		m_iPopularity = iPop;
		mc.FunctionNum("UpdatePopularity", m_iPopularity);
	}
}

// Ring ---------------------------------------------------

public function SetRadius( float val )
{
	UpdateSize(val * 2, val * 2);
}


// Targeting lock -------------------------------------------------

public function UpdateLockedScale( float scale )
{
	if( m_fScale != scale )
	{
		m_fScale = scale;
		mc.FunctionNum("UpdateScale", m_fScale);
	}
}

public function UpdateLockedPercent( float percent)
{
	if( m_fPercent != percent )
	{
		m_fPercent = percent;
		mc.FunctionNum("UpdatePercent", m_fPercent);
	}
}


// Sight cone -------------------------------------------------

simulated function UpdateConePoints( Vector2D vec0, Vector2D vec1, Vector2D vec2 )
{
	if( m_vLoc != vec0 || m_vLoc2 != vec1 || m_vLoc3 != vec2 )
	{
		m_vLoc2 = vec1;
		m_vLoc3 = vec2;

		SetLoc(vec0);

		mc.BeginFunctionOp("DrawCone");
		mc.QueueNumber(vec1.X);
		mc.QueueNumber(vec1.Y);
		mc.QueueNumber(vec2.X);
		mc.QueueNumber(vec2.Y);
		mc.EndOp();
	}
}

// -------------------------------------------------------------

// Will automatically remove itself after the specified period of time. 
simulated function SetExpiration( float fTime )
{
	SetTimer( fTime, false, 'Remove');
}

// --------------------------------------------------------

simulated function Remove()
{
	if( !bIsInited )
	{
		b_delayedRemoval = true; 
		return; 
	}

	Movie.Pres.m_kTooltipMgr.RemoveTooltips(self);
	super.Remove(); 
}

function GenerateTooltip( string tooltipHTML )
{
	local int TooltipID; 
	if( tooltipHTML != "" )
	{
		TooltipID = Movie.Pres.m_kTooltipMgr.AddNewTooltipTextBox(tooltipHTML, 15, 0, string(MCPath), , false, , true, , , , , , 0.0 /*no delay*/);
		Movie.Pres.m_kTooltipMgr.TextTooltip.SetUsePartialPath(TooltipID, true);
		bHasTooltip = true;
	}
}
// ==========================================================================
// ================ Strategy Refactor =======================================
// ==========================================================================

// Set static entity data on initialization.
final function InitFromGeoscapeEntity(const out XComGameState_GeoscapeEntity GeoscapeEntity)
{
	// cache the associated Entity's lookup id
	GeoscapeEntityRef.ObjectID = GeoscapeEntity.ObjectID;

	// set this pin's location
	SetLoc(GeoscapeEntity.Get2DLocation());
	
	// set this actor's location
	SetLocation(`EARTH.ConvertEarthToWorld(GeoscapeEntity.Get2DLocation()));

	// init staic 3D UI (if it exists)
	InitStatic3DUI(GeoscapeEntity);

	// init animated 3D UI (if it exists)
	InitAnimated3DUI(GeoscapeEntity);

	// Set the Tooltip for this pin
	GenerateTooltip(MapPin_Tooltip);

	// Give subclasses an opportunity to perform additional initialization
	OnInitFromGeoscapeEntity(GeoscapeEntity);

	// update the flyover text for this pin, and perform any other dynamic updates
	UpdateFromGeoscapeEntity(GeoscapeEntity);
}

function InitStatic3DUI(const out XComGameState_GeoscapeEntity GeoscapeEntity)
{
	local StaticMesh UIMesh;
	local UIStrategyMapItem3D kItem;
	local vector ZeroVec;

	foreach AllActors(class'UIStrategyMapItem3D', kItem)
	{
		if(kItem.GeoscapeEntityRef == self.GeoscapeEntityRef)
		{
			MapItem3D = kItem;
			break;
		}
	}

	if(MapItem3D == none)
	{
		MapItem3D = Spawn(class'UIStrategyMapItem3D', self).InitMapItem3D();
	}

	MapItem3D.MapItem = self;
	MapItem3D.GeoscapeEntityRef = GeoscapeEntity.GetReference();	
	UIMesh = GeoscapeEntity.GetStaticMesh();

	if(UIMesh != none)
	{
		MapItem3D.SetStaticMesh(UIMesh);
		MapItem3D.SetMeshTranslation(ZeroVec);
		MapItem3D.SetScale3D(GeoscapeEntity.GetMeshScale());
		MapItem3D.SetMeshRotation(GeoscapeEntity.GetMeshRotator());
	}
}

function InitAnimated3DUI(const out XComGameState_GeoscapeEntity GeoscapeEntity)
{
	local SkeletalMesh UISkelMesh;
	local AnimTree UIAnimTree;
	local AnimSet UIAnimSet;
	local UIStrategyMapItemAnim3D kItem;
	local vector ZeroVec;

	foreach AllActors(class'UIStrategyMapItemAnim3D', kItem)
	{
		if (kItem.GeoscapeEntityRef == self.GeoscapeEntityRef)
		{
			AnimMapItem3D = kItem;
			break;
		}
	}

	if (AnimMapItem3D == none)
	{
		AnimMapItem3D = Spawn(GeoscapeEntity.GetMapItemAnim3DClass(), self).InitMapItemAnim3D();
	}

	AnimMapItem3D.MapItem = self;
	AnimMapItem3D.GeoscapeEntityRef = GeoscapeEntity.GetReference();
	UISkelMesh = GeoscapeEntity.GetSkeletalMesh();
	UIAnimSet = GeoscapeEntity.GetAnimSet();
	UIAnimTree = GeoscapeEntity.GetAnimTree();

	if (UISkelMesh != none && UIAnimSet != none && UIAnimTree != none)
	{
		AnimMapItem3D.SetUpAnimMapItem(UISkelMesh, UIAnimTree, UIAnimSet);
		AnimMapItem3D.SetMeshTranslation(ZeroVec);
		AnimMapItem3D.SetScale3D(GeoscapeEntity.GetMeshScale());
		AnimMapItem3D.SetMeshRotation(GeoscapeEntity.GetMeshRotator());
	}
}

function UpdateFlyoverText()
{
	SetLabel(MapPin_Header@"FLYOVER TEXT NOT YET IMPLEMENTED FOR THIS PIN TYPE");
}

// Virtual initializer
function OnInitFromGeoscapeEntity(const out XComGameState_GeoscapeEntity GeoscapeEntity);

function bool ShouldDrawUI(out Vector2D screenPos)
{
	local XComGameStateHistory History;
	local XComGameState_GeoscapeEntity GeoscapeEntity;
	local vector WrapOffset;

	History = `XCOMHISTORY;
	GeoscapeEntity = XComGameState_GeoscapeEntity(History.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));
	if (!GeoscapeEntity.ShouldBeVisible())
	{
		return false;
	}

	if(GetStrategyMap().m_eUIState == eSMS_Flight)
	{
		return false;
	}

	// to take care of world coordinate wrapping, check onscreen status with offsets around the world
	if(class'UIUtilities'.static.IsOnScreen(CachedWorldLocation, screenPos))
	{
		return true;
	}
	else
	{
		WrapOffset.X = `EARTH.GetWidth();
		return (class'UIUtilities'.static.IsOnScreen(CachedWorldLocation + WrapOffset, screenPos)
				|| class'UIUtilities'.static.IsOnScreen(CachedWorldLocation - WrapOffset, screenPos));
	}
}

function bool ShouldDrawMesh()
{
	local XComGameState_GeoscapeEntity GeoscapeEntity;
	GeoscapeEntity = XComGameState_GeoscapeEntity(`XCOMHISTORY.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));
	return GeoscapeEntity.ShouldBeVisible();
}

function bool IsAvengerLandedHere()
{
	//Log spew of none access while avenger if flying between sites. 
	if( class'UIUtilities_Strategy'.static.GetXComHQ().GetCurrentScanningSite() == none ) return false; 

	return (class'UIUtilities_Strategy'.static.GetXComHQ().GetCurrentScanningSite().GetReference().ObjectID == GeoscapeEntityRef.ObjectID);
}

// Hook to perform an update to bring this visual actor up to state with it's associated Geoscape Entity.
function UpdateVisuals()
{
	local XComGameStateHistory History;
	local XComGameState_GeoscapeEntity GeoscapeEntity;
	local Vector2D TmpVector;
	local XComStrategyMap XComMap; 	
	local Rotator NewRotation;

	History = `XCOMHISTORY;
	GeoscapeEntity = XComGameState_GeoscapeEntity(History.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));

	Cached2DWorldLocation = GeoscapeEntity.Get2DLocation();
	CachedWorldLocation = `EARTH.ConvertEarthToWorld(Cached2DWorldLocation);
	CachedWorldLocation.Z = GeoscapeEntity.GetLocation().Z; //used by airship map entities for flying animations, needs to be updated every tick

	if( ShouldDrawUI(TmpVector) )
	{	
		SetNormalizedPosition(TmpVector);
		UpdateFromGeoscapeEntity(GeoscapeEntity);
		UpdateExpiration(GeoscapeEntity.AboutToExpire());
			
		Show();

		XComMap = `HQPRES.m_kXComStrategyMap;
		UpdateRegionView(XComMap != none);

		if( GeoscapeEntity.ShowFadedPin() )
		{
			SetAlpha(50);
		}
		else
		{
			SetAlpha(100);
		}

		
	}
	else
	{
		
		Hide();		
	}

	if (ShouldDrawMesh())
	{
		SetHidden(false);

		MapItem3D.SetMeshHidden(false);
		AnimMapItem3D.SetMeshHidden(false);
		if(CachedWorldLocation != MapItem3D.Location)
		{
			MapItem3D.SetLocation(CachedWorldLocation);
		}
		if (CachedWorldLocation != AnimMapItem3D.Location)
		{
			AnimMapItem3D.SetLocation(CachedWorldLocation);
		}

		NewRotation = GeoscapeEntity.GetMeshRotator() + GeoscapeEntity.GetRotation();
		if(NewRotation != MapItem3D.GetMeshRotation())
		{
			MapItem3D.SetMeshRotation(NewRotation);
		}
		if (NewRotation != AnimMapItem3D.GetMeshRotation())
		{
			AnimMapItem3D.SetMeshRotation(NewRotation);
		}

		// Trigger unique animation updates if any exist
		UpdateAnimMapItem3DVisuals();
	}
	else
	{
		SetHidden(true);

		MapItem3D.SetMeshHidden(true);
		AnimMapItem3D.SetMeshHidden(true);
	}
}

function UpdateAnimMapItem3DVisuals()
{
	// implemented in subclasses
}

// Update dynamic entity data.
function UpdateFromGeoscapeEntity(const out XComGameState_GeoscapeEntity GeoscapeEntity)
{
	local XComGameStateHistory History;
	local XComGameState_GeoscapeEntity OldGeoscapeEntity;

	History = `XCOMHISTORY;
	OldGeoscapeEntity = XComGameState_GeoscapeEntity(History.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID,, HistoryIndexOnLastUpdate));

	if( GeoscapeEntity != OldGeoscapeEntity || HistoryIndexOnLastUpdate == -1 )
	{
		// update the flyover text for this pin
		UpdateFlyoverText();

		HistoryIndexOnLastUpdate = History.GetCurrentHistoryIndex();
	}
}

function FadeOut()
{
	// TODO - eventually make this fade out gradually
	SetAlpha(50);
	Show();

	// set the mission pin UI item to be cleaned up in the near future
	SetExpiration(3);
}

// ==========================================================================

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local XComGameStateHistory History;
	local XComGameState_GeoscapeEntity GeoscapeEntity;

	if(GetStrategyMap().m_eUIState == eSMS_Flight)
	{
		return;
	}

	switch(cmd) 
	{ 
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		OnMouseIn();
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		OnMouseOut();
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		History = `XCOMHISTORY;
		GeoscapeEntity = XComGameState_GeoscapeEntity(History.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));
		GeoscapeEntity.AttemptSelectionCheckInterruption();
		break;
	}
}
simulated function UIStrategyMap GetStrategyMap()
{
	return UIStrategyMap(`SCREENSTACK.GetScreen(class'UIStrategyMap'));
}

// Handle mouse hover special behavior
simulated function OnMouseIn()
{
	local XComGameState_GeoscapeEntity GeoscapeEntity;

	MC.FunctionVoid("MoveToHighestDepth");
	MC.FunctionVoid("showShadow");

	GeoscapeEntity = XComGameState_GeoscapeEntity(`XCOMHISTORY.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));
	if (GeoscapeEntity.ShouldBeVisible())
	{
		`SOUNDMGR.PlaySoundEvent("Play_Mouseover"); //Possibly update with custom sound from auto 
	}
}

// Clear mouse hover special behavior
simulated function OnMouseOut()
{
	MC.FunctionVoid("hideShadow");
}


// ==========================================================================
// ==========================================================================

DefaultProperties
{
	MCName = "_item";
	b_delayedRemoval = false;
	bProcessesMouseEvents = true;

	bDisableHitTestWhenZoomedOut = true;
	bFadeWhenZoomedOut = true;

	m_fAlpha = 100; 
	m_fScale = 0.05;
	m_fPercent = 1.0; 

	HistoryIndexOnLastUpdate=-1
	LibID = "MapItemGeneric";
}
