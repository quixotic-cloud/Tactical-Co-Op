//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XGBattle_SPStreetSwarm extends XGBattle_SP;

//#################################################################################
//							STATE CODE
//#################################################################################

// --------------------------------------------------------------
// --------------------------------------------------------------
function bool IsVictory(bool bIgnoreBusyCheck)
{
	// VICTORY = AT LEAST ONE UNIT IN THE EXFILTRATION ZONE
	// AND ALL OTHER UNITS DEAD OR IN EXFILTRATION ZONE

	local int       i;
	local XGUnit    kUnit;
	local XGSquad   kSquad;
	local bool      bUnitEscaped;

    kSquad = GetHumanPlayer().GetSquad();
	for( i = 0; i < kSquad.GetNumMembers(); i++ )
	{
        kUnit = kSquad.GetMemberAt( i );

		// IF( This unit suceeded in reaching an exfiltration zone )
		if( kUnit.DEPRECATED_m_bOffTheBattlefield )
			bUnitEscaped = true;
		// ELSE IF( This unit is incapacitated or dead )
		else if( kUnit.IsDead() || kUnit.IsCriticallyWounded() )
			continue;
		// ELSE ( Someone is still alive on the battlefield )
		else
			return false;
	}

	return bUnitEscaped;
}

// --------------------------------------------------------------
// --------------------------------------------------------------
function bool IsDefeat()
{
	local int       i;
	local XGUnit    kUnit;
	local XGSquad   kSquad;

	// DEFEAT = ALL SOLDIERS DEAD

    kSquad = GetHumanPlayer().GetSquad();
	for( i = 0; i < kSquad.GetNumMembers(); i++ )
	{
        kUnit = kSquad.GetMemberAt( i );

		if( !kUnit.IsDead() && !kUnit.IsCriticallyWounded())
			return false;
	}

	return true;
}

DefaultProperties
{

}
