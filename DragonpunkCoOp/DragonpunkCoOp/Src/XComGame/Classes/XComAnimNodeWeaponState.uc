//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAnimNodeWeaponState extends AnimNodeBlendList
	native(Animation);

enum EAnimWeaponState
{
 	eAnimWeaponState_Idle,
 	eAnimWeaponState_Fire,
};

cpptext
{
}

defaultproperties
{
	Children(eAnimWeaponState_Idle)=(Name="RaisedIdle")
	Children(eAnimWeaponState_Fire)=(Name="Fire")

	bFixNumChildren=true
	bPlayActiveChild=true
}
