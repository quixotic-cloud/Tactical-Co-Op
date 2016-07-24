/**
 * HiddenOnMap interface provides functions for hiding and unhiding items on the strategy map
 * Used for map elements that are revealed through scanning only
 */

interface HiddenOnMap;

/**
 * InitHideValues
 * Sets the initial values for relevant hide vars
 */
function InitHideValues(XComGameState NewGameState);

/**
 * IsHidden
 * Return true if item is hidden on the strategy map
 */
function bool IsHidden();

/**
 * Unhide
 * Unhide the item on the strategy map
 */
function Unhide(XComGameState NewGameState);

/**
 * UnhiddenNotification
 * Popup or message when item is unhidden.
 */
function UnhiddenNotification();

/**
 * StartUnhideTimer
 * Call when starting to scan a region
 */
function StartUnhideTimer(XComGameState NewGameState);

/**
 * PauseUnhideTimer
 * Call when stopping scanning a region
 */
function PauseUnhideTimer(XComGameState NewGameState);

/**
 * ResetUnhideTimer
 * Call when Avenger leaves the item's region
 */
function ResetUnhideTimer(XComGameState NewGameState);

/**
 * UnhideTimerComplete
 * Returns true when the unhide timer is complete
 */
function bool UnhideTimerComplete();

/**
 * AvengerInRegion
 * Returns true when the Avenger is in the item's region
 */
function bool AvengerInRegion();