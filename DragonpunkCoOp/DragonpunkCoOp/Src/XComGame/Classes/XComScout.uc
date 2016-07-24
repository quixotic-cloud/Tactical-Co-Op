class XComScout extends Scout
	native(Level)
	transient;

cpptext
{
	virtual UBOOL CanDoMove( const TCHAR* Str, ANavigationPoint* Nav, INT Item = -1, UBOOL inbSeedPylon = FALSE );

#if WITH_EDITOR
	virtual UBOOL GenerateNavMesh( UBOOL bShowMapCheck, UBOOL bOnlyBuildSelected );
	virtual void FinishPathBuild();
#endif

	virtual void BuildCover(  UBOOL bFromDefinePaths = FALSE );
	virtual void DefinePaths( UBOOL bShowMapCheck);
};

defaultproperties
{

}
