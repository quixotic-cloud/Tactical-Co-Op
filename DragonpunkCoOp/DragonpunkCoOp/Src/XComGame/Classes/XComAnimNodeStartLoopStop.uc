//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAnimNodeStartLoopStop extends AnimNodeBlendList
	native(Animation);

enum EAnimStartLoopStop
{
 	eAnimStartLoopStop_Start,
	eAnimStartLoopStop_Loop,
	eAnimStartLoopStop_Stop,
	eAnimStartLoopStop_Idle,
};

cpptext 
{
	virtual void InitAnim( USkeletalMeshComponent* meshComp, UAnimNodeBlendBase* Parent );
	virtual	void TickAnim( FLOAT DeltaSeconds );
}

DefaultProperties
{
	Children(eAnimStartLoopStop_Start)=(Name="Start")
	Children(eAnimStartLoopStop_Loop)=(Name="Loop")
	Children(eAnimStartLoopStop_Stop)=(Name="Stop")
	Children(eAnimStartLoopStop_Idle)=(Name="Idle")

	bFixNumChildren=true
	bPlayActiveChild=true
	ActiveChildIndex = eAnimStartLoopStop_Idle;
}
