class X2Item_DefaultDamageTypes extends X2Item config(GameData_WeaponData);

var name DefaultDamageType;
var privatewrite name KnockbackDamageType;
var privatewrite name ParthenogenicPoisonType;
var privatewrite name DisorientDamageType;

var config array<name> DamagedTeleport_DmgNotAllowed;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> DamageTypes;

	DamageTypes.AddItem(CreateConventionalProjectileDamageType('DefaultProjectile'));
	DamageTypes.AddItem(CreateConventionalProjectileDamageType('Projectile_Conventional'));
	DamageTypes.AddItem(CreateMagneticProjectileDamageType('Projectile_MagXCom'));
	DamageTypes.AddItem(CreateMagneticProjectileDamageType('Projectile_MagAdvent'));
	DamageTypes.AddItem(CreateBeamProjectileDamageType('Projectile_BeamXCom'));
	DamageTypes.AddItem(CreateBeamProjectileDamageType('Projectile_BeamAlien'));
	DamageTypes.AddItem(CreateBeamProjectileDamageType('Projectile_BeamAvatar'));
	DamageTypes.AddItem(CreateHeavyDamageType());
	DamageTypes.AddItem(CreateExplosionDamageType());
	DamageTypes.AddItem(CreateFireDamageType());
	DamageTypes.AddItem(CreateAcidDamageType());
	DamageTypes.AddItem(CreatePoisonDamageType());
	DamageTypes.AddItem(CreatePsiDamageType());
	DamageTypes.AddItem(CreateElectricalDamageType());
	DamageTypes.AddItem(CreateMeleeDamageType());
	DamageTypes.AddItem(CreateParthenogenicPoisonDamageType());
	DamageTypes.AddItem(CreateViperCrushDamageType());
	DamageTypes.AddItem(CreateStunDamageType());
	DamageTypes.AddItem(CreateKnockbackDamageType());
	DamageTypes.AddItem(CreateBlazingPinionsDamageType());
	DamageTypes.AddItem(CreateMentalDamageType());
	DamageTypes.AddItem(CreateUnconsciousDamageType());
	DamageTypes.AddItem(CreateNonflammableExplosionDamageType());
	DamageTypes.AddItem(CreateDisorientDamageType());
	DamageTypes.AddItem(CreatePanicDamageType());
	
	return DamageTypes;
}

static function X2DamageTypeTemplate CreateConventionalProjectileDamageType(Name TemplateName)
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, TemplateName);

	//By default projectiles *can* cause all of the below effects. The actual results depend on damage and other ammo-based considerations
	Template.bCauseFracture = true;
	Template.MaxFireCount = 1;
	Template.FireChance = 10;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreateMagneticProjectileDamageType(Name TemplateName)
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, TemplateName);

	//By default projectiles *can* cause all of the below effects. The actual results depend on damage and other ammo-based considerations
	Template.bCauseFracture = true;
	Template.MaxFireCount = 1;
	Template.FireChance = 30;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreateBeamProjectileDamageType(Name TemplateName)
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, TemplateName);

	//By default projectiles *can* cause all of the below effects. The actual results depend on damage and other ammo-based considerations
	Template.bCauseFracture = true;
	Template.MaxFireCount = 2;
	Template.FireChance = 50;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreateHeavyDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, 'Heavy');

	Template.bCauseFracture = true;		
	Template.MaxFireCount = 2;
	Template.FireChance = 50;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreateExplosionDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, 'Explosion');
	
	Template.bCauseFracture = true;
	Template.MaxFireCount = 3;
	Template.MinFireCount = 1;
	Template.FireChance = 100;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreateFireDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, 'Fire');

	Template.bCauseFracture = false;
	Template.MaxFireCount = 0; //Fire damage is the result of fire, not a cause
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreateAcidDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, 'Acid');

	Template.bCauseFracture = false;
	Template.MaxFireCount = 0;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreatePoisonDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, 'Poison');

	Template.bCauseFracture = false;
	Template.MaxFireCount = 0;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreateParthenogenicPoisonDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, default.ParthenogenicPoisonType);

	Template.bCauseFracture = false;
	Template.MaxFireCount = 0;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreatePsiDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, 'Psi');

	Template.bCauseFracture = false;
	Template.MaxFireCount = 0;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreateElectricalDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, 'Electrical');

	Template.bCauseFracture = true;
	Template.MaxFireCount = 2;
	Template.FireChance = 30;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreateMeleeDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, 'Melee');

	Template.bCauseFracture = false;
	Template.MaxFireCount = 0;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreateViperCrushDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, 'ViperCrush');

	Template.bCauseFracture = false;
	Template.MaxFireCount = 0;
	Template.bAllowAnimatedDeath = false;

	return Template;
}

static function X2DamageTypeTemplate CreateStunDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, 'Stun');

	//By default projectiles *can* cause all of the below effects. The actual results depend on damage and other ammo-based considerations
	Template.bCauseFracture = false;		
	Template.MaxFireCount = 0;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreateKnockbackDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, default.KnockbackDamageType);

	Template.bCauseFracture = false;
	Template.MaxFireCount = 0;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreateBlazingPinionsDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, 'BlazingPinions');
	
	Template.bCauseFracture = true;
	Template.MaxFireCount = 3;
	Template.MinFireCount = 1;
	Template.FireChance = 50;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreateMentalDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, 'Mental');

	Template.bCauseFracture = false;
	Template.MaxFireCount = 0;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreateUnconsciousDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, 'Unconscious');

	Template.bCauseFracture = false;
	Template.MaxFireCount = 0;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreateNonflammableExplosionDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, 'NoFireExplosion');

	Template.bCauseFracture = true;
	Template.MaxFireCount = 0;
	Template.FireChance = 0;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreateDisorientDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, default.DisorientDamageType);

	Template.bCauseFracture = false;
	Template.MaxFireCount = 0;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

static function X2DamageTypeTemplate CreatePanicDamageType()
{
	local X2DamageTypeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DamageTypeTemplate', Template, 'Panic');

	Template.bCauseFracture = false;
	Template.MaxFireCount = 0;
	Template.bAllowAnimatedDeath = true;

	return Template;
}

defaultproperties
{
	DefaultDamageType = "DefaultProjectile"
	KnockbackDamageType="KnockbackDamage"
	ParthenogenicPoisonType="ParthenogenicPoison"
	DisorientDamageType="Disorient"
}
