class UIInventory_ClassListItem extends UIInventory_ListItem;

simulated function UIListItemString InitListItem(optional string InitText)
{
	InitPanel();

	//OVERRIDE what the base class is setting for 3D/2D, since we're using a super giant button.
	MC.ChildSetNum("theButton", "_height", height-4);
	return self;
}

simulated function PopulateData(optional bool bRealizeDisabled)
{
	MC.BeginFunctionOp("populateData");
	MC.QueueString(ItemComodity.Image);
	MC.QueueString(ItemComodity.Title);
	MC.QueueString(class'UIUtilities_text'.static.GetTimeRemainingString(ItemComodity.OrderHours));
	MC.QueueString(ItemComodity.Desc);
	MC.EndOp();

	if(bRealizeDisabled)
		RealizeDisabledState();
}

defaultproperties
{
	LibID = "InventoryClassListItem";
	bShouldSet3DHeight=false;
	bCascadeFocus = false;
	height = 166;
}