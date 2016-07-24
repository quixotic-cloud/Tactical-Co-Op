//-----------------------------------------------------------
// MHU - Note, derives from XComAnimNodeBlendList in order to
//       to properly reset Mirroring flag.
//-----------------------------------------------------------
class XComAnimNodeBlendByMovementType extends XComAnimNodeBlendList
	native(Animation);

enum EMoveType
{
 	eMoveType_Running,
	eMoveType_Stationary,
	eMoveType_Dead,
	eMoveType_Turn,
	eMoveType_Action,
	eMoveType_StartRunning,
	eMoveType_Anim // For playing a just a simple animation sequence
};

cpptext
{
	virtual	void TickAnim( FLOAT DeltaSeconds );
}

// If animation blending becomes an issue we can use a ring buffer for the seqNode
native function SetAnimByEnum(ESingleAnim eAnim, optional ERootBoneAxis AxisX = RBA_Default,
											  optional ERootBoneAxis AxisY = RBA_Default,
											  optional ERootBoneAxis AxisZ = RBA_Default);

simulated function SetAnimReverse(ESingleAnim eAnim, optional ERootBoneAxis AxisX = RBA_Default,
													 optional ERootBoneAxis AxisY = RBA_Default,
													 optional ERootBoneAxis AxisZ = RBA_Default)
{
	SetAnimByName(XComGameReplicationInfo(class'Engine'.static.GetCurrentWorldInfo().GRI).AnimMapping[eAnim], AxisX, AxisY, AxisZ, -1.0f);
}

//This function has a specialized use: switching out of a mirrored cover animation. To do this, we cut immediately to the last few frames of the 
//get into cover animations (which are unmirrored) and then blend into the no cover state from there
native function SetAnimByEnumEnd(ESingleAnim eAnim, optional ERootBoneAxis AxisX = RBA_Default,
												 optional ERootBoneAxis AxisY = RBA_Default,
												 optional ERootBoneAxis AxisZ = RBA_Default);

native function SetAnimByName(Name AnimName, optional ERootBoneAxis AxisX = RBA_Default,
												optional ERootBoneAxis AxisY = RBA_Default,
												optional ERootBoneAxis AxisZ = RBA_Default,
												optional float UseRate = 1.0f,
												optional float StartTime = 0.0f);

DefaultProperties
{
	Children(eMoveType_Running)=(Name="Running")
	Children(eMoveType_Stationary)=(Name="Stationary")
	Children(eMoveType_Dead)=(Name="Dead")
	Children(eMoveType_Turn)=(Name="Turn")
	Children(eMoveType_Action)=(Name="Action");
	Children(eMoveType_StartRunning)=(Name="Start Running");
	Children(eMoveType_Anim)=(Name="Anim");
}
