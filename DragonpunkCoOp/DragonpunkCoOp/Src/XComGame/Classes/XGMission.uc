//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XGMission extends Actor 
	abstract;


var string                      m_strHelp;          // The help string that displays when this mission is selected in MC
var float                       fAnimationTimer;

var bool                m_bRetaliation;

var localized array<String> m_aFirstOpName;
var localized array<String> m_aSecondOpName;

var localized array<String> m_aFirstOpWord;
var localized array<String> m_aSecondOpWord;

var localized string m_strOpAvenger;
var localized string m_strOpAshes;
var localized string m_strOpRandom;
var localized string m_strOpRandomWord;

var localized string m_strChicken;	// I just want to use "Chicken" every once in a while

var localized string m_strTitle;     // The mission's name
var localized string m_strSituation; // A string describing the narrative of the mission
var localized string m_strObjective; // A string describing the objective of the mission
var string m_strOpenExclamationMark; // A string for the open exclamation mark for Spanish language "¡"
var string m_strTip;


static function string GenerateOpName(optional bool bTutorial = false)
{
	local XGParamTag kTag;	
	local int iSelection, iTop, iBottom;
	local bool bUseChicken;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	bUseChicken = Rand(500) == 0;

	// Choose which random op name generator to use
	if( Rand(2) == 0 )
	{
		kTag.StrValue0 = default.m_aFirstOpName[Rand(default.m_aFirstOpName.Length)];
		kTag.StrValue1 = default.m_aSecondOpName[Rand(default.m_aSecondOpName.Length)];

		if( bUseChicken )
		{
			kTag.StrValue1 = default.m_strChicken;
		}

		return `XEXPAND.ExpandString(default.m_strOpRandom);	
	}
	else
	{
		iSelection = Rand(default.m_aFirstOpWord.Length);
		kTag.StrValue0 = default.m_aFirstOpWord[iSelection];
		iSelection = Rand(default.m_aSecondOpWord.Length);
		kTag.StrValue1 = default.m_aSecondOpWord[iSelection];

		if( bUseChicken )
		{
			kTag.StrValue0 = default.m_strChicken;
		}

		// Make sure the first and second word of the operation name are not the same
		if(kTag.StrValue1 == kTag.StrValue0 )
		{
			iTop = default.m_aSecondOpWord.Length - (iSelection+1);
			iBottom = iSelection;
			if( iTop >= iBottom )
			{
				kTag.StrValue1 = default.m_aSecondOpWord[(iSelection+1) + Rand(iTop)];
			}
			else
			{
				kTag.StrValue1 = default.m_aSecondOpWord[Rand(iBottom)];
			}
		}
		
		return `XEXPAND.ExpandString(default.m_strOpRandomWord);
	}
	
}

defaultproperties
{

}
