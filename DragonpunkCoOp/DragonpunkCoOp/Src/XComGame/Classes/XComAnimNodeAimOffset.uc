class XComAnimNodeAimOffset extends AnimNodeAimOffset
	native(Animation);

var() bool bDummyThisIsAnXComAnimNodeAimOffset;

cpptext 
{
	virtual	void TickAnim( FLOAT DeltaSeconds );
	virtual void InitAnim( USkeletalMeshComponent* meshComp, UAnimNodeBlendBase* Parent );
}

DefaultProperties
{
	bDummyThisIsAnXComAnimNodeAimOffset = true
}
