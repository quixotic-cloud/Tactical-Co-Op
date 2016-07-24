class XComDestructibleActor_Action_ToggleEffect extends XComDestructibleActor_Action
	native(Destruction);

var deprecated Emitter Emitter<ToolTip="The emitter to toggle">;
var(XComDestructibleActor_Action) array<Emitter> Emitters<ToolTip="The emitters to toggle">;

cpptext
{
	virtual void PostLoad();
}

native function Activate();
