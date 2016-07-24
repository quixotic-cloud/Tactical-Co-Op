
class UIMissionIntro extends UIScreen;

var localized String m_strTransmissionTitle; 
var localized String m_strOperationTitle; 
var localized String m_strDatelineTitle; 
var localized String m_strLocationTitle; 
var localized String m_strMissionTitle; 

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);	
}

simulated function OnInit()
{
	local string Time;
	local XComGameState_BattleData BattleDataObject;
	
	super.OnInit();

	BattleDataObject = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	`assert(BattleDataObject != none);

	Time = class'X2StrategyGameRulesetDataStructures'.static.GetTimeString(BattleDataObject.LocalTime) @ class'X2StrategyGameRulesetDataStructures'.static.GetDateString(BattleDataObject.LocalTime);

	AS_SetDisplay( m_strTransmissionTitle, 
				   "XTA-87", 
				   m_strOperationTitle, 
				   BattleDataObject.m_strOpName != "" ? BattleDataObject.m_strOpName : "HIDDEN BLIGHT", 
				   m_strDatelineTitle, 
				   Time != "" ? Time : "141900Z JUN 2035", 
				   m_strLocationTitle, 
				   BattleDataObject.m_strDesc != "" ? BattleDataObject.m_strDesc : "ADVENT COLONY 1-7-2", 
				   BattleDataObject.m_strLocation != "" ? BattleDataObject.m_strLocation : "14 miles northeast of Baton Rouge, Louisiana, United States.", 
				   m_strMissionTitle, 
				   BattleDataObject.m_strDesc != "" ? BattleDataObject.m_strDesc : "ADVENT security forces have closed access to the city center. Intel suggests resistance sympathizers are being apprehended for possible termination. Assault primary checkpoint to subvert ADVENT forces. Expect alien reinforcements.", 
				   0);
}

simulated function AS_SetDisplay( String _transmissionLabel, 
								 String _transmissionValue, 
								 String _operationLabel, 
								 String _operationValue, 
								 String _datelineLabel, 
								 String _datelineValue, 
								 String _locationLabel, 
								 String _locationValue, 
								 String _locationValue2, 
								 String _missionLabel, 
								 String _missionValue, 
								 int _delay)
{
	Movie.ActionScriptVoid( MCPath $ ".SetDisplay" ); 
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	return super.OnUnrealCommand(cmd, arg);
}


simulated function OnCommand(string cmd, string arg)
{
	local X2Action_DropshipIntro showIntroAction;
	if (cmd == "OnComplete") 
	{
		foreach `XWORLDINFO.AllActors(class'X2Action_DropshipIntro', showIntroAction)
		{
			showIntroAction.StopUIMissionIntroSound();
		}		
	}
}

// ===========================================================================
//  DEFAULTS:
// ===========================================================================
defaultproperties
{
	Package = "/ package/gfxMissionIntro/MissionIntro";
	MCName = "theMissionIntro";
}
