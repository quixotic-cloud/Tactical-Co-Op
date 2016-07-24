class X2SoldierClass_DefaultClasses extends X2SoldierClass
	config(ClassData);

var config array<name> SoldierClasses;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2SoldierClassTemplate Template;
	local name SoldierClassName;
	
	foreach default.SoldierClasses(SoldierClassName)
	{
		`CREATE_X2TEMPLATE(class'X2SoldierClassTemplate', Template, SoldierClassName);
		Templates.AddItem(Template);
	}

	return Templates;
}