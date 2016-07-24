class XComAlienSpawnVolume extends TriggerVolume
	placeable;

var bool bSwappingSomeone;
var() Volume Volume;
//var() class<XGCharacter> UnitClass;

simulated event Touch(Actor Other, PrimitiveComponent OtherComp,Vector HitLocation, Vector HitNormal)
{
	/*  jbouscher - REFACTORING CHARACTERS
	local XComUnitPawn XPawn;
	local XGUnit NewUnit;
	local XGCharacter kChar;
	local XGSquad kSquad;
	local vector Locale;
	
	Locale = Volume.Location;
	Locale.X = Locale.X + Rand(384);
	Locale.Y = Locale.Y + Rand(384);

	super.Touch(Other, OtherComp, HitLocation, HitNormal);

	if (bSwappingSomeone)
		return;

	XPawn = XComUnitPawn(Other);

	if (XPawn != none) 
	{
		bSwappingSomeone = true;
		
		kSquad = XGBattle_SP(`BATTLE).GetAIPlayer().m_kSquad;
		kChar = Spawn(UnitClass);
		NewUnit = XGBattle_SP(`BATTLE).GetAIPlayer().SpawnUnit(class'XGUnit' , XGBattle_SP(`BATTLE).GetAIPlayer().m_kPlayerController, Locale, rot(0,0,0), kChar, kSquad);
		`LOADOUTMGR.ApplyInventory( NewUnit );

		bSwappingSomeone = false;
	}
	*/
}

defaultproperties
{
	bSwappingSomeone = false;
	//UnitClass=class'XGCharacter_Chryssalid'
}
