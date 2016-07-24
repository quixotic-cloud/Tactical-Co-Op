class X2Effect_GrantActionPointsWithRecord extends X2Effect_GrantActionPoints;

struct RecordData
{
	var name UnitValueName;
	var EUnitValueCleanup CleanupType;
};

var array<RecordData> RecordUnitValueWithGrant;

function AddRecordData(name UnitValueName, EUnitValueCleanup CleanupType)
{
	local RecordData NewRecordData;

	NewRecordData.UnitValueName = UnitValueName;
	NewRecordData.CleanupType = CleanupType;

	RecordUnitValueWithGrant.AddItem(NewRecordData);
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;
	local int i;
	local UnitValue CurrUnitValue;

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
		for (i = 0; i < RecordUnitValueWithGrant.Length; ++i)
		{
			UnitState.GetUnitValue(RecordUnitValueWithGrant[i].UnitValueName, CurrUnitValue);
			UnitState.SetUnitFloatValue(RecordUnitValueWithGrant[i].UnitValueName, CurrUnitValue.fValue + NumActionPoints, RecordUnitValueWithGrant[i].CleanupType);
		}
	}
}