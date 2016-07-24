class UITacticalHUD_ChallengeCountdown extends UIPanel; 

var UIX2PanelHeader	m_CountdownText;

 var localized string m_strTimeRemaining;
 var localized string m_strTimeExpired;

simulated function UITacticalHUD_ChallengeCountdown InitCountdown()
{
	local XComGameState_TimerData Timer;

	InitPanel();

	Timer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
	if ((Timer != none) && Timer.bIsChallengeModeTimer)
	{
		//Reset the timer until the user begins the mission.
		Timer.ResetTimer();

		m_CountdownText = Spawn(class'UIX2PanelHeader', self);
		m_CountdownText.InitPanelHeader('', m_strTimeRemaining, "");
		m_CountdownText.SetHeaderWidth(200);
		m_CountdownText.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_CENTER);
		m_CountdownText.SetPosition(-m_CountdownText.headerWidth * 0.5, 120);
	}

	Hide();

	return self;
}

simulated event Tick(float DeltaTime)
{
	local XComGameState_TimerData Timer;
	local int TotalSeconds, Minutes, Seconds;
	local string Separator;

	Timer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
	if (Timer != none && Timer.bIsChallengeModeTimer && Timer.TimeLimit >= 0)
	{
		Show();
		TotalSeconds = Timer.GetCurrentTime();
		if (TotalSeconds > 0)
		{
			Minutes = (TotalSeconds / 60);
			Seconds = TotalSeconds % 60;
			Separator = (Seconds < 10) ? ":0" : ":";
			m_CountdownText.SetText(m_strTimeRemaining, Minutes $ Separator $ Seconds);
		}
		else
		{
			m_CountdownText.SetText(m_strTimeExpired, "");
		}
	}
	super.Tick(DeltaTime);
}

defaultproperties
{
	
}