class XComVolumeDuckingMgr extends Object;

var private WatchVariableMgr WatchVarMgr;
var private int CommLinkWatchVar;
var private bool m_bVolumeDucked;
var private float m_fVolumeDuckBlendTimeFadeIn;
var private float m_fVolumeDuckBlendTimeFadeOut;
var private float m_fVolumeDuckBlendTimeToGo;
var private float m_fCurrentVolumeSoundFX;
var private float m_fCurrentVolumeMusic;
var private float m_fVolumeDuckPercent;

// FUTURE TODO:  Merge this classes functionality into the narrative manager

function Init()
{
	WatchVarMgr = `BATTLE.WorldInfo.MyWatchVariableMgr;

	CommLinkWatchVar = WatchVarMgr.RegisterWatchVariable(`BATTLE.PRES().GetUIComm(), 'bIsVisible', self, OnDialog);

	m_fCurrentVolumeMusic = `BATTLE.GetProfileSettings().Data.m_iMusicVolume/100.0f;
	m_fCurrentVolumeSoundFX = `BATTLE.GetProfileSettings().Data.m_iFXVolume/100.0f;
}

function OnDialog()
{
	if (`BATTLE.PRES().GetUIComm().bIsVisible && !m_bVolumeDucked &&
		!`BATTLE.PRES().m_kNarrativeUIMgr.m_arrConversations[0].NarrativeMoment.bUseCinematicSoundClass)  // Don't duck sound if we're currently playing a narrative with cinematic sound
	{
		m_bVolumeDucked = true;
		m_fVolumeDuckBlendTimeToGo = m_fVolumeDuckBlendTimeFadeOut;
	}
	else if (!`BATTLE.PRES().GetUIComm().bIsVisible && m_bVolumeDucked)
	{
		m_bVolumeDucked = false;
		m_fVolumeDuckBlendTimeToGo = m_fVolumeDuckBlendTimeFadeIn;
	}
}

function Tick(float DeltaTime)
{
	local float DurationPct, BlendTime;

	if (m_fVolumeDuckBlendTimeToGo > 0)
	{
		m_fVolumeDuckBlendTimeToGo -= DeltaTime;

		BlendTime = (m_bVolumeDucked) ? m_fVolumeDuckBlendTimeFadeOut : m_fVolumeDuckBlendTimeFadeIn;

		DurationPct	= (BlendTime - m_fVolumeDuckBlendTimeToGo) / BlendTime;

		if (m_bVolumeDucked)
		{
			m_fCurrentVolumeSoundFX = Lerp(m_fCurrentVolumeSoundFX, (`BATTLE.GetProfileSettings().Data.m_iFXVolume*m_fVolumeDuckPercent)/100.0f, DurationPct);
			m_fCurrentVolumeMusic = Lerp(m_fCurrentVolumeMusic, (`BATTLE.GetProfileSettings().Data.m_iMusicVolume*m_fVolumeDuckPercent)/100.0f, DurationPct);
		}
		else
		{
			m_fCurrentVolumeSoundFX = Lerp(m_fCurrentVolumeSoundFX, `BATTLE.GetProfileSettings().Data.m_iFXVolume/100.0f, DurationPct);
			m_fCurrentVolumeMusic = Lerp(m_fCurrentVolumeMusic, `BATTLE.GetProfileSettings().Data.m_iMusicVolume/100.0f, DurationPct);
		}
		`BATTLE.GetALocalPlayerController().SetAudioGroupVolume('SoundFX', m_fCurrentVolumeSoundFX);
		`BATTLE.GetALocalPlayerController().SetAudioGroupVolume('Music', m_fCurrentVolumeMusic);
	}
}

function Destroy()
{
	WatchVarMgr.UnRegisterWatchVariable(CommLinkWatchVar);
	`BATTLE.GetALocalPlayerController().SetAudioGroupVolume('SoundFX', `BATTLE.GetProfileSettings().Data.m_iFXVolume/100.0f);
	`BATTLE.GetALocalPlayerController().SetAudioGroupVolume('Music', `BATTLE.GetProfileSettings().Data.m_iMusicVolume/100.0f);
}

defaultproperties
{
	m_fVolumeDuckBlendTimeFadeIn=3.0
	m_fVolumeDuckBlendTimeFadeOut=0.2

	m_fVolumeDuckPercent=0.65
}