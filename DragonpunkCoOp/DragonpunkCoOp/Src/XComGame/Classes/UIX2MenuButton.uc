//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MenuButton.uc
//  AUTHOR:  Brit Steiner
//  PURPOSE: X2MenuButton to interface with specialized XComButton
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIX2MenuButton extends UIButton;

var Name DefaultLibID;
var Name PsiLibID;
var bool bAnimateRings; 
var bool bAnimateShine; 
var string CachedTooltipText; 

delegate del_OnMouseIn( UIToolTip refToTooltip ); 

simulated function UIX2MenuButton InitMenuButton(optional bool bIsPsi = false, optional name InitName, optional string InitLabel, optional delegate<OnClickedDelegate> InitOnClicked, optional EUIButtonStyle InitStyle = eUIButtonStyle_BUTTON_WHEN_MOUSE)
{
	if( bIsPsi )
		LibID = PsiLibID;  
	else
		LibID = DefaultLibID; 

	super.InitButton(InitName, InitLabel, InitOnClicked);
	
	return self;
}

// Tooltip code is kinda nasty - TODO @sbatista - cleanup unused params before ship
simulated function SetTooltipWIthCallback(string DisplayText, delegate<del_OnMouseIn> MouseInDel)
{
	local int TooltipID; 

	if( DisplayText == "" )
	{
		RemoveTooltip();
	}
	else
	{
		 TooltipID = Movie.Pres.m_kTooltipMgr.AddNewTooltipTextBox( DisplayText,
														0,
														-10,
														string(MCPath) $".bg",
														"",
														true,
														class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT,
														false,
														500,
														class'UITextTooltip'.default.maxH,
														class'UITextTooltip'.default.eTTBehavior,
														class'UITextTooltip'.default.eTTColor,
														class'UITextTooltip'.default.tDisplayTime,
														class'UITextTooltip'.default.tDelay);
		bHasTooltip = true;
		Movie.Pres.m_kTooltipMgr.TextTooltip.SetMouseDelegates(TooltipID, MouseInDel);
	}

	CachedTooltipText = DisplayText;
}

simulated function NeedsAttention( bool bAttention, optional bool bForceOnStage )
{
	super.NeedsAttention(bAttention, true);
	if( AttentionIcon != none )
	{
		AttentionIcon.SetSize(85, 85);
		AttentionIcon.SetPosition(4, 4);
	}
	RealizeRings();
}

simulated function UIButton SetDisabled(bool disabled, optional string TooltipText = "DEFAULT_TEXT" )
{
	if( TooltipText == "DEFAULT_TEXT" && !disabled )
		super.SetDisabled(disabled, CachedTooltipText);
	else
		super.SetDisabled(disabled, TooltipText);

	RealizeRings();
	return self;
}

simulated function RealizeRings()
{
	if( class'UIUtilities_Strategy'.static.IsInTutorial(true) )
	{
		AnimateRings(!IsDisabled && bNeedsAttention);
	}
}

simulated function AnimateShine( bool bShowAnimation )
{
	if( bAnimateShine != bShowAnimation )
	{
		bAnimateShine = bShowAnimation;
		MC.FunctionBool("animateShine", bAnimateShine);
	}
}

simulated function AnimateRings( bool bShouldAnimate )
{
	if( bAnimateRings != bShouldAnimate)
	{
		bAnimateRings = bShouldAnimate;
		MC.FunctionBool("animateRings", bAnimateRings);
	}
}

defaultproperties
{
	DefaultLibID = "X2MenuButton";
	PsiLibID = "X2MenuButtonPsi";
}

