class XGInventoryNativeBase extends Actor
	  native(Core);

const MAX_INVENTORY_ITEMS_PER_SLOT = 5;

//RAM - if you add to to this enum, be sure to increment the global macro MAX_LOADOUT_SLOTS! Got burned by this...
enum ELocation
{	
	eSlot_None,	
	eSlot_RightBack,
	eSlot_LeftBack,
	eSlot_RightHand,
	eSlot_LeftHand,
	eSlot_Grapple,
	eSlot_RightThigh,
	eSlot_LeftThigh,
	eSlot_LeftBelt,       
	eSlot_RightChest,
	eSlot_LeftChest,	
	eSlot_RightForearm,
	eSlot_RightSling,       // MHU - Reserved for weapon swapping. Do not equip weapons directly here.
	eSlot_RearBackPack,     // MHU - Weapons equipped here are hidden, revealed only upon attach anywhere else.
	eSlot_PsiSource,
	eSlot_Head,	
	eSlot_CenterChest,
	eSlot_Claw_R,           // Added muton berserker locations for muton blades.
	eSlot_Claw_L,
	eSlot_ChestCannon,			// This is for the sectopod focus fire
	eSlot_KineticStrike,    //MEC support
	eSlot_Flamethrower,     //MEC support
	eSlot_ElectroPulse,     //MEC support		
	eSlot_GrenadeLauncher,  //MEC support		
	eSlot_PMineLauncher,    //MEC support		
	eSlot_RestorativeMist,  //MEC support		
	eSlot_LowerBack,
	eSlot_BeltHolster,
	eSlot_HeavyWeapon,      //For weapons that are integrated into heavy armor
};

struct native InventorySlot
{
	var	private	ELocation			            m_eLoc;
	var	private	XGInventoryItem		            m_arrItems[`MAX_INVENTORY_ITEMS_PER_SLOT];
	var private int                             m_iNumItems;
	var         bool                            m_bMultipleItems;
	var	        bool                            m_bReserved;
	var transient XComWeapon                    m_kLastUnequippedWeapon;
};

var private InventorySlot m_arrStructSlots[ ELocation.EnumCount ];
var ELocation m_ActiveWeaponLoc;
var float m_fModifiableEngagementRange;// MHU - Determines the max modifiable weapon range for all items in inventory 
												   //       that can be used immediately.
var float m_fFixedEngagementRange;// MHU - Determines max fixed weapon range for items in inventory that can be used immediately.
var float m_fGrenadeEngagementRange;// MHU - Determines max grenade range

var XGWeapon m_kPrimaryWeapon;
var XGWeapon m_kSecondaryWeapon;

var	XGUnit	m_kOwner;
var XGInventoryItem  m_kLastEquippedItem;

replication
{
	if( Role == Role_Authority )
		m_kOwner;
}

// Add item to a unit's inventory at the specified inventory location
native simulated function bool AddItem( XGInventoryItem kItem, ELocation eLoc , optional bool bMultipleItems = false);

native simulated function XGInventoryItem GetItem( ELocation eSlot );

native simulated function bool IsItemInInventory( XGInventoryItem kItem);

native simulated function XGWeapon GetActiveWeapon();

native simulated function XGInventoryItem FindGrenade();

//  ported slot functionality
native simulated function XGInventoryItem GetPrimaryItemInSlot(ELocation Slot);
native simulated function SetPrimaryItemInSlot(ELocation Slot, XGInventoryItem kItem);
native simulated function SetItemByIndexInSlot(ELocation Slot, int iIndex, XGInventoryItem kItem);
native simulated function int GetNumberOfItemsInSlot(ELocation Slot);
native simulated function XGInventoryItem GetItemByIndexInSlot(int iIndex, ELocation Slot);
native simulated function EquipItemInSlot(ELocation Slot, XGInventoryItem kItem);
native simulated function UnequipItemInSlot(ELocation Slot, optional XGInventoryItem kItem);
native simulated function XGInventoryItem SearchForItemByEnumInSlot(ELocation Slot, EItemType eCompareType, optional out int iSearchIndex);
native simulated function AddItemInSlot(ELocation Slot, XGInventoryItem kItem , optional bool bMultipleItems = false);
native simulated function RemoveItemInSlot(ELocation Slot);

// This handles the visuals of the actual 3D item/weapon
simulated event PresAddItem(XGInventoryItem kItem)
{
	local XGWeapon ActiveWeapon;
	local XComWeapon kWeapon;

	ActiveWeapon = XGWeapon(kItem);
	assert(ActiveWeapon != none);

	kWeapon = XComWeapon(kItem.m_kEntity);
	m_kOwner.GetPawn().AttachItem( kItem.m_kEntity, kWeapon.DefaultSocket, false, kItem.m_kMeshComponent);

	// MHU - If kItem.m_kMeshComponent exists, then AddItem succeeded in finding the mesh component from
	//       m_kEntity and moving it onto Mesh.Attachments array.
	assert (kItem.m_kMeshComponent != none);
}

simulated function bool IsInitialReplicationComplete()
{
	local bool bInitialReplicationComplete;
	//local int i, ReplicatedSlots;

	bInitialReplicationComplete = true;
	/*
	if (NumRequiredSlots > -1)
	{
		ReplicatedSlots = 0;
		for(i = 0; i < ELocation.EnumCount; i++)
		{
			`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(i) @ `ShowVar(m_arrSlots[i]) @ `ShowVar(m_arrSlots[i].IsInitialReplicationComplete()));
			// dont care about the none slot -tsmith 
			if(ELocation(i) == eSlot_None)
			{
				continue;
			}
			else if(m_arrSlots[i] != none && m_arrSlots[i].IsInitialReplicationComplete())
			{
				ReplicatedSlots++;
			}
		}

		`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(ReplicatedSlots) @ `ShowVar(NumRequiredSlots));
		bInitialReplicationComplete = (ReplicatedSlots == NumRequiredSlots);
	}
	else
	{
		bInitialReplicationComplete = false;
	}
	*/

	`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(bInitialReplicationComplete));


	return bInitialReplicationComplete;
}

final function PostInit()
{
	local int i;

	//  Set the location for all slots
	for (i = 0; i < ELocation.EnumCount; ++i)
	{
		m_arrStructSlots[i].m_eLoc = ELocation(i);
	}
}

simulated function string ToString()
{
	local string strRep;

	strRep = self @ `ShowVar(m_ActiveWeaponLoc) $ "\n";

	return strRep;
}

simulated function DestroyXComWeapons()
{
	local int Slot;
	local int Index;
	local XGWeapon SlotWeapon;

	for( Slot = 0; Slot < ELocation.EnumCount; ++Slot )
	{
		for( Index = 0; Index < m_arrStructSlots[Slot].m_iNumItems; ++Index )
		{
			SlotWeapon = XGWeapon(m_arrStructSlots[Slot].m_arrItems[Index]);
			if( SlotWeapon != none && XComWeapon(SlotWeapon.m_kEntity) != none )
			{
				SlotWeapon.m_kEntity.Destroy();
				SlotWeapon.m_kEntity = none;
			}
		}
	}
}

defaultproperties
{
	//bAlwaysRelevant = true;
	//RemoteRole = Role_SimulatedProxy;
	bAlwaysRelevant=true;
	RemoteRole=ROLE_None;
}