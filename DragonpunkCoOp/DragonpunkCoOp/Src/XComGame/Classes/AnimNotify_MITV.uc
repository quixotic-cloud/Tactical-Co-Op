class AnimNotify_MITV extends AnimNotify_WithPlayLimits
	native(Animation);

var() const MaterialInstanceTimeVarying     MITV;
var() const float                           DurationOverride;

/** If set will swap all materials on the mesh to the given MITV (instead of just triggering an existing MITV) */
var() const bool							bOverrideAllMaterials;
/** If set will reset all materials on the mesh to their defaults after DurationOverride seconds */
var() const bool							bResetMaterialsOnCompletion;
/** If set will apply the MITV to the pawn's weapon mesh instead of the character mesh */
var() const bool							bApplyToWeapon;
/** If set applies the material to all meshes attached to the character */
var() const bool							bApplyFullUnitMaterial;
/** instead of overriding all MIC materials or all materials, override just one */
var() const bool							bOverrideSingleMaterial;
var() const int								MaterialOverrideIndex;

/**  placeholder for MaterialReset **/
var transient AnimNodeSequence ResetNodeSeq;
var transient name ResetPawnName;

/**  checks PlayLimtes to see if the MITV should be run against this object **/
event bool ShouldRun(XComUnitPawnNativeBase Unit)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Unit.ObjectID));
	
	return Unit.PassesParticleEffectUnitTypeTest(self, UnitState);
}


/** will reset the material instances back to null and regnerate the material set for the mesh **/
function native ResetMaterial();

function DoResetMaterial()
{
	ResetMaterial();
}

function native ApplyMITV( XComUnitPawnNativeBase XComPawn );

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment();
	virtual FColor GetEditorColor() { return FColor(70,130,180); }

	void HandleShared( AXComUnitPawnNativeBase* XComPawn, USkeletalMeshComponent *SkelComponent );
	void ResetShared( USkeletalMeshComponent *SkelComponent );
}

defaultproperties
{
	DurationOverride = 0.0f
}
