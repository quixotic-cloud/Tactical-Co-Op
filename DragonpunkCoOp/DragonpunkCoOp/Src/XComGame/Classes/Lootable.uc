/**
 * Lootable interface provides functions for getting new or existing items out of an object.
 */

interface Lootable
	dependson(XComGameStateVisualizationMgr);

/**
 * HasAvailableLoot
 * Return true if there is loot to be looted.
 */
simulated event bool HasLoot();

/**
 * HasAvailableLoot
 * Return true if there is loot available to be looted. It's possible the loot could be there but not accessible,
 * for example if it is in a locked chest.
 */
simulated event bool HasAvailableLoot();

/**
 * MakeAvailableLoot
 * Create any uncreated loot and return a reference to your own new state.
 */
function Lootable MakeAvailableLoot(XComGameState ModifyGameState);

/**
 * GetAvailableLoot
 * Returns all items currently available on the Lootable object.
 */
function array<StateObjectReference> GetAvailableLoot();

/**
 * GetLoot
 * Remove item from Lootable object and place in Looter's backpack.
 */
function bool GetLoot(StateObjectReference ItemRef, StateObjectReference LooterRef, XComGameState ModifyGameState);

/**
 * LeaveLoot
 * Remove item from Looter's backpack and place in Lootable object.
 */
function bool LeaveLoot(StateObjectReference ItemRef, StateObjectReference LooterRef, XComGameState ModifyGameState);

/**
* AddLoot
* Adds a new item unconditionally to this lootable object.
*/
function AddLoot(StateObjectReference ItemRef, XComGameState ModifyGameState);

/**
* RemoveLoot
* Removes an item unconditionally from this lootable object.
*/
function RemoveLoot(StateObjectReference ItemRef, XComGameState ModifyGameState);

/**
 * GetLootingName
 * Returns a localized string which can be displayed to the player when looting.
 */
function string GetLootingName();

/**
 * GetLootLocation
 * Returns tile where the Lootable object resides.
 */
simulated function TTile GetLootLocation();

function VisualizeLootFountain(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks);

/**
* UpdateLootSparklesEnabled
* Force a visualizer update to match the current lootable state of this object.
*/
function UpdateLootSparklesEnabled(bool bHighlightObject);