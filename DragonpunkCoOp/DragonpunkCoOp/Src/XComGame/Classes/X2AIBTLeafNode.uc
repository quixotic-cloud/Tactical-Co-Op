// Leaf node definitions for default conditions.
class X2AIBTLeafNode extends X2AIBTBehavior
	native(AI);
var XComGameState_Unit m_kUnitState;
var XGAIBehavior m_kBehavior;
var Name SplitNameParam; // For special conditions/actions with this as a parameter.
var array<Name> m_ParamList; // For special conditions/actions with this as a parameter.

// For debug only
var string DebugDetailText;
var string ParentName;
// end debug only.

native function SetParams(array<Name> ParamList);

protected function OnInit( int iObjectID, int iFrame )
{
	m_kUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(iObjectID));
	m_kBehavior = XGUnit(m_kUnitState.GetVisualizer()).m_kBehavior;
	if( iFrame != m_iLastInit )
	{
		// Only reset the debug text if this is a new frame.
		DebugDetailText = "";
	}
	super.OnInit(iObjectID, iFrame);
}

function LogDetailText(string NewText)
{
	DebugDetailText = DebugDetailText @ NewText;
}

function String GetLeafParentName()
{
	return ParentName;
}


function UpdateAdditionalInfo(out BTDetailedInfo BTInfo)
{
	BTInfo.DetailedText = DebugDetailText;
}

static function bool ParseNameForNameAbilitySplit(Name strName, string strKeyName, out Name AbilityName)
{
	local string strSearch;
	local int InStrResult;
	strSearch = string(strName);
	InStrResult = InStr(strSearch, strKeyName);
	if (InStrResult == 0) // Starts with SelectAbility
	{
		strSearch = Split(strSearch, strKeyName, true);
		AbilityName = Name(strSearch);
		return true;
	}
	return false;
}

static function ResolveAbilityNameWithUnit(out Name AbilityName, XGAIBehavior Behavior)
{
	local array<Name> AbilityList;
	local EquivalentAbilityNames AliasList;
	local Name Alias;
	local AvailableAction AvailAction;

	// Check if this is a valid ability name for this unit.
	if( !Behavior.FindOrGetAbilityList(AbilityName, AbilityList) )
	{
		// If not, search through the equivalent abilities list for a match.
		foreach class'X2AIBTBehaviorTree'.default.EquivalentAbilities(AliasList)
		{
			if( AliasList.KeyName == AbilityName )
			{
				foreach AliasList.EquivalentAbilityName(Alias)
				{
					if( AbilityList.Find(Alias) != INDEX_NONE )
					{
						// Found this in the unit's ability list.  Use this instead of the KeyName.
						AbilityName = Alias;
						// Return immediately if we found a valid, available ability.  Otherwise keep looking.
						AvailAction = Behavior.FindAbilityByName(Alias);
						if( AvailAction.AvailableCode == 'AA_Success')
						{
							return;
						}
					}
				}
			}
		}
	}
}

//------------------------------------------------------------------------------
// Functions used for debugging 
function string GetNodeDetails(const out array<BTDetailedInfo> TraversalData)
{
	local string strText;
	strText = super.GetNodeDetails(TraversalData);

	strText @= "\n Leaf Node- Type:";
	return strText;
}

//------------------------------------------------------------------------------------------------
static function ECharStatType FindStatByName(string strStatName)
{
	local int iType;
	local ECharStatType Stat;
	local string strType;
	for( iType = 0; iType < eStat_MAX; iType++ )
	{
		Stat = ECharStatType(iType);
		strType = string(Stat);
		if( Caps(strType) == Caps(strStatName) )
		{
			return Stat;
		}
	}
	return EStat_Invalid;
}

//------------------------------------------------------------------------------------------------
defaultproperties
{
}