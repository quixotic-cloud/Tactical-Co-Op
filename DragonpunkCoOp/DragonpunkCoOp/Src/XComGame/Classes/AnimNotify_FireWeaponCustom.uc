
class AnimNotify_FireWeaponCustom extends AnimNotify_FireWeapon
	native(Animation);

var() bool bDoDamage;
var() int TemplateIndex;
var() int WeaponIndex;
var() name WeaponSocketName;
var() string PerkAbilityName;

cpptext
{
	// AnimNotify interface.
	virtual void Notify( class UAnimNodeSequence* NodeSeq );
	virtual FString GetEditorComment() { return TEXT("FireCustom"); }
	virtual FColor GetEditorColor() { return FColor(255,150,150); }
}

defaultproperties
{
	TemplateIndex=0;
	WeaponIndex=0;
	WeaponSocketName="gun_fire"
	PerkAbilityName="";
}
