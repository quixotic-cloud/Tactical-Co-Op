class UITooltipMgr extends UIScreen
	dependson(UITextTooltip)
	native(UI);

var bool bEnableTooltips;
var UITextTooltip TextTooltip;
var array<UIToolTip> Tooltips; 
var array<UITooltip> ActiveTooltips;
// ========== TACTICAL ===================================
var localized string m_strSightlineContainer_HitTooltip;
var localized string m_strSightlineContainer_CritTooltip;
var localized string m_strTacticalHUD_WeaponPanelBody; 
// ========== STRATEGY ===================================
var localized string m_strSoldierSummary_SoldierInfoBody; 
// =======================================================
var private int Counter;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	Movie.InsertHighestDepthScreen(self);

	// Reuse one text tooltip
	TextTooltip = Spawn(class'UITextTooltip', self);
	AddPreformedTooltip(TextTooltip);
}

// Occurs for a mouse-triggered event (-in, -out, -press, -release) handled by the movie. 
//  path,  Path to panel which handles event
//  cmd,   Command to send to panel
//  arg,   (optional) parameter to pass along.
simulated function OnMouse(string path, int cmd, string arg)
{
	local UITooltip Tooltip; 
	local array<UITooltip> MatchedTooltips; 

	// Entire system could be toggled off. 
	if( !bEnableTooltips ) return; 

	//Tooltips only care about certain mouse events, so filter down the event types
	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE:
			//Continue on through
			break;
		default:
			return;
	}

	// Find the targeted tooltips, if any
	foreach Tooltips(Tooltip)
	{ 
		if(Tooltip.MatchesPath(arg))
			MatchedTooltips.AddItem(Tooltip);
	}

	//No match was found, so bail. 
	if( MatchedTooltips.length == 0 ) 
		return; 
	
	//Start processing here, since we have at least one legit match. 
	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
			foreach MatchedTooltips(Tooltip)
			{ 
				//Trigger the delegate first, which is allowed to update the Tooltip if it needs to.
				if( Tooltip.del_OnMouseIn != none )
					Tooltip.del_OnMouseIn( Tooltip );

				ActivateTooltip(Tooltip);
			}
			break;

		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE:
			foreach MatchedTooltips(Tooltip)
			{ 
				//Trigger the delegate first, which is allowed to update the Tooltip if it needs to.
				if( Tooltip.del_OnMouseOut != none )
					Tooltip.del_OnMouseOut( Tooltip );

				DeactivateTooltip(Tooltip, true);
			}
			break; 
	}
	return;
}

simulated function OnCommand(string cmd, string arg)
{
	if(arg == "undefined")
		HideAllTooltips(true);
	else
		OnMouse(arg, class'UIUtilities_Input'.const.FXS_L_MOUSE_IN, arg);
}

simulated function ActivateTooltip(UITooltip Tooltip)
{
	if(ActiveTooltips.Find(Tooltip) == INDEX_NONE)
		ActiveTooltips.AddItem(Tooltip);
}

simulated function DeactivateTooltip(UITooltip Tooltip, bool bAnimateIfPossible)
{
	Tooltip.HideTooltip(bAnimateIfPossible);
	Tooltip.deltaTime = 0.0; 
	Tooltip.currentPath = ""; 
	ActiveTooltips.RemoveItem(Tooltip);
}

simulated function HideAllTooltips(optional bool bAnimateOutTooltip = false)
{
	local UITooltip Tooltip;

	foreach Tooltips(Tooltip)
	{ 
		DeactivateTooltip(Tooltip, bAnimateOutTooltip);	
	}
}

// Useful for a screen to call when internal data is being refreshed, so that it closes down 
// all associated tooltips within a designated path. 
simulated function HideTooltipsByPartialPath(string TargetPath, optional bool bAnimateOutTooltip = false)
{
	local UITooltip Tooltip;

	foreach Tooltips(Tooltip)
	{ 
		if( Tooltip.MatchesPath(TargetPath, true, true) )
			DeactivateTooltip(Tooltip, bAnimateOutTooltip);
	}
}

// Useful for a screen to call when internal data is being refreshed, so that it pulses the 
simulated function ForceUpdateByPartialPath(string targetPath)
{
	local UITooltip Tooltip;

	foreach Tooltips(Tooltip)
	{
		if( Tooltip.MatchesPath(TargetPath, true, true) )
		{
			//Trigger the delegate first, which is allowed to update the Tooltip if it needs to.
			if( Tooltip.del_OnMouseIn != none )
				Tooltip.del_OnMouseIn( Tooltip );

			Tooltip.UpdateData();
		}
	}
}

//Returns unique ID of the newly generated Tooltip 
simulated function int AddNewTooltipTextBox( string sBody, 
							   float tX, 
							   float tY, 
							   string targetPath, 
							   //All other items are optional: 
							   optional string sTitle,
							   optional bool bRelativeLocation  = class'UITextTooltip'.default.bRelativeLocation, 
							   optional int tanchor             = class'UITextTooltip'.default.Anchor, 
							   optional bool bFollowMouse       = class'UITextTooltip'.default.bFollowMouse,
							  // optional int pointerAnchor     = class'UIUtilities'.const.ANCHOR_NONE, 
							   optional float maxW              = class'UITextTooltip'.default.maxW,
							   optional float maxH				= class'UITextTooltip'.default.maxH,
							   optional int eTTBehavior			= class'UITextTooltip'.default.eTTBehavior, 
							   optional int eTTColor			= class'UITextTooltip'.default.eTTColor,
							   optional float tDisplayTime		= class'UITextTooltip'.default.tDisplayTime,
							   optional float tDelay			= class'UITextTooltip'.default.tDelay,
							   optional float tAnimateIn		= class'UITextTooltip'.default.tAnimateIn,
							   optional float tAnimateOut		= class'UITextTooltip'.default.tAnimateOut )
{
	local TTextTooltipData TooltipData;
	
	TooltipData.ID            = Counter++;
	TooltipData.sBody         = sBody; 
	TooltipData.targetPath    = targetPath; 
	TooltipData.sTitle        = sTitle;
	TooltipData.bRelativeLocation = bRelativeLocation;
	TooltipData.bFollowMouse  = bFollowMouse;
	TooltipData.maxW          = maxW;
	TooltipData.maxH          = maxH;
	TooltipData.eTTBehavior   = EUITT_Behavior(eTTBehavior);
	TooltipData.eTTColor      = EUITT_Color(eTTColor);
	TooltipData.tDisplayTime  = tDisplayTime;
	TooltipData.tDelay        = tDelay;
	TooltipData.tAnimateIn    = tAnimateIn;
	TooltipData.tAnimateOut   = tAnimateOut;
	TooltipData.anchor        = tanchor;
	TooltipData.x             = tX;
	TooltipData.y             = tY;

	TextTooltip.TextTooltipData.AddItem(TooltipData);

	return TooltipData.ID; 
}

simulated function int AddPreformedTooltip(UIToolTip Tooltip)
{
	AddToolTip(Tooltip);

	//Pumping the init for the box tooltips, in case they are missed elsewhere. 
	if( !Tooltip.bIsInited && UITextTooltip(Tooltip) != none )
		Tooltip.Init();

	return Tooltip.ID; 
}

simulated function AddTooltip(UITooltip Tooltip)
{
	if(Tooltip.ID == INDEX_NONE)
	{
		Tooltip.ID = Counter++;
		Tooltips.AddItem(Tooltip);
	}
}

simulated function RemoveTooltipByID(int ID)
{
	local UITooltip Tooltip;
	local bool bFoundMatch;

	bFoundMatch = false;
	foreach Tooltips(Tooltip)
	{ 
		if( Tooltip != none && Tooltip.MatchesID(ID) )
		{
			bFoundMatch = true;
			break; 	
		}
	}

	if( bFoundMatch ) 
	{
		ActiveTooltips.RemoveItem(Tooltip);
		if(Tooltip != TextTooltip)
		{
			Tooltips.RemoveItem(Tooltip);
			Tooltip.Remove();
		}
		else
			TextTooltip.RemoveTooltipByID(ID);
	}
}

simulated function RemoveTooltipByTarget(string TargetPath, optional bool bPartialPath)
{
	local UITooltip Tooltip;
	local bool bFoundMatch;

	if(bPartialPath)
	{
		RemoveTooltipsByPartialPath(TargetPath);
		return;
	}

	bFoundMatch = false;
	foreach Tooltips(Tooltip)
	{ 
		if( Tooltip != none && Tooltip.TargetPath == TargetPath )
		{
			bFoundMatch = true;
			break; 	
		}
	}

	if( bFoundMatch ) 
	{
		ActiveTooltips.RemoveItem(Tooltip);
		if(Tooltip != TextTooltip)
		{
			Tooltips.RemoveItem(Tooltip);
			Tooltip.Remove();
		}
		else
			TextTooltip.RemoveTooltipByPath(TargetPath);
	}
}

// Useful to clear tooltips belonging to a panel reference
simulated function RemoveTooltips(UIPanel Panel)
{
	RemoveTooltipsByPartialPath(string(Panel.MCPath));
}

// Useful for a screen to call to nuke anything that was underneath of it. 
simulated function RemoveTooltipsByPartialPath(string TargetPath)
{
	local int i;
	local UITooltip Tooltip;

	for(i = Tooltips.length - 1; i > -1; --i)
	{ 
		Tooltip = Tooltips[i];
		if( Tooltip != none && Tooltip.MatchesPath(TargetPath, true, true) )
		{
			ActiveTooltips.RemoveItem(Tooltip);
			if(Tooltip != TextTooltip)
			{
				Tooltips.RemoveItem(Tooltip);
				Tooltip.Remove();
			}
			else
				TextTooltip.RemoveTooltipByPartialPath(TargetPath);
		}
	}
}

event Tick (float DeltaTime )
{
	if(bEnableTooltips)
		Update(DeltaTime);
}

simulated native function Update(float DeltaTime); 

simulated function PrintDebugInfo()
{
	local UITooltip Tooltip;

	`log("========== TooltipMgr PrintInfo ===========",,'uixcom');
	`log(" Tooltips.length = " $Tooltips.Length,, 'uixcom');

	//Note: we can add as much as we need to here once we need to debug some actual cases. Initial setup jsut to have the structure in. -bsteiner 9.20.2013 
	foreach Tooltips(Tooltip)
	{ 
		`log(Tooltip.ID @ "vis:" @ Tooltip.bIsVisible,,'uixcom');
	}
}

simulated function Remove()
{	
	local UITooltip Tooltip;

	foreach Tooltips(Tooltip)
	{ 
		Tooltips.RemoveItem(Tooltip);
		ActiveTooltips.RemoveItem(Tooltip);
		Tooltip.Remove();
	}

	super.Remove();
}

simulated function UITooltip GetTooltipByID( int ID )
{	
	local UITooltip Tooltip;

	foreach Tooltips(Tooltip)
	{ 
		if( Tooltip.ID == ID )
			return Tooltip; 
	}
	return none; 
}

simulated function ActivateTooltipByID(int ID)
{	
	local UITooltip Tooltip;
	Tooltip = GetTooltipByID(ID);
	if(Tooltip != none)
		ActivateTooltip(Tooltip);
}

simulated function DeactivateTooltipByID(int ID, optional bool bAnimateOutIfPossible)
{	
	local UITooltip Tooltip;
	Tooltip = GetTooltipByID(ID);
	if(Tooltip != none)
		DeactivateTooltip(Tooltip, bAnimateOutIfPossible);
}

DefaultProperties
{
	MCName = "theTooltipMgr";
	Package = "/ package/gfxTooltipMgr/TooltipMgr";
	InputState = eInputState_None; 
	bHideOnLoseFocus = false;
	bEnableTooltips = true;
	bAlwaysTick = true
}