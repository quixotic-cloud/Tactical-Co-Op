class X2SoldierAbilityUnlockTemplate extends X2SoldierUnlockTemplate;

var name AbilityName;

function bool ValidateTemplate(out string strError)
{
	if (class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName) == none)
	{
		strError = "references unknown ability template" @ AbilityName;
		return false;
	}
	return super.ValidateTemplate(strError);
}