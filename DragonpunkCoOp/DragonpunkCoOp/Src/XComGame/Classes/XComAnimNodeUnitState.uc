//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAnimNodeUnitState extends AnimNodeBlendList
	native(Animation);

enum EAnimUnitState
{
	eAnimUnitState_Normal,
	eAnimUnitState_HighAlert,
	eAnimUnitState_LookingAt,
	eAnimUnitState_Panicking,
	eAnimUnitState_HighCoverFront,
	eAnimUnitState_HighCoverBack,
	eAnimUnitState_HighCoverLeft,
	eAnimUnitState_HighCoverRight,
	eAnimUnitState_LowCoverFront,
	eAnimUnitState_LowCoverBack,
	eAnimUnitState_LowCoverLeft,
	eAnimUnitState_LowCoverRight,
};

cpptext
{
	virtual	void TickAnim( FLOAT DeltaSeconds );
}

defaultproperties
{
	Children(eAnimUnitState_Normal)=(Name="Normal")
	Children(eAnimUnitState_HighAlert)=(Name="HighAlert")
	Children(eAnimUnitState_LookingAt)=(Name="LookingAt")
	Children(eAnimUnitState_Panicking)=(Name="Panicking")
	Children(eAnimUnitState_HighCoverFront)=(Name="HighCoverFront")
	Children(eAnimUnitState_HighCoverBack)=(Name="HighCoverBack")
	Children(eAnimUnitState_HighCoverLeft)=(Name="HighCoverLeft")
	Children(eAnimUnitState_HighCoverRight)=(Name="HighCoverRight")
	Children(eAnimUnitState_LowCoverFront)=(Name="LowCoverFront")
	Children(eAnimUnitState_LowCoverBack)=(Name="LowCoverBack")
	Children(eAnimUnitState_LowCoverLeft)=(Name="LowCoverLeft")
	Children(eAnimUnitState_LowCoverRight)=(Name="LowCoverRight")

	bFixNumChildren=true
	bPlayActiveChild=true
}
