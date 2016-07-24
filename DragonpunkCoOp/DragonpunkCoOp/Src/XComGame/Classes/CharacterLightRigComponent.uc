class CharacterLightRigComponent extends ActorComponent
	dependson(Pawn)
	native;

var native SHVectorRGB TargetSH;
var native SHVectorRGB CurrentSH;

var float LastUpdateTime;
var float fTimeBetweenUpdates;

var float PrimaryLightTargetBrightness;
var float SecondaryLightBrightnessFactor;

var float LightRadius;
var float LightDistance;

var float PrimaryLightAngle;
var float SecondaryLightAngle;

var float PreviousAlpha;

var BoxSphereBounds OwnerBounds;

var SpotLightComponent PrimaryLight;
var SpotLightComponent SecondaryLight;

cpptext
{
	virtual void Tick(FLOAT DeltaTime);

	void UpdateOwnerBounds(AGamePawn* pOwner);
	void AddLightToEnvironment(FSHVectorRGB& OutEnvironment, ULightComponent* pLightComponent, const FBoxSphereBounds& OwnerBounds, UBOOL bDoLineCheck = FALSE);
	UBOOL FindAndAddCubeMap(FSHVectorRGB& OutEnvironment, const FBoxSphereBounds& OwnerBounds);

	void InterpolateLightEnvironment(FLOAT DeltaTime, FLOAT TimeBetweenUpdates);

	void CreateLights(AGamePawn* pOwner);
	void CreateLightFromEnvironment(USpotLightComponent* pLight, FSHVectorRGB& Environment, FLOAT TargetBrightness);
	void CreateLightOppositePrimary(USpotLightComponent* pLight, USpotLightComponent* pPrimaryLight, FSHVectorRGB& Environment, FLOAT BrightnessMod);
}

event bool IsStrategyGame()
{
	return `STRATEGYRULES != none;
}

defaultproperties
{
	LastUpdateTime = 0;
	fTimeBetweenUpdates = 0.8;

	PrimaryLightTargetBrightness = 2;
	SecondaryLightBrightnessFactor = .5;

	LightRadius = 165;
	LightDistance = 128;

	PrimaryLightAngle = 45;
	SecondaryLightAngle = 30;

	PreviousAlpha = 1.0;
}