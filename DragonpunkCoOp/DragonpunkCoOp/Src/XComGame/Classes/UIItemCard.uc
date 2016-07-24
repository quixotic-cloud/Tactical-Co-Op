//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIItemCard.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: UIPanel that displays and image, and description of an item.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIItemCard extends UIPanel;

var localized string m_strCostLabel;
var localized string m_strSupplyLabel; 
var localized string m_strTimeToBuildLabel;
var localized string m_strNeedEngineers; 
var localized string m_strIntelLabel; 
var localized string m_strScienceSkillLabel;
var localized string m_strEngineeringSkillLabel;
var localized string m_strUpkeepCostLabel;
var localized string m_strInstant;
var localized string m_strPurchased;

var Texture2D StaffPicture;
var bool bWaitingForImageUpdate;

var XComGameStateHistory History;

simulated function UIItemCard InitItemCard(optional name InitName)
{
	InitPanel(InitName);
	History = `XCOMHISTORY;
	return self;
}


simulated function SetItemImages(optional X2ItemTemplate ItemTemplate, optional StateObjectReference ItemRef)
{
	local int i;
	local array<string> Images;
	local XComGameState_Item Item;
	local X2WeaponTemplate WeaponTemplate;

	if( ItemRef.ObjectID > 0 )
	{
		Item = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
		Images = Item.GetWeaponPanelImages();
	}
	else if( ItemTemplate != none )
	{
		if (ItemTemplate.IsA('X2WeaponTemplate'))
		{
			WeaponTemplate = X2WeaponTemplate(ItemTemplate); 

			if (ItemTemplate.strImage != "")
				Images.AddItem(ItemTemplate.strImage);
			else if( X2WeaponTemplate(ItemTemplate).WeaponPanelImage != "" )
				Images.AddItem(X2WeaponTemplate(ItemTemplate).WeaponPanelImage);

			//Base Attachment Images 
			for( i = 0; i < WeaponTemplate.DefaultAttachments.length; i++ )
			{
				if( WeaponTemplate.DefaultAttachments[i].AttachIconName != "" )
					Images.AddItem(WeaponTemplate.DefaultAttachments[i].AttachIconName);
			}
		}
		else
		{
			if (ItemTemplate.strImage != "")
				Images.AddItem(ItemTemplate.strImage);
			else if( X2WeaponTemplate(ItemTemplate).WeaponPanelImage != "" )
				Images.AddItem(X2WeaponTemplate(ItemTemplate).WeaponPanelImage);
		}
	}

	MC.BeginFunctionOp("SetImageStack");
	for( i = 0; i < Images.Length; i++ )
	{
		MC.QueueString(Images[i]);
	}
	MC.EndOp();
}

simulated function PopulateItemCard(optional X2ItemTemplate ItemTemplate, optional StateObjectReference ItemRef)
{
	local string strDesc, strRequirement, strTitle;

	if( ItemTemplate == None )
	{
		Hide();
		return;
	}

	bWaitingForImageUpdate = false;

	strTitle = class'UIUtilities_Text'.static.GetColoredText(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(ItemTemplate.GetItemFriendlyName()), eUIState_Header, 24);
	strDesc = ""; //Description and requirements strings are reversed for item cards, desc appears at the very bottom of the card so not needed here
	strRequirement = class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetItemBriefSummary(ItemRef.ObjectID), eUIState_Normal, 24);
		
	PopulateData(strTitle, strDesc, strRequirement, "");
	SetItemImages(ItemTemplate, ItemRef);
}

simulated function string GetOrStartWaitingForStaffImage(XComGameState_Unit UnitState)
{
	local XComPhotographer_Strategy Photo;
	local X2ImageCaptureManager CapMan;
	local StateObjectReference UnitRef;
	local name UnitImageTag;
	
	CapMan = X2ImageCaptureManager(`XENGINE.GetImageCaptureManager());
	Photo = `GAME.StrategyPhotographer;
	UnitRef = UnitState.GetReference();

	UnitImageTag = name("UnitPicture"$UnitRef.ObjectID);
	StaffPicture = CapMan.GetStoredImage(UnitRef, UnitImageTag);
	if (StaffPicture == none)
	{
		if (!Photo.HasPendingHeadshot(UnitRef, UpdateItemCardImage))
		{
			Photo.AddHeadshotRequest(UnitRef, 'UIPawnLocation_ArmoryPhoto', 'SoldierPicture_Head_Armory', 512, 512, UpdateItemCardImage,, false, true);
		}
		bWaitingForImageUpdate = true;
		return "";
	}

	return "img:///"$PathName(StaffPicture);
}

simulated function UpdateItemCardImage(const out HeadshotRequestInfo ReqInfo, TextureRenderTarget2D RenderTarget)
{
	local X2ImageCaptureManager CapMan;
	local string TextureName;
	
	// only want the callback for the larger image
	if (ReqInfo.Height != 512)
		return;
	
	TextureName = "UnitPicture"$ReqInfo.UnitRef.ObjectID;
	CapMan = X2ImageCaptureManager(`XENGINE.GetImageCaptureManager());
	StaffPicture = RenderTarget.ConstructTexture2DScript(CapMan, TextureName, false, false, false);
	CapMan.StoreImage(ReqInfo.UnitRef, StaffPicture, name(TextureName));

	// if we have changed the selected item we no longer want to update the image in the UI (but we do want to store it in the image capture manager above)
	if (!bWaitingForImageUpdate)
		return;

	MC.FunctionString("SetHeadImage", "img:///"$PathName(StaffPicture));

	bWaitingForImageUpdate = false;
}

simulated function PopulateResearchCard(optional Commodity ItemCommodity, optional StateObjectReference ItemRef)
{
	local bool bIsHeadImage;
	local string strDesc, strRequirement, strTitle, strImage;
	local XComGameState_Unit UnitState;
	local XComGameState_Reward RewardState;

	bWaitingForImageUpdate = false;

	strTitle = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(ItemCommodity.Title);
	strDesc = ""; //Description and requirements strings are reversed for item cards, desc appears at the very bottom of the card so not needed here
	strRequirement = ItemCommodity.Desc;

	if( ItemCommodity.Image != "" )
	{
		strImage = ItemCommodity.Image;
	}
	else
	{
		if (ItemCommodity.RewardRef.ObjectID != 0)
		{
			RewardState = XComGameState_Reward(History.GetGameStateForObjectID(ItemCommodity.RewardRef.ObjectID));
			`assert(RewardState != none);
			
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));
			if (UnitState != none)
			{
				strImage = GetOrStartWaitingForStaffImage(UnitState);
				bIsHeadImage = true;
			}
		}
	}
	
	PopulateData(strTitle, strDesc, strRequirement, strImage);
	if( UIResearchArchives(Screen) == none )
		PopulateResearchCostData(ItemCommodity, ItemRef);

	if (bIsHeadImage && strImage != "")
		mc.FunctionString("SetHeadImage", strImage);

}

simulated function PopulateResearchCostData(optional Commodity ItemCommodity, optional StateObjectReference ItemRef)
{
	local string Cost, Time, Requirements, TimeLabel;
	local EUIState TimeColorState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech TechState;
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	TechState = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));
	Cost = class'UIUtilities_Strategy'.static.GetStrategyCostString(ItemCommodity.Cost, ItemCommodity.CostScalars, ItemCommodity.DiscountPercent);

	TimeLabel = m_strTimeToBuildLabel;
	if (ItemCommodity.OrderHours < 0 )
	{
		Time = "";
		TimeLabel = "";
	}
	else if (ItemCommodity.OrderHours == 0)
	{
		Time = class'UIUtilities_Text'.static.GetColoredText(m_strInstant, eUIState_Good);
	}
	else
	{
		Time = class'UIUtilities_text'.static.GetTimeRemainingString(ItemCommodity.OrderHours);
		TimeColorState = class'UIUtilities_Strategy'.static.GetResearchProgressColor(XComHQ.GetResearchProgress(ItemRef));
		Time = class'UIUtilities_Text'.static.GetColoredText(Time, TimeColorState);
	}
	
	if(ItemCommodity.bTech)
	{
		Requirements = class'UIUtilities_Strategy'.static.GetTechReqString(ItemCommodity.Requirements, ItemCommodity.Cost);
	}
	else
	{
		Requirements = class'UIUtilities_Strategy'.static.GetStrategyReqString(ItemCommodity.Requirements);
	}

	// ---------------------------

	mc.BeginFunctionOp("PopulateCostData");
	if(Cost != "")
	{
		mc.QueueString(m_strCostLabel);
		mc.QueueString(Cost);
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
	}

	if(ItemCommodity.bTech && XComHQ.TechIsResearched(ItemRef) && !TechState.GetMyTemplate().bRepeatable)
	{
		mc.QueueString("");
		mc.QueueString("");
	}
	else
	{
		mc.QueueString(TimeLabel);
		mc.QueueString(Time);
	}
	mc.QueueString(Requirements);
	mc.EndOp();
}

simulated function PopulateSimpleCommodityCard(optional Commodity ItemCommodity, optional StateObjectReference ItemRef)
{
	local string strDesc, strRequirement, strTitle, strImage;

	bWaitingForImageUpdate = false;

	strTitle = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(ItemCommodity.Title);
	strDesc = ""; //Description and requirements strings are reversed for item cards, desc appears at the very bottom of the card so not needed here
	strRequirement = ItemCommodity.Desc;

	if( ItemCommodity.Image != "" )
		strImage = ItemCommodity.Image;
	else
		strImage = "img:///UILibrary_StrategyImages.GeneMods.GeneMods_MimeticSkin"; //Temp cool image 

	PopulateData(strTitle, strDesc, strRequirement, strImage);
	PopulateSimpleCommodityCostData(ItemCommodity, ItemRef);
}

simulated function PopulateXComDatabaseCard(X2EncyclopediaTemplate EncyclopediaEntry)
{
	mc.BeginFunctionOp("PopulateArchiveData");
	mc.QueueString(EncyclopediaEntry.GetDescriptionTitle());
	mc.QueueString(EncyclopediaEntry.GetDescriptionEntry());
	mc.EndOp();

	Show();
}

simulated function PopulateSimpleCommodityCostData(optional Commodity ItemCommodity, optional StateObjectReference ItemRef)
{
	local string Cost, Time, Requirements, TimeLabel;
	local EUIState TimeColorState;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	Cost = class'UIUtilities_Strategy'.static.GetStrategyCostString(ItemCommodity.Cost, ItemCommodity.CostScalars, ItemCommodity.DiscountPercent);

	if( ItemCommodity.OrderHours == 0 )
	{
		Time = "";
		TimeLabel = "";
	}
	else
	{
		Time = class'UIUtilities_text'.static.GetTimeRemainingString(ItemCommodity.OrderHours);
		TimeColorState = class'UIUtilities_Strategy'.static.GetResearchProgressColor(XComHQ.GetResearchProgress(ItemRef));
		Time = class'UIUtilities_Text'.static.GetColoredText(Time, TimeColorState);
		TimeLabel = m_strTimeToBuildLabel;
	}

	if (ItemCommodity.bTech)
	{
		Requirements = class'UIUtilities_Strategy'.static.GetTechReqString(ItemCommodity.Requirements, ItemCommodity.Cost);
	}
	else
	{
		Requirements = class'UIUtilities_Strategy'.static.GetStrategyReqString(ItemCommodity.Requirements);
	}

	// ---------------------------

	mc.BeginFunctionOp("PopulateCostData");
	if( Cost != "" )
	{
		mc.QueueString(m_strCostLabel);
		mc.QueueString(Cost);
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
	}
	mc.QueueString(TimeLabel);
	mc.QueueString(Time);
	mc.QueueString(Requirements);
	mc.EndOp();
}

simulated function PopulateUpgradeCard(X2FacilityUpgradeTemplate UpgradeTemplate, StateObjectReference FacilityRef)
{
	local XComGameState_FacilityXCom Facility;
	local string strDesc, strTitle, strRequirements, strImage, strUpkeep;

	if( UpgradeTemplate == None )
	{
		Hide();
		return;
	}

	bWaitingForImageUpdate = false;

	Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
	
	strTitle = UpgradeTemplate.DisplayName;

	strDesc = UpgradeTemplate.Summary $"\n";

	strImage = UpgradeTemplate.strImage;

	strRequirements = class'UIUtilities_Strategy'.static.GetStrategyCostString(UpgradeTemplate.Cost, `XCOMHQ.FacilityUpgradeCostScalars);
	
	strRequirements $= "<font color='#546f6f'> | </font>"; //HTML Divider

	// Add Power requirement
	if (UpgradeTemplate.iPower >= 0) //Building a power generator upgrade
		strRequirements $= class'UIUtilities_Text'.static.InjectImage("power_icon") $ class'UIUtilities_Text'.static.GetColoredText(string(UpgradeTemplate.iPower), eUIState_Good);
	else if (Facility.GetRoom().HasShieldedPowerCoil()) // Or building upgrade on top of a power coil
		strRequirements $= class'UIUtilities_Text'.static.InjectImage("power_icon") $ class'UIUtilities_Text'.static.GetColoredText("0", eUIState_Good);
	else
		strRequirements $= class'UIUtilities_Text'.static.InjectImage("power_icon") $ class'UIUtilities_Text'.static.GetColoredText(string(int(Abs(UpgradeTemplate.iPower))), eUIState_Warning);
	
	strRequirements $= class'UIUtilities_Strategy'.static.GetStrategyReqString(UpgradeTemplate.Requirements);

	if (UpgradeTemplate.UpkeepCost > 0)
	{
		strUpkeep = m_strUpkeepCostLabel @ class'UIUtilities_Strategy'.default.m_strCreditsPrefix $ UpgradeTemplate.UpkeepCost;
		strUpkeep = class'UIUtilities_Text'.static.GetColoredText(strUpkeep, eUIState_Warning);
		strDesc $= "\n" $ strUpkeep;
	}

	PopulateData(strTitle, strDesc, strRequirements, strImage);
}

simulated function PopulateData(string Title, string Desc, string Requirements, string ImagePath)
{
	mc.BeginFunctionOp("PopulateData");
	mc.QueueString(Title);
	
	if (Requirements == "")
		mc.QueueString(Desc);
	else
		mc.QueueString(Requirements $"\n" $ Desc);
	
	mc.QueueString(ImagePath);
	mc.EndOp();

	Show();
}

simulated function PopulateCostData(optional X2ItemTemplate ItemTemplate)
{
	local float EngBonus;
	local int Hours; 
	local string Cost, Time, Requirements; 

	if( ItemTemplate != none )
	{
		EngBonus = class'UIUtilities_Strategy'.static.GetEngineeringDiscount(ItemTemplate.Requirements.RequiredEngineeringScore);
		Cost = class'UIUtilities_Strategy'.static.GetStrategyCostString(ItemTemplate.Cost, `XCOMHQ.ItemBuildCostScalars, EngBonus);

		Hours = `XCOMHQ.GetItemBuildTime(ItemTemplate, UIFacility_Storage(Movie.Stack.GetFirstInstanceOf(class'UIFacility_Storage')).FacilityRef); 
		if (Hours < 0)
		{
			Time = class'UIUtilities_Text'.static.GetColoredText(m_strNeedEngineers, eUIState_Bad);
		}
		else if (Hours == 0)
		{
			Time = class'UIUtilities_Text'.static.GetColoredText(m_strInstant, eUIState_Good);
		}
		else
		{
			Time = class'UIUtilities_text'.static.GetTimeRemainingString(Hours);
		}
	
		Requirements = class'UIUtilities_Strategy'.static.GetStrategyReqString(ItemTemplate.Requirements);
		if (EngBonus > 0) // Append the Eng Discount if one applies
		{
			if (Requirements != "")
				Requirements $= "\n";
			
			Requirements $= class'UIUtilities_Strategy'.static.GetEngineeringDiscountString(ItemTemplate.Requirements.RequiredEngineeringScore);
		}

		// ---------------------------

		mc.BeginFunctionOp("PopulateCostData");
		mc.QueueString(m_strCostLabel);
		mc.QueueString(Cost);
		mc.QueueString(m_strTimeToBuildLabel);
		mc.QueueString(Time);
		mc.QueueString(Requirements);
		mc.EndOp();
	}
}

simulated function PopulateUnitCard(X2MPCharacterTemplate kCharacterTemplate)
{
	local X2CharacterTemplateManager CharTemplateManager;
	local X2CharacterTemplate CharTemplate;
	local X2SoldierClassTemplateManager SoldierClassManager;
	local string strDisplayText;

	CharTemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	SoldierClassManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	strDisplayText = "";

	CharTemplate = CharTemplateManager.FindCharacterTemplate(kCharacterTemplate.CharacterTemplateName);

	if(CharTemplate != none)
	{
		if(CharTemplate.DataName == 'Soldier')
		{
			strDisplayText $= SoldierClassManager.FindSoldierClassTemplate(kCharacterTemplate.SoldierClassTemplateName).DisplayName $ class'UIMPShell_CharacterTemplateSelector'.default.m_strSoldierClassDivider;
		}
		else if(CharTemplate.bIsAdvent)
		{
			strDisplayText $= class'UIMPShell_CharacterTemplateSelector'.default.m_strAdventPrefix;
		}
	}

	strDisplayText $= kCharacterTemplate.DisplayName;

	PopulateData(strDisplayText, 
		kCharacterTemplate.DisplayDescription, 
		"", 
		kCharacterTemplate.SelectorImagePath);
}

defaultproperties
{
	LibID = "X2ItemCard";
	bWaitingForImageUpdate = false;
}
