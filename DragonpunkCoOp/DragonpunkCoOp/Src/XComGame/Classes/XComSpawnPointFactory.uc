//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComSpawnPointFactory extends ActorFactory
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

event OnCreateSpawnPoint(XComSpawnPointNativeBase SpawnPoint)
{
	if (XComSpawnPoint(SpawnPoint) != none)
		XComSpawnPoint(SpawnPoint).UnitType = UnitType;
}

DefaultProperties
{
	MenuName="Add XComSpawnPoint actor"
	NewActorClass=class'XComGame.XComSpawnPoint'
	UnitType=UNIT_TYPE_Soldier;
}
