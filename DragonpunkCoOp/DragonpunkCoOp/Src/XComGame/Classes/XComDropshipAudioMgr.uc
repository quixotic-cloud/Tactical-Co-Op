class XComDropshipAudioMgr extends Object
		config(GameData);

struct TAudio
{
	var int EnumID;
	var int SpecialMissionID;
	var string Narrative;
};

var config array<TAudio> CountryAudio;
var config array<TAudio> MissionAudio;

//UI breifing narratives
var bool m_bHasCountryAudio;
var XComNarrativeMoment CountryMoment;
var XComNarrativeMoment MissionMoment;
var XComNarrativeMoment IntroMoment;

function bool IsValidMissionType(EMissionType MissionType)
{
	local int i;

	for (i = 0; i < MissionAudio.Length; ++i)
	{
		if (MissionType == MissionAudio[i].EnumID && MissionType != eMission_AlienBase)
		{
			return true;
		}
	}
	return false;
}

//function BeginDropshipNarrativeMoments(XGMission Mission, EMissionType MissionType, ECountry Country, optional bool bRecordPlayingOnly=false)
//{
//    if (IsValidMissionType(MissionType))
//	{			
//		m_bHasCountryAudio = true;
//		GetCountryAudio(Country, MissionType, bRecordPlayingOnly);
//	}
//
//	GetMissionAudio(Mission, bRecordPlayingOnly);
//}
//
//private function GetCountryAudio(ECountry Country, EMissionType MissionType, bool bRecordPlayingOnly)
//{
//	local int i;
//	local string NarrativePath;
//	
//	for (i = 0; i < CountryAudio.Length; ++i)
//	{
//		if (Country == CountryAudio[i].EnumID && CountryAudio[i].SpecialMissionID == 0)
//		{        
//			NarrativePath = CountryAudio[i].Narrative;
//			break; 
//		}
//	}
//
//	if (!bRecordPlayingOnly)
//	{
//		`log("Playing country audio narrative moment",, 'XCom_Content');	
//		CountryMoment = XComNarrativeMoment(DynamicLoadObject(NarrativePath, class'XComNarrativeMoment'));	
//		`HQPRES.UIPreloadNarrative(CountryMoment);	
//	}
//	else
//	{
//		//  terrible hack, but necessary as the narrative counter bump can never be saved once we're in the dropship load screen
//		i = `HQPRES.m_kNarrative.FindMomentID(NarrativePath);
//		if (i > -1)
//			`HQPRES.m_kNarrative.m_arrNarrativeCounters[i] += 1;
//	}
//}

private function GetMissionAudio(XGMission mission, bool bRecordPlayingOnly)
{

}

simulated function PreloadFirstMissionNarrative()
{
	//IntroMoment = XComNarrativeMoment(DynamicLoadObject("NarrativeMoment.TUT_XCOMDeployed_Dropship", class'XComNarrativeMoment'));
	//`HQPRES.UIPreloadNarrative(IntroMoment);
}

defaultproperties
{
	m_bHasCountryAudio = false
}