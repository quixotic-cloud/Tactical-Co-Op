class XComAnimNodeUnitStairState extends AnimNodeBlendList
	native(Animation);

enum EAnimUnitStairState
{
	eAnimUnitStairState_OffStairs,
	eAnimUnitStairState_UpStairs,
	eAnimUnitStairState_DownStairs,
};

cpptext
{
	virtual void InitAnim(USkeletalMeshComponent* meshComp, UAnimNodeBlendBase* Parent);
	virtual void TickAnim(FLOAT DeltaSeconds);	
}

DefaultProperties
{
	Children(eAnimUnitStairState_OffStairs)=(Name="Off Stairs")
	Children(eAnimUnitStairState_UpStairs)=(Name="Up Stairs")
	Children(eAnimUnitStairState_DownStairs)=(Name="Down Stairs")
}
