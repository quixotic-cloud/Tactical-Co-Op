/**
 * A wait condition that requires the selected unit be at a specific location.
 */
class XComWaitCondition_SelectedUnitPos extends XComWaitCondition_DistanceCheck;

// TODO: Perhaps this should be available at a broader scope
function protected XGPlayer GetHumanPlayer()
{
	local XComTacticalGRI TacticalGRI;
	local XGBattle_SP Battle;
	local XGPlayer HumanPlayer;

	TacticalGRI = `TACTICALGRI;
	Battle = (TacticalGRI != none)? XGBattle_SP(TacticalGRI.m_kBattle) : none;
	HumanPlayer = (Battle != none)? Battle.GetHumanPlayer() : none;

	return HumanPlayer;
}

function Actor GetActor()
{
	local XGPlayer HumanPlayer;
	local XGUnit SelectedUnit;
	local XComUnitPawn SelectedUnitPawn;

	HumanPlayer = GetHumanPlayer();
	SelectedUnit = (HumanPlayer != none)? HumanPlayer.GetActiveUnit() : none;
	SelectedUnitPawn = (SelectedUnit != none)? SelectedUnit.GetPawn() : none;

	return SelectedUnitPawn;
}

function String GetActorName()
{
	return "Selected Unit";
}

DefaultProperties
{
	ObjName="Wait for Selected Unit Position"
}
