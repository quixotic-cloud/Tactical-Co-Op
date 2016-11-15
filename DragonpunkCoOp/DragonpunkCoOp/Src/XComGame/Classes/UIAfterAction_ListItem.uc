//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISquadSelect_MissionInfo
//  AUTHOR:  Sam Batista -- 5/1/14
//  PURPOSE: Displays information pertaining to a single soldier in the Headquarters Squad
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIAfterAction_ListItem extends UIPanel
	dependson(XComPhotographer_Strategy);

var StateObjectReference UnitReference;

var localized string m_strActive;
var localized string m_strWounded;
var localized string m_strMIA;
var localized string m_strKIA;
var localized string m_strMissionsLabel;
var localized string m_strKillsLabel;

var UIImage PsiMarkup;
var UIButton PromoteButton;
var bool bShowPortrait;
var bool m_bCanPromote;

simulated function UIAfterAction_ListItem InitListItem()
{
	InitPanel();

	PsiMarkup = Spawn(class'UIImage', self).InitImage(, class'UIUtilities_Image'.const.PsiMarkupIcon);
	PsiMarkup.SetScale(0.7).SetPosition(230, 130).Hide(); // starts off hidden until needed
	
	return self;
}

simulated function UpdateData(optional StateObjectReference UnitRef)
{
	local int days, injuryHours;
	local bool bCanPromote;
	local string statusLabel, statusText, daysLabel, daysText, ClassStr;
	local XComGameState_Unit Unit;

	UnitReference = UnitRef;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	
	if(Unit.bCaptured)
	{
		statusText = m_strMIA;
		statusLabel = "kia"; // corresponds to timeline label on 'AfterActionBG' mc in SquadList.fla
		bShowPortrait = true;
	}
	else if(Unit.IsAlive())
	{
		// TODO: Add support for soldiers MIA (missing in action)

		if(Unit.IsInjured())
		{
			statusText = Caps(Unit.GetWoundStatus(injuryHours, true));
			statusLabel = "wounded"; // corresponds to timeline label on 'AfterActionBG' mc in SquadList.fla
			
			if( injuryHours > 0 )
			{
				days = injuryHours / 24;
				if( injuryHours % 24 > 0 )
					days += 1;

				daysLabel = class'UIUtilities_Text'.static.GetDaysString(days);
				daysText = string(days);
			}
		}
		else
		{
			statusText = m_strActive;
			statusLabel = "active"; // corresponds to timeline label on 'AfterActionBG' mc in SquadList.fla
		}

		if(Unit.HasPsiGift())
			PsiMarkup.Show();
		else
			PsiMarkup.Hide();
	}
	else
	{
		statusText = m_strKIA;
		statusLabel = "kia"; // corresponds to timeline label on 'AfterActionBG' mc in SquadList.fla
		bShowPortrait = true;
	}

	WorldInfo.RemoteEventListeners.AddItem(self); //Listen for the remote event that tells us when we can capture a portrait

	bCanPromote = Unit.ShowPromoteIcon(); 
	//If there's no promote icon, the list item shouldn't be navigable
	bIsNavigable = bCanPromote;
	m_bCanPromote = bCanPromote; //stores a non-local version of the boolean

	// Don't show class label for rookies since their rank is shown which would result in a duplicate string
	if(Unit.GetRank() > 0)
		ClassStr = class'UIUtilities_Text'.static.GetColoredText(Caps(Unit.GetSoldierClassTemplate().DisplayName), eUIState_Faded, 17);
	else
		ClassStr = "";

	AS_SetData( class'UIUtilities_Text'.static.GetColoredText(Caps(class'X2ExperienceConfig'.static.GetRankName(Unit.GetRank(), Unit.GetSoldierClassTemplateName())), eUIState_Faded, 18),
				class'UIUtilities_Text'.static.GetColoredText(Caps(Unit.GetName(eNameType_Last)), eUIState_Normal, 22),
				class'UIUtilities_Text'.static.GetColoredText(Caps(Unit.GetName(eNameType_Nick)), eUIState_Header, 28),
				Unit.GetSoldierClassTemplate().IconImage, class'UIUtilities_Image'.static.GetRankIcon(Unit.GetRank(), Unit.GetSoldierClassTemplateName()),
				(bCanPromote) ? class'UISquadSelect_ListItem'.default.m_strPromote : "",
				statusLabel, statusText, daysLabel, daysText, m_strMissionsLabel, string(Unit.GetNumMissions()),
				m_strKillsLabel, string(Unit.GetNumKills()), false, ClassStr);

	AS_SetUnitHealth(class'UIUtilities_Strategy'.static.GetUnitCurrentHealth(Unit, true), class'UIUtilities_Strategy'.static.GetUnitMaxHealth(Unit));

	if( bCanPromote )
	{
		EnableNavigation(); 
		if( PromoteButton == none ) //This data will be refreshed several times, so beware not to spawn dupes. 
		{
			PromoteButton = Spawn(class'UIButton', self);
			PromoteButton.InitButton('promoteButtonMC', "", OnClickedPromote, eUIButtonStyle_NONE);
		}
		PromoteButton.Show();
	}
	else
	{
		if( PromoteButton != none )
			PromoteButton.Remove(); 

		DisableNavigation();
		Navigator.SelectFirstAvailable();
	}
	Navigator.Clear();
}
simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return false;
	}

	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			OnClickedPromote(None);
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnClickedPromote(UIButton Button)
{
	AfterActionPromote();
}

simulated function AfterActionPromote()
{
	UIAfterAction(Screen).OnPromote(UnitReference);
}

event OnRemoteEvent(name RemoteEventName)
{
	local XComPhotographer_Strategy Photo;
	local X2ImageCaptureManager CapMan;
	local Texture2D SoldierPicture;
	
	super.OnRemoteEvent(RemoteEventName);

	// Only take head shot picture once
	if(RemoteEventName == 'PostM_ShowSoldierHUD')
	{
		CapMan = X2ImageCaptureManager(`XENGINE.GetImageCaptureManager());
		Photo = `GAME.StrategyPhotographer;

		SoldierPicture = CapMan.GetStoredImage(UnitReference, name("UnitPictureSmall"$UnitReference.ObjectID));
		if (SoldierPicture == none)
		{
			// if we have a photo queued then setup a callback so we can sqap in the image when it is taken
			if (!Photo.HasPendingHeadshot(UnitReference, UpdateAfterActionImage,true))
			{
				//Take a picture if one isn't available - this could happen in the initial mission prior to any soldier getting their picture taken
				Photo.AddHeadshotRequest(UnitReference, 'UIPawnLocation_ArmoryPhoto', 'SoldierPicture_Passport_Armory', 128, 128, UpdateAfterActionImage,,,true);
			}

			`GAME.GetGeoscape().m_kBase.m_kCrewMgr.TakeCrewPhotobgraph(UnitReference,,true);
		}
		else
		{
			if(bShowPortrait)
			{
				MC.FunctionString("setDeadSoldierImage", class'UIUtilities_Image'.static.ValidateImagePath(PathName(SoldierPicture)));
			}
		}
	}
}

simulated function UpdateAfterActionImage(const out HeadshotRequestInfo ReqInfo, TextureRenderTarget2D RenderTarget)
{
	local X2ImageCaptureManager CapMan;
	local Texture2D SoldierPicture;
	local string TextureName;
	
	// only care about call backs for the unit we care about
	if (ReqInfo.UnitRef.ObjectID != UnitReference.ObjectID)
		return;

	// only want the callback for the smaller image
	if (ReqInfo.Height != 128)
		return;
	
	TextureName = "UnitPictureSmall"$ReqInfo.UnitRef.ObjectID;
	CapMan = X2ImageCaptureManager(`XENGINE.GetImageCaptureManager());
	SoldierPicture = RenderTarget.ConstructTexture2DScript(CapMan, TextureName, false, false, false);
	CapMan.StoreImage(ReqInfo.UnitRef, SoldierPicture, name(TextureName));
	if(bShowPortrait)
	{
		MC.FunctionString("setDeadSoldierImage", class'UIUtilities_Image'.static.ValidateImagePath(PathName(SoldierPicture)));
	}
}

// same as UISquadSelect_ListItem
simulated function AnimateIn(optional float AnimationIndex = -1.0)
{
	MC.FunctionNum("animateIn", AnimationIndex);
}

//------------------------------------------------------

simulated function AS_SetData( string firstName, string lastName, string nickName,
							   string classIcon, string rankIcon, string promote, 
							   string statusLabel, string statusText, string daysLabel, string daysText,
							   string missionsLabel, string missionsText, string killsLabel, string killsText, bool isPsiPromote, string className)
{
	mc.BeginFunctionOp("setData");
	mc.QueueString(firstName);
	mc.QueueString(lastName);
	mc.QueueString(nickName);
	mc.QueueString(classIcon);
	mc.QueueString(rankIcon);
	mc.QueueString(promote);
	mc.QueueString(statusLabel);
	mc.QueueString(statusText);
	mc.QueueString(daysLabel);
	mc.QueueString(daysText);
	mc.QueueString(missionsLabel);
	mc.QueueString(missionsText);
	mc.QueueString(killsLabel);
	mc.QueueString(killsText);
	mc.QueueBoolean(isPsiPromote);
	mc.QueueString(className);
	mc.EndOp();
}

simulated function AS_SetUnitHealth(int CurrentHP, int MaxHP)
{
	mc.BeginFunctionOp("setUnitHealth");
	mc.QueueNumber(CurrentHP);
	mc.QueueNumber(MaxHP);
	mc.EndOp();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();

	if(PromoteButton != None && m_bCanPromote)
	{
		PromoteButton.OnReceiveFocus();
	}
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();

	if(PromoteButton != None)
	{
		PromoteButton.OnLoseFocus();
	}
}
defaultproperties
{
	LibID = "AfterActionListItem";
	bCascadeFocus = false;
	width = 282;
}

//------------------------------------------------------