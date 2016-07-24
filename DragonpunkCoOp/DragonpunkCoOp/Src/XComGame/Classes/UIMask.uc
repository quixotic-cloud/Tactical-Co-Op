
class UIMask extends UIPanel;

var UIPanel target;

simulated function UIMask InitMask(optional name InitName, optional UIPanel targetControl, optional float startX, optional float startY, optional float startWidth, optional float startHeight)
{
	InitPanel(InitName);
	SetPosition(startX, startY);
	SetSize(startWidth, startHeight);
	SetMask(targetControl);
	return self;
}

simulated function UIMask SetMask(UIPanel targetClip)
{
	local UIPanel oldTarget; 

	oldTarget = target; 

	if(target != targetClip)
	{
		// Should happen before updating the member target. 
		if( oldTarget != none )
		{
			ClearMask();
			oldTarget.ClearOnInitDelegate(ActivateMask); 
		}

		target = targetClip;

		if( target != none )
		{
			if( target.mc.cacheIndex != -1 )
				ActivateMask(self);
			else 
				target.AddOnInitDelegate(ActivateMask);
		}
	}
	return self;
}

//Use the properties of another clip to quick set a mask to size.  
simulated function UIMask FitMask(UIPanel targetControl)
{
	SetPosition(targetControl.X, targetControl.Y);
	SetSize(targetControl.width, targetControl.height);
	return self;
}

simulated function ActivateMask( UIPanel Control )
{
	target.mc.FunctionNum("setMaskControl", mc.cacheIndex);
}

simulated function ClearMask()
{
	target.mc.FunctionNum("setMaskControl", -1);
}

simulated function Remove()
{
	if(target != none)
		SetMask(none);
	super.Remove();
}

simulated function DebugControl()
{
	local UIPanel debugRect; 
	ClearMask();
	debugRect = Spawn(class'UIPanel', self).InitPanel(, class'UIUtilities_Controls'.const.MC_GenericPixel);
	debugRect.SetSize(width, height);
	debugRect.SetColor("0x00ccff");
	debugRect.SetAlpha(20);
}

defaultproperties
{
	LibID = "MaskControl";
	bIsNavigable = false;
}
