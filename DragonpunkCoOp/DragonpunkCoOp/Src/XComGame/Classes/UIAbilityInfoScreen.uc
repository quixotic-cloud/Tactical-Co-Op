class UIAbilityInfoScreen extends UIScreen 
	dependson(UIQueryInterfaceUnit);

var XComGameState_Unit GameStateUnit;

var UIList ListAbilities;
var UIScrollbar Scrollbar;

var localized array<String> StatLabelStrings;
var localized String HeaderAbilities;

simulated function UIAbilityInfoScreen InitAbilityInfoScreen(XComPlayerController InitController, UIMovie InitMovie, 
	optional name InitName)
{
	InitScreen(InitController, InitMovie, InitName);

	return Self;
}

simulated function OnInit()
{
	local int i;
	local UIButton NavHint;
	local array<UIScrollingHTMLText> StatLabels;

	super.OnInit();

	ListAbilities = Spawn(class'UIList', self, 'mc_perks');
	ListAbilities.InitList('mc_perks',,, 755, 418);

	for (i = 0; i < 7; i++)
	{
		StatLabels.AddItem(Spawn(class'UIScrollingHTMLText', Self));
		if (StatLabels[i] != None)
		{
			StatLabels[i].InitScrollingText(Name("mc_statLabel0" $ i));
			StatLabels[i].SetCenteredText(i < StatLabelStrings.Length ? StatLabelStrings[i] : "");
		}
	}

	NavHint = Spawn(class'UIButton', Self);
	NavHint.InitButton('mc_closeBtn', class'UIUtilities_Text'.default.m_strGenericBack,, 
		eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
	NavHint.SetGamepadIcon(class'UIUtilities_Input'.static.GetBackButtonIcon());
		
	PopulateCharacterData();

	SimulateMouseHovers(true);
}

simulated function SetGameStateUnit(XComGameState_Unit InGameStateUnit)
{
	GameStateUnit = InGameStateUnit;
}

simulated function PopulateCharacterData()
{
	local XGUnit kActiveUnit;
	local XComGameState_Unit kGameStateUnit;
	local UIScrollingHTMLText NameHeader;
	local UIScrollingText ClassNameLabel;
	local UIIcon ClassIcon;
	local X2SoldierClassTemplate SoldierClassTemplate;

	if (PC != none && XComTacticalController(PC) != none)
	{
		kActiveUnit = XComTacticalController(PC).GetActiveUnit();

		if (kActiveUnit == none)
		{
			return;	
		}

		kGameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
	}
	else if (GameStateUnit != none)
	{
		kGameStateUnit = GameStateUnit;
	}

	if (kGameStateUnit == none)
	{
		return;
	}

	NameHeader = Spawn(class'UIScrollingHTMLText', Self);
	NameHeader.InitScrollingText('mc_nameLabel',"initializing...",,,,true);

	SoldierClassTemplate = kGameStateUnit.GetSoldierClassTemplate();
	if(SoldierClassTemplate != None)
	{
		//Show full name/rank
		NameHeader.SetTitle(kGameStateUnit.GetName(eNameType_FullNick));

		//Initialize Soldier-Class Name
		ClassNameLabel = Spawn(class'UIScrollingText', Self);
		ClassNameLabel.InitScrollingText('mc_classLabel');
		ClassNameLabel.SetHTMLText(SoldierClassTemplate.DisplayName);

		//Initialize the Class Icon
		ClassIcon = Spawn(class'UIIcon', Self);
		ClassIcon.InitIcon('mc_classIcon',,,false,42,eUIState_Normal);
		ClassIcon.LoadIcon(SoldierClassTemplate.IconImage);
	}
	else
	{
		//Don't ask for rank - Necessary to handle VIPs; asking for their rank shows them as "rookie"
		NameHeader.SetTitle(kGameStateUnit.GetName(eNameType_Full));

		//In place of the soldier-class name, show their character class (if different from their name)
		if(kGameStateUnit.GetName(eNameType_Full) != kGameStateUnit.GetMyTemplate().strCharacterName)
		{
			ClassNameLabel = Spawn(class'UIScrollingText', Self);
			ClassNameLabel.InitScrollingText('mc_classLabel');
			ClassNameLabel.SetHTMLText(kGameStateUnit.GetMyTemplate().strCharacterName);
		}

		//Use the Class Icon to show ADVENT/Alien symbol instead
		ClassIcon = Spawn(class'UIIcon', Self);
		ClassIcon.InitIcon('mc_classIcon',,,false,42,eUIState_Normal);
		ClassIcon.LoadIcon("img://" $ kGameStateUnit.GetMyTemplate().strTargetIconImage);
		ClassIcon.SetForegroundColorState(eUIState_Normal);
	}

	PopulateStatValues(kGameStateUnit);
	PopulateCharacterAbilities(kGameStateUnit);

	Navigator.Clear(); //Default Navigation can cause focus issues on this screen if left on (use OnUnrealCommand unless list selection becomes necessary) - JTA 2016/5/20
}

simulated function PopulateStatValues(XComGameState_Unit kGameStateUnit)
{
	local int i, StatValueInt;
	local UIScrollingHTMLText StatLabel;
	local String StatLabelString;
	local EUISummary_UnitStats UnitStats;

	UnitStats = kGameStateUnit.GetUISummary_UnitStats();

	for (i = 0; i < 7; ++i)
	{
		StatValueInt = -1;
		switch(i)
		{
		case 0:
			StatLabelString = UnitStats.CurrentHP $ "/" $ UnitStats.MaxHP;
			break;

		case 1:
			StatValueInt = UnitStats.Aim;
			break;

		case 2:
			StatValueInt = UnitStats.Tech;
			break;
		case 3:

			StatValueInt = UnitStats.Will;
			break;

		case 4:
			StatValueInt = UnitStats.Armor;
			break;

		case 5:
			StatValueInt = UnitStats.Dodge;
			break;

		case 6:
			StatValueInt = UnitStats.PsiOffense;
			break;

		default:
			StatLabelString = "";
			break;
		}
		
		if (StatValueInt >= 0)
		{
			StatLabelString = StatValueInt > 0 ? String(StatValueInt) : "---";
		}

		StatLabel = None;
		StatLabel = Spawn(class'UIScrollingHTMLText', Self);
		if (StatLabel != None)
		{
			StatLabel.InitScrollingText(Name('mc_statValue0' $ i));
			StatLabel.SetCenteredText(StatLabelString);
		}		
	}
}

simulated function PopulateCharacterAbilities(XComGameState_Unit kGameStateUnit)
{	
	AddAbilitiesToList(kGameStateUnit, HeaderAbilities);
}

simulated function array<X2AbilityTemplate> GetAbilityTemplates(XComGameState_Unit Unit, 
	optional XComGameState CheckGameState)
{
	local int i;
	local X2AbilityTemplate AbilityTemplate;
	local array<AbilitySetupData> AbilitySetupList;
	local array<SoldierClassAbilityType> AbilityTree;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<X2AbilityTemplate> AbilityTemplates;

	if (Unit.IsSoldier())
	{
		AbilityTree = Unit.GetEarnedSoldierAbilities();
		AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

		for (i = 0; i < AbilityTree.Length; ++i)
		{
			AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[i].AbilityName);
			if (!AbilityTemplate.bDontDisplayInAbilitySummary)
			{
				AbilityTemplates.AddItem(AbilityTemplate);
			}
		}
	}
	else
	{
		AbilitySetupList = Unit.GatherUnitAbilitiesForInit(CheckGameState,, true);

		for (i = 0; i < AbilitySetupList.Length; ++i)
		{
			AbilityTemplate = AbilitySetupList[i].Template;
			if (!AbilityTemplate.bDontDisplayInAbilitySummary)
			{
				AbilityTemplates.AddItem(AbilityTemplate);
			}
		}
	}

	return AbilityTemplates;
}

simulated function AddAbilitiesToList(XComGameState_Unit kGameStateUnit, String Header_Text, 
	optional EUIState UIState = eUIState_Normal)
{
	local array<X2AbilityTemplate> Abilities;
	local UIText HeaderListItem;
	local UIListItemAbility ListItem;
	local int i;

	Abilities = GetAbilityTemplates(kGameStateUnit, XComGameState(kGameStateUnit.Outer));
	if (Abilities.Length > 0)
	{
		HeaderListItem = Spawn(class'UIText', ListAbilities.ItemContainer);
		HeaderListItem.LibID = 'mc_columnHeader';		
		HeaderListItem.InitText(,Header_Text);
		HeaderListItem.SetColor(class'UIUtilities_Colors'.static.GetHexColorFromState(UIState));
		HeaderListItem.SetHeight(40);

		for (i = 0; i < Abilities.Length; i++)
		{
			ListItem = Spawn(class'UIListItemAbility', ListAbilities.ItemContainer);
			ListItem.InitListItemPerk(Abilities[i], eUIState_Normal);
			ListItem.SetX(class'UIListItemAbility'.default.Padding);
		}
	}
}

simulated function HandleScrollBarInput(bool bDown)
{
	if (ListAbilities != none && ListAbilities.Scrollbar != none)
	{
		if (bDown)	
		{
			ListAbilities.Scrollbar.OnMouseScrollEvent(-1);
		}
		else			
		{
			ListAbilities.Scrollbar.OnMouseScrollEvent(1);
		}
		PlaySound(SoundCue'SoundUI.MenuScrollCue', true);
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		HandleScrollBarInput(cmd == class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN);
		return true;

	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		if (CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		{
			CloseScreen();
		}

		return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function bool SimulateMouseHovers(bool bIsHovering)
{
	local UITooltipMgr Mgr;
	local String WeaponMCPath;
	local int MouseCommand;
	local UITacticalHUD TacticalHUD;

	if (bIsHovering)
	{
		MouseCommand = class'UIUtilities_Input'.const.FXS_L_MOUSE_IN;
	}
	else
	{
		MouseCommand = class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT;	
	}

	Mgr = Movie.Pres.m_kTooltipMgr;

	TacticalHUD = UITacticalHUD(Movie.Pres.ScreenStack.GetScreen(class'UITacticalHUD'));
	if (TacticalHUD != None)
	{
		if (TacticalHUD.m_kInventory != None)
		{	
			WeaponMCPath = String(TacticalHUD.m_kInventory.m_kWeapon.MCPath);
			Mgr.OnMouse(WeaponMCPath, MouseCommand, WeaponMCPath);
		}
	}

	return true;
}

simulated function CloseScreen()
{
	SimulateMouseHovers(false);

	super.CloseScreen();	
}

defaultproperties
{
	Package = "/ package/gfxTacticalCharInfo/TacticalCharInfo";
	MCName = "mc_tacticalCharInfo";
	InputState = eInputState_Consume;
	bIsNavigable = true;
}