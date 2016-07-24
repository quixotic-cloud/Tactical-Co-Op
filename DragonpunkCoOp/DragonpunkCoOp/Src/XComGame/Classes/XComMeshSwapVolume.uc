class XComMeshSwapVolume extends TriggerVolume
	placeable;

var bool bSwappingSomeone;

//var() class<XGCharacter> UnitClass;

simulated event Touch(Actor Other, PrimitiveComponent OtherComp,Vector HitLocation, Vector HitNormal)
{
	/*  jbouscher - REFACTORING CHARACTERS
	local XComUnitPawn XPawn;
	local XGUnit NewUnit;
	local XGCharacter kChar;
	local XGSquad kSquad;

	super.Touch(Other, OtherComp, HitLocation, HitNormal);

	if (bSwappingSomeone)
		return;

	XPawn = XComUnitPawn(Other);

	if (XPawn != none) 
	{
		bSwappingSomeone = true;
		
		kSquad = XGUnit(XPawn.GetGameUnit()).GetSquad();
		kSquad.RemoveUnit(XGUnit(XPawn.GetGameUnit()));
		XPawn.Destroy();
		kChar = Spawn(UnitClass);
		NewUnit = XGBattle_SP(`BATTLE).GetHumanPlayer().SpawnUnit(class'XGUnit' , XGBattle_SP(`BATTLE).GetHumanPlayer().m_kPlayerCOntroller, Other.Location, rot(0,0,0), kChar, kSquad);
		`LOADOUTMGR.EquipUnit( NewUnit );

		bSwappingSomeone = false;
	}
	*/
}

defaultproperties
{
	bSwappingSomeone = false;
	//UnitClass=class'XGCharacter_Chryssalid'
}