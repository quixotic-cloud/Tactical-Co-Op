/**
 * Hackable interface provides functions for hacking an object.
 */

interface Hackable;

/**
* GetHackRewards
* Returns all hack reward templates currently available on the Hackable object.
*/
function array<Name> GetHackRewards(Name HackAbilityName);

/**
* GetHackRewardRollMods
* Returns the current set of roll mods applied to the Hackable object.
*/
function array<int> GetHackRewardRollMods();

/**
* SetHackRewardRollMods
* Sets the RollMods for this Hackable.
*/
function SetHackRewardRollMods(const out array<int> RollMods);

function bool HasBeenHacked();

function int GetUserSelectedHackOption();