interface Destructible
	native(Core);

event DestructibleTakeDamage(XComGameState_EnvironmentDamage DamageEvent);

cpptext
{
	virtual void PostProcessDamage(const FStateObjectReference &Dmg) = 0;
	
	//These functions are called as part of the system to show which environment objects will be affected by AOE damage
	virtual void ApplyAOEDamageMaterial() = 0;
	virtual void RemoveAOEDamageMaterial() = 0;
	virtual void GetAffectedChildren(TArray<IDestructible*>& Children) = 0;
	virtual bool GetAOEBreadcrumb() = 0;
	virtual int GetToughnessHealth() = 0;
}
