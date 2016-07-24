
class UIPersonnel_SoldierListItem extends UIPersonnel_ListItem;

var UIImage PsiMarkup;

var bool m_bIsDisabled;

simulated function InitListItem(StateObjectReference initUnitRef)
{
	super.InitListItem(initUnitRef);

	PsiMarkup = Spawn(class'UIImage', self);
	PsiMarkup.InitImage('PsiPromote', class'UIUtilities_Image'.const.PsiMarkupIcon);
	PsiMarkup.Hide(); // starts off hidden until needed
}

 simulated function UpdateData()
{
	local XComGameState_Unit Unit;
	local string UnitLoc, status, statusTimeLabel, statusTimeValue, classIcon, rankIcon, flagIcon;	
	local int iRank;
	local X2SoldierClassTemplate SoldierClass;
	
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	iRank = Unit.GetRank();

	SoldierClass = Unit.GetSoldierClassTemplate();

	class'UIUtilities_Strategy'.static.GetPersonnelStatusSeparate(Unit, status, statusTimeLabel, statusTimeValue);
	if( statusTimeValue == "" )
		statusTimeValue = "---";

	flagIcon = Unit.GetCountryTemplate().FlagImage;
	rankIcon = class'UIUtilities_Image'.static.GetRankIcon(iRank, SoldierClass.DataName);
	classIcon = SoldierClass.IconImage;

	// if personnel is not staffed, don't show location
	if( class'UIUtilities_Strategy'.static.DisplayLocation(Unit) )
		UnitLoc = class'UIUtilities_Strategy'.static.GetPersonnelLocation(Unit);
	else
		UnitLoc = "";

	AS_UpdateDataSoldier(Caps(Unit.GetName(eNameType_Full)),
					Caps(Unit.GetName(eNameType_Nick)),
					Caps(`GET_RANK_ABBRV(Unit.GetRank(), SoldierClass.DataName)),
					rankIcon,
					Caps(SoldierClass != None ? SoldierClass.DisplayName : ""),
					classIcon,
					status,
					statusTimeValue $"\n" $ Class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(Class'UIUtilities_Text'.static.GetSizedText( statusTimeLabel, 12)),
					UnitLoc,
					flagIcon,
					false, //todo: is disabled 
					Unit.ShowPromoteIcon(),
					false); // psi soldiers can't rank up via missions
}

simulated function AS_UpdateDataSoldier(string UnitName,
								 string UnitNickname, 
								 string UnitRank, 
								 string UnitRankPath, 
								 string UnitClass, 
								 string UnitClassPath, 
								 string UnitStatus, 
								 string UnitStatusValue, 
								 string UnitLocation, 
								 string UnitCountryFlagPath,
								 bool bIsDisabled, 
								 bool bPromote, 
								 bool bPsiPromote)
{
	MC.BeginFunctionOp("UpdateData");
	MC.QueueString(UnitName);
	MC.QueueString(UnitNickname);
	MC.QueueString(UnitRank);
	MC.QueueString(UnitRankPath);
	MC.QueueString(UnitClass);
	MC.QueueString(UnitClassPath);
	MC.QueueString(UnitStatus);
	MC.QueueString(UnitStatusValue);
	MC.QueueString(UnitLocation);
	MC.QueueString(UnitCountryFlagPath);
	MC.QueueBoolean(bIsDisabled);
	MC.QueueBoolean(bPromote);
	MC.QueueBoolean(bPsiPromote);
	MC.EndOp();
}



defaultproperties
{
	LibID = "SoldierListItem";
}