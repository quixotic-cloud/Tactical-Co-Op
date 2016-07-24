class XGInventory extends XGInventoryNativeBase
	dependson(XGWeapon);

function int GetLocationCount()
{
	return Elocation.EnumCount;
}

function OnLoad( XGUnit kUnit )
{
	// MHU - Re-associate Inventory owner
	m_kOwner = kUnit;

	ApplyInventoryOnLoad();
}

function ApplyInventoryOnLoad()
{
	local int i, j, Idx;
	local XGInventoryItem kItem;
	local XGWeapon ActiveWeapon;
	local XComWeapon kWeapon;
	local MeshComponent AttachedComponent;

	//  all items need to have their entities recreated
	for (i = 0; i < eSlot_MAX; ++i)
	{
		for (j = 0; j < GetNumberOfItemsInSlot(ELocation(i)); ++j)
		{
			kItem = GetItemByIndexInSlot(j, ELocation(i));
			if (kItem != none)
			{
				kItem.Init();       //  fills out the template data
				kItem.m_kEntity = kItem.CreateEntity();
				ActiveWeapon = XGWeapon(kItem);
				if (ActiveWeapon != none)
				{
					kWeapon = XComWeapon(kItem.m_kEntity);
					kWeapon.m_kPawn = m_kOwner.GetPawn();
					kWeapon.Instigator = kWeapon.m_kPawn;

					kWeapon.m_kPawn.UpdateMeshMaterials(kWeapon.Mesh);
					for(Idx = 0; Idx < SkeletalMeshComponent(kWeapon.Mesh).Attachments.Length; ++Idx)
					{
						AttachedComponent = MeshComponent(SkeletalMeshComponent(kWeapon.Mesh).Attachments[Idx].Component);
						if(AttachedComponent != none)
						{
							kWeapon.m_kPawn.UpdateMeshMaterials(AttachedComponent);
						}
					}

					PresAddItem(kItem);
				}
			}
		}
	}

	ActiveWeapon = XGWeapon(GetPrimaryItemInSlot(m_ActiveWeaponLoc));
	
	if (ActiveWeapon == none)
	{
		`log("XGInventory.ApplyInventoryOnLoad:" @ m_kOwner @ self @ "No ActiveWeapon found for" @ m_kOwner.GetPawn());
	}

	if (ActiveWeapon != none)
	{
		EquipItem(ActiveWeapon, true, true);
	}
	else
	{
		`log("XGInventory.ApplyInventoryOnLoad:" @ m_kOwner @ self @ "Nothing equipped.  Attempting to equip primary weapon for " @ m_kOwner.GetPawn());
		// Attempt to equip our primary weapon.
		EquipItem( m_kPrimaryWeapon, true, true );
	}
}

simulated function SetActiveWeapon(XGWeapon kWeapon)
{	
	`log("SetActiveWeapon:"$kWeapon,,'GameCore');
	if (kWeapon.m_eEquipLocation == kWeapon.m_eSlot)
	{
		m_ActiveWeaponLoc = kWeapon.m_eEquipLocation;
		`log("ActiveWeaponLoc:"$m_ActiveWeaponLoc,,'GameCore');
	
		m_kOwner.GetPawn().SetCurrentWeapon(XComWeapon(kWeapon.m_kEntity));

		DetermineEngagementRange();
	}
	else `log("ERROR: Trying to SetActiveWeapon that isn't in its equipped location");
}

simulated function int GetNumClips( int iWeaponType )
{
	return 1;
}

simulated function XGWeapon GetPrimaryWeapon()
{
	return m_kPrimaryWeapon;
}

simulated function XGWeapon GetSecondaryWeapon()
{
	return m_kSecondaryWeapon;
}

simulated function XGWeapon GetPrimaryWeaponForUI()
{
	if (m_kPrimaryWeapon != none)
	{
			return m_kPrimaryWeapon;
	}
	else
	{
			return m_kSecondaryWeapon;
	}
}

simulated function XGWeapon GetSecondaryWeaponForUI()
{
	local XGWeapon weap;

	if (m_kPrimaryWeapon != none)
	{
		weap = m_kSecondaryWeapon;
	}
	else
	{
		weap = m_kPrimaryWeapon;
	}

	if (weap == none)
	{   
		weap = SearchForSecondaryWeapon();
	}

	if( weap == none )
		return none;
	return weap;
}

simulated function GetLargeItems(out array<XGWeapon> arrLargeItems)
{

}

//Similate to GetLargeItems, except the weapons don't have to be eItemSize_Large
simulated function GetWeapons(out array<XGWeapon> arrWeapons)
{
	local int i;
	local XGWeapon kWeapon;

	arrWeapons[0] = m_kPrimaryWeapon;

	for( i = 0; i < Elocation.EnumCount; i++ )
	{
		kWeapon = XGWeapon(GetPrimaryItemInSlot(ELocation(i)));
		if (kWeapon != none && kWeapon != m_kPrimaryWeapon)
		{
			arrWeapons.AddItem(kWeapon);			
		}
	}
}

simulated function bool HasSomethingEquipped(ELocation eLoc)
{
	return GetPrimaryItemInSlot(eLoc) != none;
}

// MHU - Determining max weapon range, accounting for the active weapon AND weapons
//       that cannot be equipped (these are instant-use weapons; ie. sniper rifle, 
//       rocket launcher, etc where unit will switch weapons temporarily, fire, then
//       switching back).
simulated function DetermineEngagementRange()
{

}

// Drop an item from this unit's inventory
simulated function bool DropItem( XGInventoryItem kItem )
{
	PresRemoveItem(kItem);

	RemoveItemInSlot(kItem.m_eSlot);
	RemoveItemInSlot(kItem.m_eReservedSlot);
	
	kItem.m_kOwner 			= none;	

	// MHU - Inventory changed, determine new Engagement Range
	DetermineEngagementRange();

	return true;
}

// Equip item into right hand
simulated function bool EquipItem( XGInventoryItem kItem, 
								   bool bImmediate, 
								   optional bool bSkipEquipSlotChecks = false)
{
	local ELocation kEquipSlot;
	local ELocation kSlot;

	kEquipSlot = kItem.m_eEquipLocation;

	if( kItem.m_eSlot != kEquipSlot ) //Only go through the processing below if the item is changing slots
	{
		if (!bSkipEquipSlotChecks)
		{
			if( GetPrimaryItemInSlot(kEquipSlot) != none )
			{
				`log("EquipItem::kEquipSlot.m_kItem not none");
				return false;
			}
		}

		kSlot = kItem.m_eSlot;
		if( kSlot != eSlot_Grapple ) //Don't need to worry about equiping this, it's already equipped
		{		
			UnequipItemInSlot(kSlot, kItem);

			EquipItemInSlot( kEquipSlot, kItem );
		}

		SetActiveWeapon(XGWeapon(kItem));

		DetermineEngagementRange();
	}

	// Presentation Code
	PresEquip( kItem, bImmediate );

	return true;
}

// This handles the equipping of the actual 3D item/weapon
simulated function PresEquip( XGInventoryItem kItem, bool bImmediate )
{
	if( kItem.IsA('XGWeapon') )
	{
		m_kOwner.GetPawn().EquipWeapon( XComWeapon(kItem.m_kEntity), bImmediate, false );
	}
}

simulated function PresRemoveItem(XGInventoryItem kItem)
{
	if( kItem.m_kMeshComponent != none )
	{
		m_kOwner.GetPawn().DetachItem( kItem.m_kMeshComponent/*, kItem.m_kSlot.m_SocketName*/ );
	}
}

// Unequip Item from right hand, return to body
simulated function bool UnequipItem(optional bool bOverrideWithRightSling = false,
									optional bool bManualItemAttachToReservedSlot = false)
{
	local ELocation kHandSlot;
	local XGInventoryItem kItem;

	kHandSlot = m_ActiveWeaponLoc;

	kItem = GetPrimaryItemInSlot(kHandSlot);
	// IF( This unit has nothing equipped )
	if( kItem == none )
	{
		return false;
	}

	// IF( This item has no valid reserved slot to return to )
	if( kItem.m_eReservedSlot == eSlot_None )
	{
		return false;
	}

	UnequipItemInSlot(kHandSlot);

	if (bOverrideWithRightSling)
		EquipItemInSlot(eSlot_RightSling, kItem);
	else
	{
		EquipItemInSlot( kItem.m_eReservedSlot, kItem );
	}
	m_kLastEquippedItem = kItem;

	// MHU - Handle Presentation processing when
	//       there's no item attach notifies in the animation.
	if (bManualItemAttachToReservedSlot)
	{
		if( kItem.IsA('XGWeapon'))
		{
			PresRemoveItem(kItem);
			PresAddItem(kItem);
			//m_kOwner.GetPawn().UnequipWeapon( kItem );
		}
	}

	return true;
}

simulated function XGWeapon SearchForSecondaryWeapon()
{
	return none;
}

simulated function int GetNumItems(EItemType eItem)
{
	local int i, j, num;

	for (i = 0; i < ELocation.EnumCount; i++)
	{
		for (j = 0; j < GetNumberOfItemsInSlot(ELocation(i)); j++)
		{
			if (GetItemByIndexInSlot(j, ELocation(i)) != none && GetItemByIndexInSlot(j, ELocation(i)).GameplayType() == eItem)
				num++;
		}
	}
	return num;
}

simulated function string ToString()
{
	local string strRep;

	strRep = super.ToString();
	strRep $= "\n";
	strRep $= "     Unit=" $ m_kOwner.SafeGetCharacterFirstName() @ m_kOwner.SafeGetCharacterLastName() $ "\n";

	return strRep;
}

simulated function bool IsInitialReplicationComplete()
{
	return m_kOwner != none && super.IsInitialReplicationComplete();
}

simulated function SetAllInventoryLightingChannels(bool bEnableDLE, LightingChannelContainer NewLightingChannel)
{
//	local XGInventoryItem kItem;
//	local int i, j;

	//for (i = 0; i < ELocation.EnumCount; i++)
	//{
	//	for (j = 0; j < GetNumberOfItemsInSlot(ELocation(i)); j++)
	//	{
	//		kItem = GetItemByIndexInSlot(j, ELocation(i));
	//		if( kItem != none && kItem.m_kMeshComponent != none )
	//		{
	//			kItem.m_kMeshComponent.LightEnvironment.SetEnabled(bEnableDLE);
	//			kItem.m_kMeshComponent.SetLightingChannels(NewLightingChannel);
	//		}
	//	}
	//}
}

defaultproperties
{
	bTickIsDisabled=true;
	//bAlwaysRelevant = true;
	//RemoteRole=ROLE_SimulatedProxy
	RemoteRole=ROLE_None
	bAlwaysRelevant=false
}

