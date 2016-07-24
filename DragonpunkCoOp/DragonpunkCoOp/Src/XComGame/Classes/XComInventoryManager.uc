class XComInventoryManager extends InventoryManager;

//////////////////////////////////////////////////////////////////////////////////////////////
// BEGIN taken from InventoryManager to override and prevent destroying/none'ing of Inventory. 
//       This was causing Weapons to disappear when a pawn died. -tsmith 
//////////////////////////////////////////////////////////////////////////////////////////////
/**
 * Attempts to remove an item from the inventory list if it exists.
 *
 * @param	Item	Item to remove from inventory
 */
simulated function RemoveFromInventory(Inventory ItemToRemove)
{
	//local Inventory Item;
	//local bool		bFound;

	//if( ItemToRemove != None )
	//{
	//	if( InventoryChain == ItemToRemove )
	//	{
	//		bFound = TRUE;
	//		InventoryChain = ItemToRemove.Inventory;
	//	}
	//	else
	//	{
	//		// If this item is in our inventory chain, unlink it.
	//		for(Item = InventoryChain; Item != None; Item = Item.Inventory)
	//		{
	//			if( Item.Inventory == ItemToRemove )
	//			{
	//				bFound = TRUE;
	//				Item.Inventory = ItemToRemove.Inventory;
	//				break;
	//			}
	//		}
	//	}

	//	if( bFound )
	//	{
	//		`LogInv("removed" @ ItemToRemove);
	//		ItemToRemove.ItemRemovedFromInvManager();
	//		// NOTE: never, ever, ever destroy or none the inventory because we need them to exist, this is why sometimes weapons would disappear when a pawn died. -tsmith 
	//		//ItemToRemove.SetOwner(None);
	//		ItemToRemove.Inventory = None;
	//	}

	//	// make sure we don't have other references to the item
	//	if( ItemToRemove == Instigator.Weapon )
	//	{
	//		// NOTE: never, ever, ever destroy or none the inventory because we need them to exist, this is why sometimes weapons would disappear when a pawn died. -tsmith 
	//		//Instigator.Weapon = None;
	//	}

	//	if( Instigator.Health > 0 && Instigator.Weapon == None && Instigator.Controller != None )
	//	{
	//		`LogInv("Calling ClientSwitchToBestWeapon");
	//		Instigator.Controller.ClientSwitchToBestWeapon(TRUE);
	//	}
	//}
}

/**
 * Discard full inventory, generally because the owner died
 */
simulated event DiscardInventory()
{
	//local Inventory	Inv;
	//local vector	TossVelocity;
	//local bool		bBelowKillZ;

	//`LogInv("");

	//// don't drop any inventory if below KillZ or out of world
	//bBelowKillZ = (Instigator == None) || (Instigator.Location.Z < WorldInfo.KillZ);

	//ForEach InventoryActors(class'Inventory', Inv)
	//{
	//	if( Inv.bDropOnDeath && !bBelowKillZ )
	//	{
	//		TossVelocity = vector(Instigator.GetViewRotation());
	//		TossVelocity = TossVelocity * ((Instigator.Velocity dot TossVelocity) + 500.f) + 250.f * VRand() + vect(0,0,250);
	//		Inv.DropFrom(Instigator.Location, TossVelocity);
	//	}
	//	else
	//	{
	//		// NOTE: never, ever, ever destroy or none the inventory because we need them to exist, this is why sometimes weapons would disappear when a pawn died. -tsmith 
	//		//Inv.Destroy();
	//	}
	//}

	//// Clear reference to Weapon
	//Instigator.Weapon = None;

	//// Clear reference to PendingWeapon
	//PendingWeapon = None;
}

/**
 * Spawns a new Inventory actor of NewInventoryItemClass type, and adds it to the Inventory Manager.
 * @param	NewInventoryItemClass		Class of inventory item to spawn and add.
 * @return	Inventory actor, None if couldn't be spawned.
 */
simulated function Inventory CreateInventory(class<Inventory> NewInventoryItemClass, optional bool bDoNotActivate)
{
	//local Inventory	Inv;

	//if( NewInventoryItemClass != None )
	//{
	//	inv = Spawn(NewInventoryItemClass, Owner);
	//	if( inv != None )
	//	{
	//		if( !AddInventory(Inv, bDoNotActivate) )
	//		{
	//			`warn("InventoryManager::CreateInventory - Couldn't Add newly created inventory" @ Inv);
	//		    // NOTE: never, ever, ever destroy or none the inventory because we need them to exist, this is why sometimes weapons would disappear when a pawn died. -tsmith 
	//			Inv.Destroy();
	//			Inv = None;
	//		}
	//	}
	//	else
	//	{
	//		`warn("InventoryManager::CreateInventory - Couldn't spawn inventory" @ NewInventoryItemClass);
	//	}
	//}

	//return Inv;

	return none;
}
//////////////////////////////////////////////////////////////////////////////////////////////
// END taken from InventoryManager to override and prevent destroying/none'ing of Inventory. 
//     This was causing Weapons to disappear when a pawn died. -tsmith 
//////////////////////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	PendingFire(0)=0
	PendingFire(1)=0
}