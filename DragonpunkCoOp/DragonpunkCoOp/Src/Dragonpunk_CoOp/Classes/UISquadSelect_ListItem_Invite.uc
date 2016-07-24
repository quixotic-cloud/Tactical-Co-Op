// This is an Unreal Script
                           
class UISquadSelect_ListItem_Invite extends UIPanel;

var UIButton InvitePlayer;

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	InvitePlayer = (Spawn(class'UIButton', self)).InitButton('InvitePlayer',"Invite Friend",,eUIButtonStyle_BUTTON_WHEN_MOUSE);
	return self;
}
simulated function ChangePanelDim(UIPanel ExternalPanel)
{
	self.SetHeight(ExternalPanel.Height/2);
	self.SetWidth(ExternalPanel.Width/2);
	
}
simulated function AS_SetEmpty( string label )
{
	mc.FunctionString("setEmptySlot", label);
}