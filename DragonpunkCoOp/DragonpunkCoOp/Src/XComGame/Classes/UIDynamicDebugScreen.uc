//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMapList.uc
//  AUTHOR:  Brit Steiner - 3/18/11
//  PURPOSE: This file corresponds to the server browser list screen in the shell. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 


class UIDynamicDebugScreen extends UIScreen
	dependson(UIStaffIcon);

var localized string FontCharacterTest; 
var localized string LocStringTest0;
var localized string LocStringTest1;

//--------------------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{

	super.InitScreen(InitController, InitMovie, InitName);

	//Movie.Pres.UIDrawGridPixel(100, 100);

	//TestNavigation();
	//TestNavigationCascading();
	//TestManualNavigation(); 
	//TestNavHelpBar();

	//TestHorizontalList();
	//TestVericalList();
	//TestVericalListWithConfirms();
	//TestHorizontalScrollingText();
	//TestVerticalScrollingText();

	//TestPolishNames();
	//TestLocString();

	//TestTooltip(); 
	//TestTextFormatting();

	//TestAnimation();

	//TestMouseHandling();

	//TestColorSelector();
	//TestToDoWidget();
	//TestObjectives();
	//TestStrategyShortcuts();
	//TestIconAutoColoring(); 
	//TestEventNotices();
	//TestProgressBars(); 

	//TestDebugPanel();

	//TestEventQueue();

	//TestLargeButton();

	//TestSimpleSpinnerList();
	//TestSpinnerList();
	//TestStaffIcons();

	//TestTutorialBladeMessages();
	//TestTutorialArrows();
	TestCommanderKilledPopup();

}

function TestCommanderKilledPopup()
{
	local UICombatLose TempScreen; 

	TempScreen = Spawn(class'UICombatLose', self);
	TempScreen.m_eType = eUICombatLose_UnfailableCommanderKilled;
	Movie.Stack.Push(TempScreen);

}

simulated function TestSimpleSpinnerList()
{
	local int i;
	local UIList list;

	list = Spawn(class'UIList', self);
	list.InitList('SimpleSpinnerList', 400, 300, 400, 600);
	list.onItemClicked = OnSpinnerListItemClicked;

	for( i = 0; i < 5; ++i )
	{
		UIListItemSpinner(list.CreateItem(class'UIListItemSpinner')).InitSpinner("List Item" @ list.itemCount, string(i), OnSpinnerChangedCallback);
	}

}

simulated function OnSpinnerChangedCallback(UIListItemSpinner spinnerControl, int direction)
{
	`log("OnSpinnerChangedCallback You CHANGED direction of spinner: " $spinnerControl.Name @" in direction: "$ string(direction));
	// FIRST Do codey stuff based on the direction that was pressed...
	// THEN: make sure to tell the spinner to update it's value, to reflect whatever changed in game. 
	spinnerControl.SetValue(string(direction));
}

simulated function OnSpinnerListItemClicked(UIList listControl, int itemIndex)
{
	`log("OnSpinnerListItemClicked You CLICKED the list: " $listControl.Name @" item index: "$ string(itemIndex));
}

simulated function OnSpinnerListClick()
{
	`log("OnSpinnerListClick You CLICKED the whole line item.");
}

simulated function TestSpinnerList()
{
	local int i;
	local UIList list;
	local UIMechaListItem item;

	list = Spawn(class'UIList', self);
	list.InitList('SpinnerList', 1300, 300, 400, 600);
	list.onItemClicked = OnSpinnerListItemClicked;

	for( i = 0; i < 5; ++i )
	{
		Item = UIMechaListItem(list.CreateItem(class'UIMechaListItem')).InitListItem();
		Item.UpdateDataSpinner("New item" @ i,
						"Init spinner val",
						OnSpinnerChangedCallback);
	}

}

simulated function TestMouseHandling()
{
	Spawn(class'UIPanel', self)
		.InitPanel('MouseTest', class'UIUtilities_Controls'.const.MC_GenericPixel)
		.ProcessMouseEvents(TestOnMouseEvent)
		.SetPosition(100, 100)
		.SetSize(50, 50)
		.SetRotationDegrees(45);
}

simulated function TestOnMouseEvent(UIPanel control, int cmd)
{
	switch(cmd)
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN: 
			control.SetColor(class'UIUtilities_Colors'.const.BAD_HTML_COLOR);
			break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
			control.SetColor(class'UIUtilities_Colors'.const.GOOD_HTML_COLOR);
			break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
			control.SetColor(class'UIUtilities_Colors'.const.DISABLED_HTML_COLOR);
			control.IgnoreMouseEvents();
			break;
	}
}

simulated function TestHorizontalScrollingText()
{
	Spawn(class'UIScrollingText', self).InitScrollingText('', "SUPER LONG TEXT THAT MUST SCROLL FOR SURE", 100, 100, 120);
}

simulated function TestVerticalScrollingText()
{
	local int i;
	local string txt;
	for(i = 0; i < 10; ++i)
	{
		txt $= "SUPER LONG TEXT THAT MUST SCROLL FOR SURE " $ i $ "_";
	}
	Spawn(class'UITextContainer', self).InitTextContainer('', txt, 700, 120, 500, 200, true);
}

simulated function TestHorizontalList()
{
	local int i;
	local UIList list;

	list = Spawn(class'UIList', self);
	list.InitList('HorizontalList', 100, 175, 620, 50, true, true);
	list.onItemClicked = TestListItemClicked;

	for(i = 0; i < 10; ++i)
	{
		UIListItemString(list.CreateItem()).InitListItem("List Item" @ i).SetTooltipText("Tooltip test " $i);
	}
}

simulated function TestVericalList()
{
	local int i;
	local UIList list;

	list = Spawn(class'UIList', self);
	list.InitList('VericalList', 100, 300, 400, 600, false, true);
	list.onItemClicked = TestListItemClicked;

	for(i = 0; i < 20; ++i)
	{
		UIListItemString(list.CreateItem()).InitListItem(class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.const.HTML_PromotionIcon, 20, 20, 0) @"List Item with a long bit of text" @ list.itemCount).SetConfirmButtonStyle(eUIConfirmButtonStyle_Default, "WEEE");
	}

	UIListItemString(list.GetItem(3)).NeedsAttention(true);
}

simulated function TestListItemClicked(UIList listControl, int itemIndex)
{
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
}


simulated function TestVericalListWithConfirms()
{
	local int i;
	local UIList list;

	local UIListItemString Item; 

	list = Spawn(class'UIList', self);
	list.InitList('VericalListConfirms', 700, 200, 450, 600);
	list.OnItemDoubleClicked = TestListItemConfirmDoubleClicked;
	list.SetSelectedNavigation();
	list.Navigator.LoopSelection = true;

	for( i = 0; i < 5; ++i )
	{
		Item = UIListItemString(list.CreateItem()).InitListItem("List Item that has a long string so long more text very long but this is the end." @ list.itemCount);
		Item.SetConfirmButtonStyle(eUIConfirmButtonStyle_Default, "CONFIRM");
	}
	//#5: 
	//Item.SetBad(true);
	
	for(i = 0; i < 2; ++i)
	{
		Item = UIListItemString(list.CreateItem()).InitListItem("List Item with X" @ list.itemCount);
		//Item.SetConfirmButtonStyle(eUIConfirmButtonStyle_X);
	}
	/*for( i = 0; i < 2; ++i )
	{
		Item = UIListItemString(list.CreateItem()).InitListItem("List Item with Check" @ list.itemCount);
		Item.SetConfirmButtonStyle(eUIConfirmButtonStyle_Check);
	}
	for( i = 0; i < 2; ++i )
	{
		Item = UIListItemString(list.CreateItem()).InitListItem("List Item Sci" @ list.itemCount);
		Item.SetConfirmButtonStyle(eUIConfirmButtonStyle_BuyScience);
	}
	for( i = 0; i < 2; ++i )
	{
		Item = UIListItemString(list.CreateItem()).InitListItem("List Item with Eng" @ list.itemCount);
		Item.SetConfirmButtonStyle(eUIConfirmButtonStyle_BuyEngineering);
	}*/

	Navigator.SetSelected(List);
	List.Navigator.SelectFirstAvailableIfNoCurrentSelection();
}

simulated function TestListItemConfirmDoubleClicked(UIList listControl, int itemIndex)
{

	`log("Confirming: " @ listControl.GetItem(itemIndex));
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
}

simulated function TestManualNavigation() 
{
	local UIButton c0b0, c0b1, c0b2; 
	local UIButton c1b0, c1b1, c1b2; 
	local UIButton c2b0, c2b1, c2b2; 
	local UIPanel kContainer; 

	kContainer = Spawn(class'UIPanel', self).InitPanel('Container0').SetPosition(550, 300);
	c0b0 = UIButton(Spawn(class'UIButton', kContainer).InitButton('Button_0', "C 0 N 0",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(0, 0));
	c0b1 = UIButton(Spawn(class'UIButton', kContainer).InitButton('Button_1', "C 0 N 1",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(0, 50));
	c0b2 = UIButton(Spawn(class'UIButton', kContainer).InitButton('Button_2', "C 0 N 2",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(0, 100));

	kContainer = Spawn(class'UIPanel', self).InitPanel('Container1').SetPosition(750, 300);
	c1b0 = UIButton(Spawn(class'UIButton', kContainer).InitButton('Button_0', "C 1 N 0",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(0, 0));
	c1b1 = UIButton(Spawn(class'UIButton', kContainer).InitButton('Button_1', "C 1 N 1",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(0, 50));
	c1b2 = UIButton(Spawn(class'UIButton', kContainer).InitButton('Button_2', "C 1 N 2",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(0, 100));

	kContainer = Spawn(class'UIPanel', self).InitPanel('Container2').SetPosition(950, 300);
	c2b0 = UIButton(Spawn(class'UIButton', kContainer).InitButton('Button_0', "C 2 N 0",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(0, 0));
	c2b1 = UIButton(Spawn(class'UIButton', kContainer).InitButton('Button_1', "C 2 N 1",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(0, 50));
	c2b2 = UIButton(Spawn(class'UIButton', kContainer).InitButton('Button_2', "C 2 N 2",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(0, 100));



	// Notes: Optional lines below are technically unnecessary, since they were added 
	// in such an order as the normal up-down logic of the Navigator would perform 
	// the same functionality by default. 

	// First Row 
	c0b0.Navigator.AddNavTargetLeft(c2b0);
	c0b0.Navigator.AddNavTargetRight(c1b0);
	c0b0.Navigator.AddNavTargetUp(c0b2);
	c0b0.Navigator.AddNavTargetDown(c0b1);	//Optional

	c1b0.Navigator.AddNavTargetLeft(c0b0);
	c1b0.Navigator.AddNavTargetRight(c2b0);
	c1b0.Navigator.AddNavTargetUp(c1b2);
	c1b0.Navigator.AddNavTargetDown(c1b1);	//Optional

	c2b0.Navigator.AddNavTargetLeft(c1b0);
	c2b0.Navigator.AddNavTargetRight(c0b0);
	c2b0.Navigator.AddNavTargetUp(c2b2);
	c2b0.Navigator.AddNavTargetDown(c2b1);	//Optional

	// Second Row 
	c0b1.Navigator.AddNavTargetLeft(c2b1);
	c0b1.Navigator.AddNavTargetRight(c1b1);
	c0b1.Navigator.AddNavTargetUp(c0b0);	//Optional
	c0b1.Navigator.AddNavTargetDown(c0b2);	//Optional

	c1b1.Navigator.AddNavTargetLeft(c0b1);
	c1b1.Navigator.AddNavTargetRight(c2b1);
	c1b1.Navigator.AddNavTargetUp(c1b0);	//Optional
	c1b1.Navigator.AddNavTargetDown(c1b2);	//Optional

	c2b1.Navigator.AddNavTargetLeft(c1b1);
	c2b1.Navigator.AddNavTargetRight(c0b1);
	c2b1.Navigator.AddNavTargetUp(c2b0);	//Optional
	c2b1.Navigator.AddNavTargetDown(c2b2);	//Optional

	// Third Row 
	c0b2.Navigator.AddNavTargetLeft(c2b2);
	c0b2.Navigator.AddNavTargetRight(c1b2);
	c0b2.Navigator.AddNavTargetUp(c0b1);	//Optional
	c0b2.Navigator.AddNavTargetDown(c0b0);

	c1b2.Navigator.AddNavTargetLeft(c0b2);
	c1b2.Navigator.AddNavTargetRight(c2b2);
	c1b2.Navigator.AddNavTargetUp(c1b1);	//Optional
	c1b2.Navigator.AddNavTargetDown(c1b0);

	c2b2.Navigator.AddNavTargetLeft(c1b2);
	c2b2.Navigator.AddNavTargetRight(c0b2);
	c2b2.Navigator.AddNavTargetUp(c2b1);	//Optional
	c2b2.Navigator.AddNavTargetDown(c2b0);
}
simulated function TestNavigation()
{
	local UIPanel kContainer;
	local UIImage kImage;

	// Instance names should be as generic and reusable as possible
	// The convention is to take the word on the right of "UI###" and use that as the instance name:
	Spawn(class'UIBGBox', self).InitBG('BGBox', 0, 0, 500, 500).CenterOnScreen();

	Spawn(class'UISlider', self).InitSlider('Slider', "Label for the slider", 20.0).SetPosition(900, 100);

	Spawn(class'UICheckbox', self).InitCheckbox('Checkbox', "Happy checkbox")
	.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(700, 200);

	kImage = Spawn(class'UIImage', self);
	kImage.InitImage('Image', class'UIUtilities_Image'.static.GetItemImagePath(0));
	kImage.SetPosition(100, 300).SetSize(200, 200).SetAlpha(66);

	Spawn(class'UIScrollbar', self)
	.InitScrollbar('ScrollbarY', kImage )
	.NotifyValueChange( kImage.SetY, kImage.y, kImage.y + 50 ); 

	Spawn(class'UIScrollbar', self)
	.InitScrollbar('ScrollbarAlpha')
	.SnapToControl( kImage, ,false )
	.SetThumbAtPercent( 0.5 )
	.NotifyPercentChange( kImage.SetAlpha );

	kContainer = Spawn(class'UIPanel', self).InitPanel('Container').SetPosition(650, 300);
	Spawn(class'UIButton', kContainer).InitButton('Button_0', "Nav button 0",, eUIButtonStyle_BUTTON_WHEN_MOUSE);
	Spawn(class'UIButton', kContainer).InitButton('Button_1', "Nav button 1",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(0, 50);
	Spawn(class'UIButton', kContainer).InitButton('Button_2', "Nav button 2",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(0, 100);
	Spawn(class'UIButton', self).InitButton('Button', "BUTTON NOT IN CONTAINER ",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(700, 450);

	Spawn(class'UIMask', self).InitMask('Mask', kContainer, 700, 300, 250, 250);

	Navigator.LoopSelection = true;
}

simulated function TestNavigationCascading()
{
	local UIPanel kContainer0, kContainer1, kContainer2, kContainer3, kContainer4;

	kContainer0 = Spawn(class'UIPanel', self).InitPanel('Container0').SetPosition(50, 100);
	kContainer1 = Spawn(class'UIPanel', self).InitPanel('Container1').SetPosition(50, 200);
	kContainer2 = Spawn(class'UIPanel', self).InitPanel('Container2').SetPosition(50, 300);
	kContainer3 = Spawn(class'UIPanel', self).InitPanel('Container3').SetPosition(50, 400);
	kContainer4 = Spawn(class'UIPanel', self).InitPanel('Container4').SetPosition(50, 500);

	Spawn(class'UIButton', kContainer0).InitButton('Button_0', "Nav button 0");
	Spawn(class'UIButton', kContainer1).InitButton('Button_1', "Nav button 1");
	Spawn(class'UIButton', kContainer2).InitButton('Button_2', "Nav button 2");
	Spawn(class'UIButton', kContainer3).InitButton('Button_3', "Nav button 3");
	Spawn(class'UIButton', kContainer4).InitButton('Button_4', "Nav button 4");

	Navigator.LoopSelection = true;

	Navigator.SelectFirstAvailable();
}

simulated function TestNavHelpBar()
{
	local UINavigationHelp kNavHelp; 
	
	kNavHelp = Spawn(class'UINavigationHelp', self);
	kNavHelp.InitNavHelp('NavigationHelp');
	kNavHelp.SetY(-5);

	kNavHelp.AddBackButton(OnCancel);
	kNavHelp.AddRightHelp("RightHelp","");
	kNavHelp.AddCenterHelp("Center Help",""); 
}

simulated function XComGameState_Item TooltipRequestItemFromPath( string currentPath )
{
	return none;
}

simulated function TestTooltip()
{
	local UITacticalHUD_SoldierInfoTooltip TooltipStats;
	local UITacticalHUD_WeaponTooltip TooltipWeapon;
	local UIButton Button; 
	local UITacticalHUD_PerkTooltip SoldierPerks; 
	local UITacticalHUD_BuffsTooltip kSoldierBonuses, kSoldierPenalties;
	local UITacticalHUD_AbilityTooltip kAbility;
	local UITacticalHUD_EnemyTooltip kEnemyStats; 
	local UITacticalHUD_HackingTooltip kHackingTooltip;
	local UIArmory_LoadoutItemTooltip InfoTooltip; 
	
	Button = Spawn(class'UIButton', self); 
	Button.InitButton('Button_InfoTooltip', "Test Inventory",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(500, 10);

	InfoTooltip = Spawn(class'UIArmory_LoadoutItemTooltip', self); 
	InfoTooltip.InitLoadoutItemTooltip('UITooltipInventoryItemInfo');

	InfoTooltip.targetPath = string(Button.MCPath); 
	InfoTooltip.RequestItem = TooltipRequestItemFromPath; 

	InfoTooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( InfoTooltip );
	
	// Stat List ----------------
	Button = Spawn(class'UIButton', self); 
	Button.InitButton('Button_TooltipTest_0', "Test Soldier Stats",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(100, 10);

	TooltipStats = Spawn(class'UITacticalHUD_SoldierInfoTooltip', Movie.Pres.m_kTooltipMgr); 
	TooltipStats.InitSoldierStats('TooltipStatList').SetPosition(Button.X + 150, Button.Y);
	TooltipStats.targetPath = string(Button.MCPath); 
	TooltipStats.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( TooltipStats );
	
	// Weapon Stats ----------------

	Button = Spawn(class'UIButton', self); 
	Button.InitButton('Button_TooltipTest_1', "Test Weapon",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(900, 800);

	TooltipWeapon = Spawn(class'UITacticalHUD_WeaponTooltip', Movie.Pres.m_kTooltipMgr); 
	TooltipWeapon.InitWeaponStats('TooltipWeaponStats'); 

	TooltipWeapon.SetPosition(Button.X + 150, Button.Y);
	TooltipWeapon.bFollowMouse = false;
	TooltipWeapon.targetPath = string(Button.MCPath); 

	TooltipWeapon.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( TooltipWeapon );

	// Stats tooltip ------------------------------------------------------------------

	Button = Spawn(class'UIButton', self); 
	Button.InitButton('Button_TooltipTest_2', "Test Soldier Perks",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(100, 200);

	SoldierPerks = Spawn(class'UITacticalHUD_PerkTooltip', Movie.Pres.m_kTooltipMgr); 
	SoldierPerks.InitPerkTooltip('TooltipSoldierPassives').SetPosition(Button.X + 150, Button.Y);
	SoldierPerks.targetPath = string(Button.MCPath);
	SoldierPerks.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip(SoldierPerks);

	// Soldier bonuses ---------------------------------------------------------------------

	Button = Spawn(class'UIButton', self); 
	Button.InitButton('Button_TooltipTest_3', "Test Bonus",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(100, 800);

	kSoldierBonuses = Spawn(class'UITacticalHUD_BuffsTooltip', Movie.Pres.m_kTooltipMgr); 
	kSoldierBonuses.InitBonusesAndPenalties('TooltipSoldierBonuses',,true, true, Button.X + 150, Movie.m_v2ScaledDimension.Y);
	kSoldierBonuses.targetPath = string(Button.MCPath);
	kSoldierBonuses.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip(kSoldierBonuses);

	// Soldier penalties  ---------------------------------------------------------------------

	Button = Spawn(class'UIButton', self); 
	Button.InitButton('Button_TooltipTest_4', "Test Penalty",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(100, 400);

	kSoldierPenalties = Spawn(class'UITacticalHUD_BuffsTooltip', Movie.Pres.m_kTooltipMgr); 
	kSoldierPenalties.InitBonusesAndPenalties('TooltipSoldierPenalty',,false, true,Button.X + 150, Button.Y);
	kSoldierPenalties.targetPath = string(Button.MCPath);
	kSoldierPenalties.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip(kSoldierPenalties);

	// Soldier abilities  ---------------------------------------------------------------------

	Button = Spawn(class'UIButton', self); 
	Button.InitButton('Button_TooltipTest_5', "Test TooltipAbility",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(640, 600);

	kAbility = Spawn(class'UITacticalHUD_AbilityTooltip', Movie.Pres.m_kTooltipMgr); 
	kAbility.InitAbility('TooltipAbility',,Button.X + 150, Button.Y);
	kAbility.targetPath =  string(Button.MCPath);
	kAbility.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip(kAbility);

	// Enemy abilities  ---------------------------------------------------------------------

	Button = Spawn(class'UIButton', self); 
	Button.InitButton('Button_TooltipTest_6', "Test Enemy Stats",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(100, 500);

	kEnemyStats = Spawn(class'UITacticalHUD_EnemyTooltip', Movie.Pres.m_kTooltipMgr); 
	kEnemyStats.InitEnemyStats('UITooltipEnemyStats').SetPosition(Button.X + 150, Button.Y);
	kEnemyStats.targetPath =  string(Button.MCPath);
	kEnemyStats.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip(kEnemyStats);

	// Enemy abilities  ---------------------------------------------------------------------

	Button = Spawn(class'UIButton', self); 
	Button.InitButton('Button_TooltipTest_7', "Test Inventory Item Info",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(100, 600);

	// Hacking Stats ----------------

	Button = Spawn(class'UIButton', self); 
	Button.InitButton('Button_TooltipTest_8', "Test Hacking",, eUIButtonStyle_BUTTON_WHEN_MOUSE).SetPosition(100, 700);

	kHackingTooltip = Spawn(class'UITacticalHUD_HackingTooltip', Movie.Pres.m_kTooltipMgr); 
	kHackingTooltip.InitHackingStats('TooltipHackingStats'); 

	kHackingTooltip.SetPosition(Button.X + 150, Button.Y);
	kHackingTooltip.targetPath = string(Button.MCPath); 

	kHackingTooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( kHackingTooltip );

	// Shot Wings ----------------

	Spawn(class'UITacticalHUD_ShotWings', self).InitShotWings().Show();
}

simulated function TestTextFormatting()
{
	local UIText Value; 

	Value = Spawn(class'UIText', self).InitText(, "");
	Value.SetWidth(100); 
	Value.SetPosition(10, 10);
	Value.DebugControl();

	Value.SetHTMLText( class'UIUtilities_Text'.static.StyleText("Right Test", eUITextStyle_Tooltip_HackBodyRight, eUIState_Normal ));
}

simulated function TestAnimation()
{
	local UIText Value; 

	Value = Spawn(class'UIText', self).InitText(, "");
	Value.SetWidth(100); 
	Value.SetPosition(10, 10);
	Value.DebugControl();
	Value.SetHTMLText( class'UIUtilities_Text'.static.StyleText("Right Test", eUITextStyle_Tooltip_HackBodyRight, eUIState_Normal ));

	Value.AddTween("_x", 500, 3.0);
}

simulated function TestColorSelector()
{
	local UIColorSelector ColorSelector; 
	/*local array<string> Colors; 

	Colors.AddItem("546f6f");
	Colors.AddItem("53b45e");
	Colors.AddItem("fef4cb");*/

	ColorSelector = Spawn(class'UIColorSelector', self);
	ColorSelector.InitColorSelector( , , , , , , TestColor_OnSelect, TestColor_OnAccept ); 
}

simulated function TestColor_OnSelect(int iIndex)
{
	`log( "You selected color #"$iIndex$". Pretend like this previewed the color on the model." ); 
}
simulated function TestColor_OnAccept(int iIndex)
{
	`log( "You confirmed color #"$iIndex$". Pretend like this confirmed the change and updated color on the model." ); 
}

simulated function TestToDoWidget()
{
	local UIToDoWidget ToDoWidget;

	ToDoWidget = Spawn(class'UIToDoWidget', self);
	//ToDoWidget.InitToDoWidget('', 50, 800);
	ToDoWidget.InitToDoWidget('ToDoWidget');
	ToDoWidget.AnchorTopLeft().SetPosition(10, 100);
}


simulated function TestObjectives()
{
	local UIObjectiveList Objectives;

	Objectives = Spawn(class'UIObjectiveList', self);
	Objectives.InitObjectiveList();
}

simulated function TestStrategyShortcuts()
{
	local UIAvengerShortcuts ShortcutMenu;

	ShortcutMenu = Spawn(class'UIAvengerShortcuts', self);
	//ToDoWidget.InitToDoWidget('', 50, 800);
	ShortcutMenu.InitShortcuts('ShortcutMenu');
	ShortcutMenu.AnchorTopLeft().SetPosition(10, 100);
}


simulated function TestIconAutoColoring()
{
	local UIIcon Icon; 

	Icon = Spawn(class'UIIcon', self).InitIcon('TestIconColoring',"img:///UILibrary_StrategyImages.StrategyShortcut_Personnel",,,64);
	Icon.LoadIconBG(class'UIUtilities_Image'.const.StrategyShortcutIconBG);
	Icon.SetPosition(10, 500);
	Icon.ProcessMouseEvents( OnTestIconAutoColoringEvent );
	Icon.EnableMouseAutomaticColorStates(eUIState_Good);
}

simulated function OnTestIconAutoColoringEvent(UIPanel Control, int cmd)
{
	`log( "OnTestIconAutoColoringEvent: " $ Control.MCName );
}



simulated function TestEventNotices()
{
	Movie.Pres.m_kEventNotices.Notify(`XEXPAND.ExpandString("<Bullet/>Test notice!"), class'UIUtilities_Image'.const.EventQueue_Staff);
	Movie.Pres.m_kEventNotices.Notify("<Bullet/>Test notice with a longer bit of text!", class'UIUtilities_Image'.const.EventQueue_Resistance);
	Movie.Pres.m_kEventNotices.Notify("<Bullet/>Test notice!", class'UIUtilities_Image'.const.EventQueue_Staff);
	Movie.Pres.m_kEventNotices.Notify("<Bullet/>Test notice with a longer bit of text!", class'UIUtilities_Image'.const.EventQueue_Resistance);
	Movie.Pres.m_kEventNotices.Notify("<Bullet/>Test notice!", class'UIUtilities_Image'.const.EventQueue_Staff);
	Movie.Pres.m_kEventNotices.Notify("<Bullet/>Test notice with a longer bit of text!", class'UIUtilities_Image'.const.EventQueue_Resistance);
}

simulated function TestProgressBars()
{
	Spawn(class'UIProgressBar', self).InitProgressBar(, 20, 20, 300, 30, 0.5, eUIState_Normal);
	Spawn(class'UIProgressBar', self).InitProgressBar(, 20, 80, 500, 30, 0.25, eUIState_Bad);
}

simulated function TestDebugPanel()
{
	local int i; 

	for( i = 0; i < 20; i++ )
	{
		Movie.Pres.GetDebugInfo().AddText("Test some text! This is a long string of text to fill in. " $ i);
	}
}

simulated function TestEventQueue()
{
	local UIEventQueue EventQueue; 
	local HQEvent TempEvent; 
	local array<HQEvent> arrEvents; 
	local int idx; 

	EventQueue = Spawn(class'UIEventQueue', self).InitEventQueue();
	EventQueue.Hide(); // Start off hidden

	for( idx = 0; idx < 10; idx++ )
	{
		TempEvent.Data = "Temp event " $idx; 
		TempEvent.Hours = 99;
		TempEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Resistance;
		arrEvents.AddItem(TempEvent);
	}

	EventQueue.UpdateEventQueue(arrEvents, true, false);
	EventQueue.Show();
}

simulated function TestLargeButton()
{
	local UILargeButton Button; 

	//Button = Spawn(class'UILargeButton', self);
	//Button.InitLargeButton('TestLargeButton', "UPGRADE", "TITLE AREA", TestClickLargeButton, );
	//Button.AnchorBottomRight();

	Button = Spawn(class'UILargeButton', self);
	Button.InitLargeButton('TestLargeButton2', "UPGRADE2 with a longer name", "", TestClickLargeButton, );
	Button.AnchorBottomRight();

}

public function TestClickLargeButton(UIButton Button)
{
	`log("Test clicked Large Button! " @Button.Name);
}

function TestStaffIcons()
{
	local UIList	List;
	local int i; 
	
	List = Spawn(class'UIList', self);
	List.InitList(, 10, 50, 400, 20, true);
	List.bAnimateOnInit = false;
	List.ShrinkToFit();
	List.bStickyHighlight = false;

	// Quick cycle through all of the members of EUIStaffIconType
	for( i = 0; i < 9; i++ )
	{
		CreateStaffIcon(List, i);
	}
}

function CreateStaffIcon(UIList List, int type)
{
	local UIStaffIcon Icon;

	Icon = UIStaffIcon(List.CreateItem(class'UIStaffIcon'));
	Icon.InitStaffIcon();
	Icon.SetType(EUIStaffIconType(type));
	Icon.ProcessMouseEvents(OnClickStaffIcon);
}

public function OnClickStaffIcon(UIPanel Panel, int Cmd)
{
	`log("OnClickStaffIcon");
}

simulated function TestTutorialBladeMessages()
{
	local string Msg; 

	Msg = "This is a tutorial message. Press %KEY:ENTER% to do some stuff.";
	Msg = class'UIUtilities_Input'.static.InsertPCIcons(Msg); 
	Movie.Pres.GetWorldMessenger().BladeMessage(Msg, "blademessage");
}

function TestPolishNames()
{
	local UIText Value;

	Spawn(class'UIPanel', self).InitPanel('BGBoxSimple', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple).SetSize(300, 500);

	Value = Spawn(class'UIText', self).InitText();
	Value.SetWidth(200);
	Value.SetPosition(10, 10);
	Value.SetHTMLText(FontCharacterTest);
}

function TestLocString()
{
	local UIText Value;

	Spawn(class'UIPanel', self).InitPanel('BGBoxSimple', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple).SetSize(300, 500);

	Value = Spawn(class'UIText', self).InitText();
	Value.SetWidth(200);
	Value.SetPosition(10, 10);
	Value.SetHTMLText(LocStringTest0);

	Value = Spawn(class'UIText', self).InitText();
	Value.SetWidth(200);
	Value.SetPosition(10, 50);
	Value.SetHTMLText(LocStringTest1);

	Value = Spawn(class'UIText', self).InitText();
	Value.SetWidth(200);
	Value.SetPosition(10, 100);
	Value.SetHTMLText(Caps(LocStringTest0));

	Value = Spawn(class'UIText', self).InitText();
	Value.SetWidth(200);
	Value.SetPosition(10, 150);
	Value.SetHTMLText(Caps(LocStringTest1));


	Value = Spawn(class'UIText', self).InitText();
	Value.SetWidth(500);
	Value.SetPosition(10, 200);
	Value.SetTitle(LocStringTest0);

	Value = Spawn(class'UIText', self).InitText();
	Value.SetWidth(500);
	Value.SetPosition(10, 250);
	Value.SetTitle(LocStringTest1);

	Value = Spawn(class'UIText', self).InitText();
	Value.SetWidth(500);
	Value.SetPosition(10, 300);
	Value.SetTitle(Caps(LocStringTest0));

	Value = Spawn(class'UIText', self).InitText();
	Value.SetWidth(500);
	Value.SetPosition(10, 350);
	Value.SetTitle(Caps(LocStringTest1));
}

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;
	local UIPanel ChildPanel; 

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
			if(GetChild('MouseTest') != none)
				GetChild('MouseTest').ProcessMouseEvents(TestOnMouseEvent);
			break;

		case class'UIUtilities_Input'.const.FXS_KEY_W:
			Movie.Pres.m_kEventNotices.Notify("A fresh test notice!");
			break;

		case class'UIUtilities_Input'.const.FXS_KEY_1:
			ChildPanel = GetChild('Button_1');
			if( ChildPanel != none )
				ChildPanel.Remove();

			ChildPanel = GetChild('Container1');
			ChildPanel.DisableNavigation();
			Navigator.SelectFirstAvailable();
			break;
		case class'UIUtilities_Input'.const.FXS_KEY_2:
			ChildPanel = GetChild('Button_2');
			if( ChildPanel != none )
				ChildPanel.Remove();

			ChildPanel = GetChild('Container2');
			ChildPanel.DisableNavigation();
			Navigator.SelectFirstAvailable();
			break;
		case class'UIUtilities_Input'.const.FXS_KEY_3:
			ChildPanel = GetChild('Button_3');
			if( ChildPanel != none )
				ChildPanel.Remove();

			ChildPanel = GetChild('Container3');
			ChildPanel.DisableNavigation();
			Navigator.SelectFirstAvailable();
			break;
		case class'UIUtilities_Input'.const.FXS_KEY_4:
			ChildPanel = GetChild('Button_4');
			if( ChildPanel != none )
				ChildPanel.Remove();

			ChildPanel = GetChild('Container4');
			ChildPanel.DisableNavigation();
			Navigator.SelectFirstAvailable();
			break;
		case class'UIUtilities_Input'.const.FXS_KEY_5:
			ChildPanel = GetChild('Button_5');
			if( ChildPanel != none )
				ChildPanel.Remove();

			ChildPanel = GetChild('Container5');
			ChildPanel.DisableNavigation();
			Navigator.SelectFirstAvailable();
			break;

		case class'UIUtilities_Input'.const.FXS_KEY_6:
			Movie.Pres.GetWorldMessenger().RemoveMessage("blademessage");
			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			Movie.Stack.Pop(self);
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated function OnCancel()
{
	Movie.Stack.Pop(self);
}

simulated function OnRemoved()
{
	super.OnRemoved();
	
	Movie.Pres.UIClearGrid();
}


//==============================================================================
//		DEFAULTS:
//==============================================================================
DefaultProperties
{
	InputState = eInputState_Evaluate;
}
