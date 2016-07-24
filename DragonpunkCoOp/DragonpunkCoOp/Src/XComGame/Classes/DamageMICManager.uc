class DamageMICManager extends Object
	native(Core);

struct native DamageMICKey
{
   /** Material the MIC is parented to */
   var MaterialInterface    MaterialParent;
   /** Material the parameters came from */
   var MaterialInterface    SrcMaterial;
   /** Damage type since that will set additional parameters */
   var name					DamageTypeName;

	structcpptext
	{
	   FDamageMICKey() : MaterialParent(NULL), SrcMaterial(NULL), DamageTypeName(NAME_None) {}
		FDamageMICKey( UMaterialInterface *InMaterialParent,  UMaterialInterface* InSrcMaterial, const FName& InDamageTypeName ) : MaterialParent(InMaterialParent), 
																													    	SrcMaterial(InSrcMaterial), 
																															DamageTypeName(InDamageTypeName) {}

		friend FArchive &operator<<(FArchive &Ar, FDamageMICKey &T);

		UBOOL operator==( const FDamageMICKey& Other ) const;
		friend inline DWORD GetTypeHash(const FDamageMICKey &T)
		{
			return PointerHash(T.SrcMaterial, PointerHash(T.DamageTypeName.GetEntry(T.DamageTypeName.GetIndex()), PointerHash(T.MaterialParent)));
		}
	}
};


// Map a Material/Damage pair to an MIC
//var transient native map{FDamageMICKey, class UMaterialInstance*} DamageMatInstMap;
var transient native Map_Mirror	DamageMatInstMap{TMap<FDamageMICKey, class UMaterialInstanceConstant*>};


cpptext
{
	UBOOL AcquireMaterialInstance( UMaterialInterface* MaterialParent, UMaterialInterface* DamageTexture, const FName& DamageType, UMaterialInstanceConstant*& ResultMIC );

	/**
	 * Callback used to allow object register its direct object references that are not already covered by
	 * the token stream.
	 *
	 * @param ObjectArray   array to add referenced objects to via AddReferencedObject
	 */
	void AddReferencedObjects( TArray<UObject*>& ObjectArray );

	/**
	 * Static constructor called once per class during static initialization via IMPLEMENT_CLASS
	 * macro. Used to e.g. emit object reference tokens for realtime garbage collection or expose
	 * properties for native- only classes.
	 */
	void StaticConstructor();

	void Serialize( FArchive& Ar );

	virtual void PostLoad();

}
