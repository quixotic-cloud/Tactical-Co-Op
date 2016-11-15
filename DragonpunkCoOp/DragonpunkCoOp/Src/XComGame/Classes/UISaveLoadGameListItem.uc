class UISaveLoadGameListItem extends UIPanel;

var UIButton AcceptButton;
var UIButton DeleteButton;
var UIButton RenameButton;

var OnlineSaveGame SaveGame;

var int         Index;
var int			ID; 
var bool        bIsSaving;
var UIPanel		ButtonBG;
var name		ButtonBGLibID;
var string		DateTimeString;
var	bool		bIsDifferentLanguage;

var UIList List;

var localized string m_sNewSaveLabel;
var localized string m_sSaveLabel;
var localized string m_sLoadLabel;
var localized string m_sDeleteLabel;
var localized string m_sRenameLabel;

var delegate<OnMouseInDelegate> OnMouseIn;

// mouse callbacks
delegate OnClickedDelegate(UIButton Button);
delegate OnMouseInDelegate(int ListIndex);
simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);

	List = UIList(GetParent(class'UIList')); // list items must be owned by UIList.ItemContainer
	if(List == none)
	{
		ScriptTrace();
		`warn("UI list items must be owned by UIList.ItemContainer");
	}

	return self;
}

simulated function UISaveLoadGameListItem InitSaveLoadItem(int listIndex, OnlineSaveGame save, bool bSaving, optional delegate<OnClickedDelegate> AcceptClickedDelegate, optional delegate<OnClickedDelegate> DeleteClickedDelegate, optional delegate<OnClickedDelegate> RenameClickedDelegate, optional delegate<OnMouseInDelegate> MouseInDelegate)
{
	local XComOnlineEventMgr OnlineEventMgr;

	OnlineEventMgr = `ONLINEEVENTMGR;

	ID = OnlineEventMgr.SaveNameToID(save.Filename);
	InitPanel();
	Index = listIndex;

	SaveGame = save;
	bIsSaving = bSaving;
	
	SetWidth(List.width);

	SetY(135 * listIndex);
	ButtonBG = Spawn(class'UIPanel', self);
	ButtonBG.bIsNavigable = false;
	ButtonBG.bCascadeFocus = false;
	ButtonBG.InitPanel(ButtonBGLibID);

	//Navigator.HorizontalNavigation = true;
	
	AcceptButton = Spawn(class'UIButton', ButtonBG);
	AcceptButton.bIsNavigable = false;
	AcceptButton.InitButton('Button0', GetAcceptLabel(ID == -1), ID == -1 ? RenameClickedDelegate : AcceptClickedDelegate); 
	if (`ISCONTROLLERACTIVE)
	{
		AcceptButton.SetStyle(eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
		AcceptButton.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
		AcceptButton.SetVisible(bIsFocused);
	}
	AcceptButton.OnMouseEventDelegate = OnChildMouseEvent;

	DeleteButton = Spawn(class'UIButton', ButtonBG);
	DeleteButton.bIsNavigable = false;
	DeleteButton.InitButton('Button1', GetDeleteLabel(), DeleteClickedDelegate);
	if (`ISCONTROLLERACTIVE) 
	{
		DeleteButton.SetStyle(eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
		DeleteButton.SetGamepadIcon(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
		DeleteButton.SetVisible(bIsFocused);
	}
	DeleteButton.OnMouseEventDelegate = OnChildMouseEvent;
	
	if(bIsSaving && ID == -1)
	{
		DeleteButton.Hide();
	}
	
	RenameButton = Spawn(class'UIButton', ButtonBG);
	RenameButton.bIsNavigable = false;
	RenameButton.InitButton('Button2', m_sRenameLabel, RenameClickedDelegate);
	RenameButton.Hide(); //No longer used, hidden permanently. 
	RenameButton.OnMouseEventDelegate = OnChildMouseEvent;

	OnMouseIn = MouseInDelegate;

	return self;
}

simulated function OnInit()
{
	super.OnInit();

	UpdateData(SaveGame);
	if (`ISCONTROLLERACTIVE) 
	{
		// Initially when UpdateData gets called, it invokes the actionscript's UpdateData function
		// that decides it's a good idea to unhighlight the button.
		if( bIsFocused )
		{
			OnReceiveFocus();
			UIPanel(Owner).Navigator.SetSelected(self);
		}
	}
}

function bool ImageCheck()
{
	local string MapName;
	local array<string> Path; 

	//Check to see if the image fails, and clear the image if failed so the default image will stay.

	MapName = SaveGame.SaveGames[0].SaveGameHeader.MapImage;

	Path = SplitString(mapname, ".");

	if( Path.length < 2 ) //you have a malformed path 
		return false;

	return `XENGINE.DoesPackageExist(Path[0]); 
}

simulated function string GetAcceptLabel( bool bIsNewSave )
{
	local string acceptLabel;

	if( bIsSaving )
	{
		if( bIsNewSave )
		{
			acceptLabel = m_sNewSaveLabel;
		}
		else
		{
			acceptLabel = m_sSaveLabel;
		}
	}
	else
	{
		acceptLabel = m_sLoadLabel;
	}

	/*if( bIsFocused && `ISCONTROLLERACTIVE )
	{
		acceptLabel = class'UIUtilities_Input'.static.InsertGamepadIcons("%A" @ acceptLabel);
	}*/
	return acceptLabel;
}

simulated function string GetDeleteLabel()
{
	local string deleteLabel;

	deleteLabel = m_sDeleteLabel;

	/*if( bIsFocused && `ISCONTROLLERACTIVE )
	{
		deleteLabel = class'UIUtilities_Input'.static.InsertGamepadIcons("%Y" @ deleteLabel);
	}*/
	return deleteLabel; 
}

simulated function OnChildMouseEvent(UIPanel control, int cmd)
{
	if( OnMouseIn != none )
		OnMouseIn(Index);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	if( bShouldPlayGenericUIAudioEvents )
	{
		switch( cmd )
		{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN :
			`SOUNDMGR.PlaySoundEvent("Play_Mouseover");
			//ShowHighlight();
			break;
		//case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT :
		//case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT :
		//	HideHighlight();
		//	break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:
			if(AcceptButton != none)
				AcceptButton.Click();
			break;
		}
	}

	if(OnMouseIn != none)
		OnMouseIn(Index);

	if( OnMouseEventDelegate != none )
		OnMouseEventDelegate(self, cmd);
}

simulated function ShowHighlight()
{
	super.OnReceiveFocus();
	MC.FunctionVoid("mouseIn");
	DeleteButton.OnLoseFocus();
	AcceptButton.OnLoseFocus();
	AcceptButton.SetText(GetAcceptLabel(Index == 0));
	DeleteButton.SetText(GetDeleteLabel());

	if (`ISCONTROLLERACTIVE)
	{
		AcceptButton.Show();
		DeleteButton.SetVisible(!(bIsSaving && ID == -1));
	}
}

simulated function HideHighlight()
{
	super.OnLoseFocus();
	MC.FunctionVoid("mouseOut");
	AcceptButton.OnLoseFocus();
	DeleteButton.OnLoseFocus();
	AcceptButton.SetText(GetAcceptLabel( Index == 0 ));
	DeleteButton.SetText(GetDeleteLabel());
	
	if(`ISCONTROLLERACTIVE)
	{
		AcceptButton.Hide();
		DeleteButton.SetVisible(!(bIsSaving && ID == -1));
	}
}

simulated function UpdateData(OnlineSaveGame save)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local XComOnlineEventMgr OnlineEventMgr;
	local string FriendlyName, mapPath, strDate, strName, strMission, strTime;
	local array<string> Descriptions;	
	local SaveGameHeader Header;
	local bool bIsNewSave, bHasValidImage;

	OnlineEventMgr = `ONLINEEVENTMGR;	
	if(save.Filename == "")
	{		
		bIsNewSave = true; 
		OnlineEventMgr.FillInHeaderForSave(Header, FriendlyName);
	}
	else
	{
		Header = save.SaveGames[0].SaveGameHeader;
	}

	MC.FunctionBool("SetAutosave", Header.bIsAutosave);

	bIsDifferentLanguage = (Header.Language != GetLanguage());

	//Parse the description with "\n" as a separator
	// [0] = date [1] = time [2] = save type / player desc [3] = game type [4] = game type detail
	Descriptions = SplitString(Header.Description, "\n");

	//For old save files that used "-"
	if( Descriptions.length < 2 )
		Descriptions = SplitString(Header.Description, "-");

	if(Descriptions.Length < 4)
	{
		strDate = Repl(Header.Time, "\n", " - ") @ Header.Description;
	
		//Handle "custom" description such as what the error reports use
		MC.FunctionBool("SetErrorReport", true);
	}
	else
	{
		strTime = FormatTime(Header.Time);
		strDate = strTime @ (Descriptions.Length >= 3 ? Descriptions[2] : "");

		strName = Descriptions.Length >= 4 ? Descriptions[3] : "";		// A description of the save produced by the game type.
		strMission = Descriptions.Length >= 5 ? Descriptions[4] : "";	// More detail from the game type
		strMission $= Descriptions.Length >= 6 ? " - " $ Descriptions[5] : "";	// More detail from the game type
	}
	
	mapPath = Header.MapImage;

	bHasValidImage = ImageCheck();

	if( mapPath == "" || !bHasValidImage )
	{
		// temp until we get the real screen shots to display
		mapPath = "img:///UILibrary_Common.Xcom_default";
	}
	else
	{
		mapPath = "img:///"$mapPath;
	}

	//Image
	myValue.Type = AS_String;
	myValue.s = mapPath;
	myArray.AddItem(myValue);

	//Date
	myValue.s = strDate;
	myArray.AddItem(myValue);

	//Name
	myValue.s = strName;
	myArray.AddItem(myValue);

	//Mission
	myValue.s = strMission;
	myArray.AddItem(myValue);

	//accept Label
	myValue.s = GetAcceptLabel(bIsNewSave);
	AcceptButton.SetText(myValue.s);
	myArray.AddItem(myValue);

	//delete label
	myValue.s = m_sDeleteLabel;
	myArray.AddItem(myValue);
	DeleteButton.SetText(myValue.s);

	//rename label
	myValue.s = bIsSaving? m_sRenameLabel: " ";
	myArray.AddItem(myValue);

	Invoke("updateData", myArray);
}

simulated function string FormatTime( string HeaderTime )
{
	local string FormattedTime;

	FormattedTime = HeaderTime; 
	if( GetLanguage() == "INT" )
	{
		FormattedTime = `ONLINEEVENTMGR.FormatTimeStampFor12HourClock(FormattedTime);
	}

	FormattedTime = Repl(FormattedTime, "\n", " - ");

	return FormattedTime;
}

simulated function UpdateSaveName(string saveName)
{
	MC.FunctionString("SetDate", DateTimeString @ saveName);
}

simulated function ClearImage()
{
	MC.FunctionVoid("ClearImage");
}


simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		AcceptButton.Click();
		return true;

	case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
	case class'UIUtilities_Input'.const.FXS_KEY_DELETE:
		if( DeleteButton.IsVisible() )
		{
			DeleteButton.Click();
			return true;
		}
		break;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnReceiveFocus()
{
	if (`ISCONTROLLERACTIVE == false)
	{
		super.OnReceiveFocus();
	}
	else
	{
		MC.FunctionVoid("mouseIn");

		AcceptButton.SetText(GetAcceptLabel(Index == 0));
		AcceptButton.OnReceiveFocus();
		AcceptButton.Show();

		if (!(Index == 0 && bIsSaving)) //BET 2016-04-20 - Don't show delete button on "new save" option
		{
			DeleteButton.SetText(GetDeleteLabel());
			DeleteButton.OnReceiveFocus();
			DeleteButton.SetVisible(!(bIsSaving && ID == -1));
		}
	}
}

simulated function OnLoseFocus()
{
	if (`ISCONTROLLERACTIVE == false)
	{
		super.OnLoseFocus();
	}
	else
	{
		MC.FunctionVoid("mouseOut");
		AcceptButton.Hide();
		DeleteButton.Hide();
		AcceptButton.OnLoseFocus();
		DeleteButton.OnLoseFocus();
	}
}

defaultproperties
{
	LibID = "SaveLoadListItem";
	ButtonBGLibID = "ButtonGroup"
	height = 135;
	bIsDifferentLanguage = false
	bCascadeFocus = false;
}