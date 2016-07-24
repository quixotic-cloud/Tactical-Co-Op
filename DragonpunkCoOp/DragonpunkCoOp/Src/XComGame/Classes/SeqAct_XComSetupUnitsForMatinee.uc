class SeqAct_XComSetupUnitsForMatinee extends SequenceAction;

var() FaceFXAsset FaceFX;
var() bool bClearMove;
var() bool bDisableGenderBlender;

event Activated()
{
	local SeqVarLink kVarLink;
	local SequenceVariable kSeqVar; 
	local XGBattle Battle;
	local SeqVar_Object SeqVarObj;
	local XComHumanPawn HumanPawn;
	local int Idx;

	Battle = GetXGBattle();

	Idx = 0;
	foreach VariableLinks(kVarLink)
	{
		if(kVarLink.LinkDesc != "Unit Pawns") continue;

		foreach kVarLink.LinkedVariables(kSeqVar)
		{
			SeqVarObj = SeqVar_Object(kSeqVar);
			if(SeqVarObj == none) continue;

			HumanPawn = XComHumanPawn(SeqVarObj.GetObjectValue());
			if(HumanPawn == none) continue;

			if(InputLinks[0].bHasImpulse)
			{
				AtMatineeStart(HumanPawn, Battle, Idx);
			}
			else
			{
				AtMatineeEnd(HumanPawn, Battle, Idx);
			}

			Idx++;
		}
	}
}

function AtMatineeStart( XComHumanPawn UnitPawn, XGBattle Battle, int Idx )
{
	Battle.m_arrInitialUnitLocs[Idx] = UnitPawn.Location;

	if (FaceFX != none)
	{
		UnitPawn.m_kHeadMeshComponent.SkeletalMesh.FaceFXAsset = FaceFX;
		UnitPawn.m_kHeadMeshComponent.ForcedLodModel = 1;
		//UnitPawn.m_kHeadMeshComponent.SetParentAnimComponent(none);
		UnitPawn.ReattachComponent(UnitPawn.m_kHeadMeshComponent);
	}

	UnitPawn.SetupForMatinee(none, true, bDisableGenderBlender);
	UnitPawn.StopTurning();

	//`log("Unit #"$Idx$":"@UnitPawn@", Start Location:"@Battle.m_arrInitialUnitLocs[Idx]);
	UnitPawn.SetLocation(Battle.m_arrInitialUnitLocs[Idx]);

	UnitPawn.m_bTutorialCanDieInMatinee = true;
}

function AtMatineeEnd( XComHumanPawn UnitPawn, XGBattle Battle, int Idx )
{
	local XGUnit Unit;
	local Vector vDir;

	Unit = XGUnit(UnitPawn.GetGameUnit());
	UnitPawn.ReturnFromMatinee();
	
	if (UnitPawn.m_kHeadMeshComponent.SkeletalMesh.FaceFXAsset != none)
	{
		UnitPawn.m_kHeadMeshComponent.SkeletalMesh.FaceFXAsset = none;
		UnitPawn.m_kHeadMeshComponent.ForcedLodModel = 0;
		UnitPawn.DetachComponent(UnitPawn.m_kHeadMeshComponent);
		UnitPawn.AttachComponent(UnitPawn.m_kHeadMeshComponent);
	}
			
	UnitPawn.EnableRMA(true, true);

	//`log("Unit #"$Idx$":"@UnitPawn@", TP Location:"@Battle.m_arrInitialUnitLocs[Idx]);

	TeleportTo(Unit, Battle.m_arrInitialUnitLocs[Idx]);

	vDir = UnitPawn.FocalPoint - UnitPawn.Location;
	vDir.z = 0;
	UnitPawn.SetRotation(Rotator(vDir));

	UnitPawn.m_bTutorialCanDieInMatinee = false;
}

function TeleportTo(XGUnit ActiveUnit, Vector vLoc)
{	
	if (ActiveUnit != none)
	{
		ActiveUnit.GetPawn().SetLocation(vLoc);

		// MHU - Unit should process the cover system whenever he moves. This all-in-one function also updates Vis.
		ActiveUnit.ProcessNewPosition();
	}
}

function protected XGBattle GetXGBattle()
{
	local XComTacticalGRI TacticalGRI;
	
	TacticalGRI = `TACTICALGRI;

	return TacticalGRI.m_kBattle;
}

defaultproperties
{
	ObjName="XCom Pawns to Matinee"
	ObjCategory="Cinematic"
	bCallHandler=false;

	bDisableGenderBlender=false;

	InputLinks(0)=(LinkDesc="Prep")
	InputLinks(1)=(LinkDesc="Restore")

	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit Pawns")
}
