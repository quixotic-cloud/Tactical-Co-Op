//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComAnimNodeWeapon extends AnimNodeBlendList
	native(Animation);

enum EAnimWeapon
{
 	eAnimWeapon_Idle,
 	eAnimWeapon_FocusFire,
 	eAnimWeapon_CCFire,
 	eAnimWeapon_Reload,
	eAnimWeapon_Equip,
	eAnimWeapon_UnEquip,
	eAnimWeapon_UnEquippedIdle
};

defaultproperties
{
	Children(eAnimWeapon_Idle)=(Name="Idle")
	Children(eAnimWeapon_FocusFire)=(Name="Focus Fire")
	Children(eAnimWeapon_CCFire)=(Name="CC Fire")
	Children(eAnimWeapon_Reload)=(Name="Reload")
	Children(eAnimWeapon_Equip)=(Name="Equip")
	Children(eAnimWeapon_UnEquip)=(Name="UnEquip")
	Children(eAnimWeapon_UnEquippedIdle)=(Name="UnEquippedIdle")

	bPlayActiveChild=true
	NodeName = "AnimNode"
}
