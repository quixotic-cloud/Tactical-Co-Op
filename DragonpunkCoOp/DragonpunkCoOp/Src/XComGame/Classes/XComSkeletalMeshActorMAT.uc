class XComSkeletalMeshActorMAT extends SkeletalMeshActorMAT
	native(Core)
	placeable;

/** Use Head SkeletalMeshMAT to before loading character pool. Head must match loaded gender */
var(XComCharacters) string CharacterPoolSelection<DynamicList = "CharacterList">;

cpptext
{
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);
	virtual void GetDynamicListValues(const FString& ListName, TArray<FString>& Values);
}

defaultproperties
{

}