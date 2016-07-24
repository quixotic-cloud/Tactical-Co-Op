//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XGNarrative extends Actor
	config(Narrative);


struct TItemUnlock
{
	var bool bItem;
	var bool bFacility;
	var bool bFoundryProject;
	var bool bGeneMod;
	var bool bMecArmor;
	var SoundCue sndFanfare;
	var EItemType eItemUnlocked;
	var EItemType eItemUnlocked2;
	var int iUnlocked;
	var int eUnlockImage;
	var string strTitle;
	var string strName;
	var string strDescription;
	var string strHelp;
	structdefaultproperties
	{
		eItemUnlocked = eItem_NONE;
	}
};

var array<int>                                  m_arrTipCounters;
var public array<int>                           m_arrNarrativeCounters; // How many times a narrative has been requested, used for determining first time, etc
var public array<int>                           m_arrNarrativeCountersAtStartOfMap;
var protectedwrite array<XComNarrativeMoment>   m_arrNarrativeMoments;
var const config array<string>                  NarrativeMoments;
var const config array<string>                  NewbieMoments;
var bool                                        m_bSilenceNewbieMoments;
var config bool                                 bDisableFirstTimeOnlyNarratives;
var config array<Name>							NarrativeScreensUniqueVO; // A list of UIOnly narrative moments which have unique events triggered when they are closed

simulated function InitNarrative(optional bool bSilenceNewbieMoments)
{
	m_arrNarrativeCounters.Add(NarrativeMoments.Length);
	m_arrNarrativeCountersAtStartOfMap.Add(NarrativeMoments.Length);
	m_arrTipCounters.Add( eTip_MAX );
	m_bSilenceNewbieMoments = bSilenceNewbieMoments;

	DoSilenceNewbieMoments();
}

simulated function int GetNextTip( ETipTypes eTip )
{
	local int iTipIndex;

	iTipIndex = m_arrTipCounters[eTip];

	// Increment to next tip
	m_arrTipCounters[eTip] += 1;

	switch( eTip )
	{
	case eTip_Tactical:
		if( m_arrTipCounters[eTip] >= class'XGLocalizedData'.default.GameplayTips_Tactical.Length )
			m_arrTipCounters[eTip] = 0;
		break;
	}

	return iTipIndex;
}

simulated function int FindMomentID(string Moment)
{
	return NarrativeMoments.Find(Moment);
}

simulated function StoreNarrativeCounters()
{
	m_arrNarrativeCountersAtStartOfMap = m_arrNarrativeCounters;
}

simulated function RestoreNarrativeCounters()
{
	m_arrNarrativeCounters = m_arrNarrativeCountersAtStartOfMap;
}

function AddNarrativeMoment(XComNarrativeMoment NarrativeMoment)
{
	NarrativeMoment.iID = m_arrNarrativeMoments.Length;
	m_arrNarrativeMoments.AddItem(NarrativeMoment);
	m_arrNarrativeCounters.Add(1);
	m_arrNarrativeCountersAtStartOfMap.Add(1);
}

event PreBeginPlay()
{
	local int i;
	super.PreBeginPlay();

	// Run through NarrativeMoments and cache references to the XComNarrativeMoments, and their IDs
	m_arrNarrativeMoments.Length = 0;
	m_arrNarrativeMoments.Add(NarrativeMoments.Length);
	for (i = 0; i < NarrativeMoments.Length; i++)
	{
		if (NarrativeMoments[i] != "")
		{
			m_arrNarrativeMoments[i] = XComNarrativeMoment(DynamicLoadObject(NarrativeMoments[i], class'XComNarrativeMoment'));
			if (m_arrNarrativeMoments[i] != none)
			{
				m_arrNarrativeMoments[i].iID = i;
			}
		}
		else 
		{
			`log("XGNarrative.PreBeginPlay: Could not find XComNarrativeMoment" @ NarrativeMoments[i]);
		}
	}

	DoSilenceNewbieMoments();
}

function DoSilenceNewbieMoments()
{
	local int i, iNewb;

	if (SilenceNewbieMoments() && m_arrNarrativeMoments.Length > 0)
	{
		for (i = 0; i < NewbieMoments.Length; ++i)
		{
			if (NewbieMoments[i] != "")
			{
				iNewb = FindMomentID(NewbieMoments[i]);
				if (iNewb != -1 && m_arrNarrativeCounters[iNewb] == 0)
					m_arrNarrativeCounters[iNewb] = 1;
			}
		}
	}
}

simulated function bool SilenceNewbieMoments()
{
	return m_bSilenceNewbieMoments;
}

defaultproperties
{
}
