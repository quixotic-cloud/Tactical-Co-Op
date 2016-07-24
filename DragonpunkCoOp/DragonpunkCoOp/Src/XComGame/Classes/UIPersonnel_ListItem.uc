
class UIPersonnel_ListItem extends UIButton;

var UIPanel BG;

var StateObjectReference UnitRef;

simulated function InitListItem(StateObjectReference initUnitRef)
{
	UnitRef = initUnitRef;

	InitPanel(); // must do this before adding children or setting data

	/*BG = Spawn(class'UIPanel', self);
	BG.InitPanel('BGButton');
	BG.ProcessMouseEvents(onMouseEventDelegate); // processes all our Mouse Events
	*/
	UpdateData();
}

simulated function UpdateData()
{
	local XComGameState_Unit Unit;
	local string UnitLoc, UnitTypeImage; 
	local EUIPersonnelType UnitPersonnelType; 
	
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	// if personnel is not staffed, don't show location
	if(class'UIUtilities_Strategy'.static.DisplayLocation(Unit))
		UnitLoc = class'UIUtilities_Strategy'.static.GetPersonnelLocation(Unit);
	else
		UnitLoc = "";

	if( Unit.IsAnEngineer() )
	{
		UnitPersonnelType = eUIPersonnel_Engineers;
		UnitTypeImage = class'UIUtilities_Image'.const.EventQueue_Engineer;
	}
	else if( Unit.IsAScientist() )
	{
		UnitPersonnelType = eUIPersonnel_Scientists;
		UnitTypeImage = class'UIUtilities_Image'.const.EventQueue_Science;
	}
	else
	{
		UnitPersonnelType = -1;
		UnitTypeImage = "";
	}
	
	AS_UpdateData(Caps(Unit.GetName(eNameType_Full)),
			   "0", //string(Unit.GetSkillLevel()),
			   class'UIUtilities_Strategy'.static.GetPersonnelStatus(Unit),
			   "",
			   UnitLoc, 
			   Unit.GetCountryTemplate().FlagImage,
			   false,
			   UnitPersonnelType, 
			   UnitTypeImage);
}

simulated function AS_UpdateData(string UnitName, 
								 string UnitSkill, 
								 string UnitStatus, 
								 string UnitStatusValue, 
								 string UnitLocation, 
								 string UnitCountryFlagPath, 
								 bool bIsDisabled,
								 EUIPersonnelType UnitType, 
								 string UnitTypeIcon )
{
	MC.BeginFunctionOp("UpdateData");
	MC.QueueString(UnitName);
	MC.QueueString(UnitSkill);
	MC.QueueString(UnitStatus);
	MC.QueueString(UnitStatusValue);
	MC.QueueString(UnitLocation);
	MC.QueueString(UnitCountryFlagPath);
	MC.QueueBoolean(bIsDisabled);
	MC.QueueNumber(int(UnitType));
	MC.QueueString(UnitTypeIcon);
	MC.EndOp();
}

simulated function AnimateIn(optional float delay = -1.0)
{
	// this needs to be percent of total time in sec 
	if( delay == -1.0)
		delay = ParentPanel.GetChildIndex(self) * class'UIUtilities'.const.INTRO_ANIMATION_DELAY_PER_INDEX; 

	AddTweenBetween( "_alpha", 0, alpha, class'UIUtilities'.const.INTRO_ANIMATION_TIME, delay );
	AddTweenBetween( "_y", Y+10, Y, class'UIUtilities'.const.INTRO_ANIMATION_TIME*2, delay, "easeoutquad" );
}

// all mouse events get processed by bg
simulated function UIPanel ProcessMouseEvents(optional delegate<onMouseEventDelegate> mouseEventDelegate)
{
	onMouseEventDelegate = mouseEventDelegate;
	return self;
}

defaultproperties
{
	LibID = "PersonnelListItem";

	width = 1114;
	height = 55;
	bProcessesMouseEvents = true;
	bIsNavigable = true;
}