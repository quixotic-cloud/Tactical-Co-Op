class XComDestructibleActor_Action_ToggleLight extends XComDestructibleActor_Action
	native(Destruction);

var(XComDestructibleActor_Action) Array<Light> Lights;
var(XComDestructibleActor_Action) Array<LightInjector> LightInjectors;

enum LightAction
{
	eLA_Toggle,
	eLA_TurnOff,
	eLA_TurnOn
};

var(XComDestructibleActor_Action) LightAction ActionType;

native function Activate();

cpptext
{
	virtual void PostLoad( );
}

defaultproperties
{
	ActionType=eLA_TurnOff;
}
