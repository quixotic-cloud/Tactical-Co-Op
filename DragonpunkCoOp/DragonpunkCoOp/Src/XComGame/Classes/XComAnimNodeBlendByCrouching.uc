//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAnimNodeBlendByCrouching extends AnimNodeBlendList
	native(Animation);

cpptext
{
	virtual	void TickAnim( FLOAT DeltaSeconds );
}

DefaultProperties
{
	Children(0)=(Name="Crouching")
	Children(1)=(Name="Standing")
}
