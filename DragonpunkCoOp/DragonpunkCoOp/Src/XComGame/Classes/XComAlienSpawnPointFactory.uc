//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAlienSpawnPointFactory extends ActorFactory
	collapsecategories
	hidecategories(Object)
	native(Level)
	dependson(XGGameData);

cpptext
{
	virtual AActor* CreateActor( const FVector* const Location, const FRotator* const Rotation, const class USeqAct_ActorFactory* const ActorFactoryData );
	virtual UBOOL CanCreateActor(FString& OutErrorMsg, UBOOL bFromAssetOnly = FALSE );
	virtual void AutoFillFields(class USelection* Selection);
	virtual FString GetMenuName();
}

var() EUnitType UnitType;

event OnCreateAlienSpawnPoint(XComSpawnPointNativeBase SpawnPoint)
{
	if (XComSpawnPoint_Alien(SpawnPoint) != none)
		XComSpawnPoint_Alien(SpawnPoint).UnitType = UnitType;
}

DefaultProperties
{
	MenuName="Add XComSpawnPoint_Alien actor"
	NewActorClass=class'XComGame.XComSpawnPoint_Alien'
	UnitType=UNIT_TYPE_Soldier;
}
