//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_TransferToNewMission extends X2Action;

var string MissionType;

simulated state Executing
{
	function TransferToNewMission()
	{
		local XComPlayerController PlayerController;

		if(MissionType == "")
		{
			`Redscreen("X2Action_TransferToNewMission!");
			return;
		}

		PlayerController = XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
		PlayerController.TransferToNewMission(MissionType);
	}

Begin:
	TransferToNewMission();

	CompleteAction();
}

DefaultProperties
{
}
