//-----------------------------------------------------------
//
//-----------------------------------------------------------
class SeqVar_XComUnitPawn extends SeqVar_Object
	native(Unit);
	
cpptext
{
	UObject** GetObjectRef( INT Idx );

	virtual FString GetValueStr()
	{
		if (bAllUnits && !bActiveUnit)
		{
			return FString(TEXT("All Units"));
		}
		else if (!bAllUnits && bActiveUnit)
		{
			return FString(TEXT("Active Unit"));
		}
		else if (bAllUnits && bActiveUnit)
		{
			return FString(TEXT("ERROR: Invalid selection"));
		}
		else
		{
			return FString::Printf(TEXT("Unit %d"),UnitIdx);
		}
	}

	virtual UBOOL SupportsProperty(UProperty *Property)
	{
		return FALSE;
	}
};

/** Local list of units in the game */
var transient array<Object> Units;

/** Return the active unit's reference? */
var() bool bActiveUnit;

/** Return all unit references? */
var() bool bAllUnits;

/** Individual unit selection for multiplayer scripting */
var() int UnitIdx;


event XComUnitPawnNativeBase GetActiveUnitPawn()
{
	local XComTacticalController kTacticalController;

	foreach GetWorldInfo().AllControllers(class'XComTacticalController', kTacticalController)
	{
		if (kTacticalController.GetActiveUnitPawn() != none)
		{
			return kTacticalController.GetActiveUnitPawn();
		}
		else
		{
			return none;
		}
	}
	return none;
}

defaultproperties
{
	ObjName="XComUnit"
	ObjCategory="XCom Object"
	bActiveUnit=false
	bAllUnits=false
	SupportedClasses=(class'XComUnitPawn')
}
