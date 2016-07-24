class XComDestructibleActor_Toughness extends Object
	native(Destruction);

enum Toughness_TargetableBy
{
	TargetableByNone,
	TargetableByXCom,
	TargetableByAliens,
	TargetableByAll,
};

var() int Health;
var() int AvailableFireFuelTurns;
var() bool bFragile<editcondition=!bInvincible>;
var() bool bInvincible<editcondition=!bFragile>;
var() bool bNonFlammable;
var() bool bSuccumbsToDamage<editcondition=bInvincible>;
var() bool bImmuneToAreaBurnDamage<editcondition=!bInvincible>;
var() name SuccumbsToDamageType<Tooltip="Name of a damage type that can hurt the object even when it is invincible.">;
var() Toughness_TargetableBy TargetableBy<editcondition=!bInvincible>;

defaultproperties
{
	Health=3
	AvailableFireFuelTurns=0
	bFragile=false
	bSuccumbsToDamage=false
	bNonFlammable=false
	TargetableBy=TargetableByNone
}
