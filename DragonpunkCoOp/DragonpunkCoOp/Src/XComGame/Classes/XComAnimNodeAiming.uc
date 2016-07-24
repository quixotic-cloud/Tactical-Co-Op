class XComAnimNodeAiming extends AnimNodeBlendList
	native(Animation);


enum EAnimAim
{
 	eAnimAim_NotTurning,
 	eAnimAim_Turning,
};

native function SetStaticActiveChild(int iChild, float fBlendTime);

cpptext
{	
	virtual	void TickAnim( FLOAT DeltaSeconds );
	virtual void InitAnim( USkeletalMeshComponent* meshComp, UAnimNodeBlendBase* Parent );
}

defaultproperties
{
	Children(eAnimAim_NotTurning)=(Name="Aiming and Not Turning")
	Children(eAnimAim_Turning)=(Name="Aiming and Turning")

	bFixNumChildren=true
	bPlayActiveChild=true
}