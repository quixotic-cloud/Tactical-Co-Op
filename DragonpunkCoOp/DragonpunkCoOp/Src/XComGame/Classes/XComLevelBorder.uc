class XComLevelBorder extends StaticMeshActor
	placeable;

static function ToggleBorder()
{
	local XComLevelBorder A;

	foreach class'Engine'.static.GetCurrentWorldInfo().AllActors(class'XComLevelBorder', A) 
	{
		if (A.bHidden == true)
		{
			A.SetHidden(false);
		}
		else
		{
			A.SetHidden(true);
		}
	}
}

defaultproperties
{
	Begin Object Name=StaticMeshComponent0
	    TranslucencySortPriority=-2000
	End Object
}
