class SeqAct_UnitLightingChannels extends SequenceAction;

struct TLightingData
{
	var() name ChannelName;
	var() LightingChannelContainer LightingChannel;
};

struct TUnitLighting
{
	var() name PawnChannel;
	var() name AttachementChannel;
	var() bool bDisableDLE;
	var() int SquadMemberIdx;
};

var(Lighting) array<TLightingData> LightingChannels;

var(Pawn) array<TUnitLighting> UnitLighting;

var LightingChannelContainer DefaultLightingChannel;

event Activated()
{
	local XGPlayer HumanPlayer;
	local XGSquad Squad;
	local XGUnit Unit;
	local XComHumanPawn UnitPawn;
	local int i;
	local LightingChannelContainer kLightingChannelContainer;
	local Object Target;
	local XGInventory UnitInventory;

	if( Targets.Length > 0 )
	{  
		foreach Targets(Target)
		{
			UnitPawn = XComHumanPawn(Target);
			if( UnitPawn != none )
			{
				if (InputLinks[0].bHasImpulse)
				{						
					InitializeLightingChannels();

					if (GetLightingFromName(UnitLighting[i].PawnChannel, kLightingChannelContainer))
					{
						SetLightingOnMesh(UnitPawn.Mesh, !UnitLighting[i].bDisableDLE, kLightingChannelContainer);
						SetLightingOnMesh(UnitPawn.HairComponent, !UnitLighting[i].bDisableDLE, kLightingChannelContainer);
						SetLightingOnMesh(UnitPawn.m_kHeadMeshComponent, !UnitLighting[i].bDisableDLE, kLightingChannelContainer);
					}

					if (GetLightingFromName(UnitLighting[i].AttachementChannel, kLightingChannelContainer))
					{
						SetLightingOnMesh(UnitPawn.Weapon.Mesh, !UnitLighting[i].bDisableDLE, kLightingChannelContainer);

						UnitInventory = XGUnit(UnitPawn.GetGameUnit()).GetInventory();
						if( UnitInventory != none )
						{
							UnitInventory.SetAllInventoryLightingChannels(!UnitLighting[i].bDisableDLE, kLightingChannelContainer);
						}

						LightWeapons(UnitInventory, !UnitLighting[i].bDisableDLE, kLightingChannelContainer);
					}
				}
				else
				{
					SetLightingOnMesh(UnitPawn.Mesh, true, DefaultLightingChannel);
					SetLightingOnMesh(UnitPawn.HairComponent, true, DefaultLightingChannel);
					SetLightingOnMesh(UnitPawn.m_kHeadMeshComponent, true, DefaultLightingChannel);
					SetLightingOnMesh(UnitPawn.Weapon.Mesh, true, DefaultLightingChannel);

					UnitInventory = XGUnit(UnitPawn.GetGameUnit()).GetInventory();
					if( UnitInventory != none )
					{
						UnitInventory.SetAllInventoryLightingChannels(true, DefaultLightingChannel);
					}

					LightWeapons(UnitInventory, true, DefaultLightingChannel);
				}
			}
		}
	}
	else
	{
		HumanPlayer = GetHumanPlayer();
		if (HumanPlayer != none)
		{
			Squad = HumanPlayer.m_kSquad;

			if (InputLinks[0].bHasImpulse)
			{						
				InitializeLightingChannels();

				for (i = 0; i < UnitLighting.Length; ++i)
				{
					Unit = Squad.GetMemberAt(UnitLighting[i].SquadMemberIdx);
					if (Unit != none)
					{
						UnitPawn = XComHumanPawn(Unit.GetPawn());
						if (UnitPawn != none)
						{
							if (GetLightingFromName(UnitLighting[i].PawnChannel, kLightingChannelContainer))
							{
								SetLightingOnMesh(UnitPawn.Mesh, !UnitLighting[i].bDisableDLE, kLightingChannelContainer);
								SetLightingOnMesh(UnitPawn.HairComponent, !UnitLighting[i].bDisableDLE, kLightingChannelContainer);
								SetLightingOnMesh(UnitPawn.m_kHeadMeshComponent, !UnitLighting[i].bDisableDLE, kLightingChannelContainer);
							}

							if (GetLightingFromName(UnitLighting[i].AttachementChannel, kLightingChannelContainer))
							{
								SetLightingOnMesh(UnitPawn.Weapon.Mesh, !UnitLighting[i].bDisableDLE, kLightingChannelContainer);

								UnitInventory = XGUnit(UnitPawn.GetGameUnit()).GetInventory();
								if( UnitInventory != none )
								{
									UnitInventory.SetAllInventoryLightingChannels(!UnitLighting[i].bDisableDLE, kLightingChannelContainer);
								}

								LightWeapons(UnitInventory, !UnitLighting[i].bDisableDLE, kLightingChannelContainer);
							}
						}
					}
				}
			}
			else if (InputLinks[1].bHasImpulse)
			{
				for (i = 0; i < Squad.GetNumMembers(); ++i)
				{
					Unit = Squad.GetMemberAt(i);

					if (Unit != none)
					{
						UnitPawn = XComHumanPawn(Unit.GetPawn());
						if (UnitPawn != none)
						{
							SetLightingOnMesh(UnitPawn.Mesh, true, DefaultLightingChannel);
							SetLightingOnMesh(UnitPawn.HairComponent, true, DefaultLightingChannel);
							SetLightingOnMesh(UnitPawn.m_kHeadMeshComponent, true, DefaultLightingChannel);
							SetLightingOnMesh(UnitPawn.Weapon.Mesh, true, DefaultLightingChannel);

							UnitInventory = XGUnit(UnitPawn.GetGameUnit()).GetInventory();
							if( UnitInventory != none )
							{
								UnitInventory.SetAllInventoryLightingChannels(true, DefaultLightingChannel);
							}

							LightWeapons(UnitInventory, true, DefaultLightingChannel);
						}
					}
				}
			}
		}
	}
}

function LightWeapons(XGInventory UnitInventory, bool bEnableDLE, LightingChannelContainer LightChannelContainer)
{
	local array<XGWeapon> Weapons;
	local XComWeapon CurrentWeapon;
	local int i;

	UnitInventory.GetWeapons(Weapons);

	for( i = 0; i < Weapons.Length; i++ )
	{
		CurrentWeapon = XComWeapon(Weapons[i].m_kEntity);
		if( CurrentWeapon != none )
		{			
			SetLightingOnMesh(CurrentWeapon.Mesh, bEnableDLE, LightChannelContainer);
		}
	}
}

function InitializeLightingChannels()
{
	local int i;

	for (i = 0; i < LightingChannels.Length; ++i)
	{
		LightingChannels[i].LightingChannel.bInitialized = true;
	}
}

function SetLightingOnMesh(MeshComponent Mesh, bool bEnableDLE, LightingChannelContainer LightChannelContainer)
{
	if (Mesh != none)
	{
		Mesh.LightEnvironment.SetEnabled(bEnableDLE);
		Mesh.SetLightingChannels(LightChannelContainer);
	}
}

function bool GetLightingFromName(name ChannelName, out LightingChannelContainer LightChannelContainer)
{
	local int i;
	
	for (i = 0; i < LightingChannels.Length; ++i)
	{
		if (LightingChannels[i].ChannelName == ChannelName)
		{
			LightChannelContainer = LightingChannels[i].LightingChannel;
			return true;
		}
	}

	return false;
}

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

defaultproperties
{
	ObjName="Set Lighting Channels"
	ObjCategory="Actor"
	bCallHandler=false;

	InputLinks(0)=(LinkDesc="Set")
	InputLinks(1)=(LinkDesc="Restore")

	DefaultLightingChannel=(bInitialized=true,Dynamic=true)
}
