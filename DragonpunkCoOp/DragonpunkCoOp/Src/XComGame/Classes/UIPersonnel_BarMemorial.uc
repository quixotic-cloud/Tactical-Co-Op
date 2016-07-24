
// This class is functionally equivalent to UIPersonnel, it exists so we can override HQState, and m_strTitle in localization file.

class UIPersonnel_BarMemorial extends UIPersonnel;

var public localized string EmptyListMessage;

var UIText StatusMessage;

simulated function UpdateData()
{
	local int i;
	local XComGameState_Unit Unit;

	// Destroy old data
	m_arrSoldiers.Length = 0;
	m_arrScientists.Length = 0;
	m_arrEngineers.Length = 0;
	m_arrDeceased.Length = 0;

	for(i = 0; i < HQState.DeadCrew.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(HQState.DeadCrew[i].ObjectID));

		if(Unit.IsASoldier() && !Unit.IsAlive())
		{
			m_arrDeceased.AddItem(Unit.GetReference());
		}

	}

	if( StatusMessage == none )
	{
		StatusMessage = Spawn(class'UIText', self).InitText(, "");
		StatusMessage.SetWidth(m_kList.Width); 
		StatusMessage.SetPosition(m_kList.X, m_kList.Y);
	}

	if( m_arrDeceased.length == 0 )
	{
		StatusMessage.SetHTMLText( EmptyListMessage );
	}
	else
	{
		StatusMessage.SetHTMLText("");
	}
}

defaultproperties
{
	m_eListType = eUIPersonnel_Deceased;
	m_bRemoveWhenUnitSelected = true;
}