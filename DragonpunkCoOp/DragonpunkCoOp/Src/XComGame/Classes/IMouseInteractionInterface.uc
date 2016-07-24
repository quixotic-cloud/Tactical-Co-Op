interface IMouseInteractionInterface;

//Handle the incoming mouse event
function bool OnMouseEvent(    int cmd, 
							   int Actionmask, 
							   optional Vector MouseWorldOrigin, 
							   optional Vector MouseWorldDirection, 
							   optional Vector HitLocation);
/*
 * 
// *****   TODO: Fill in these function later if we need them? -bsteiner   ********


// Called when the left mouse button is pressed
function bool MouseLeftPressed(Vector MouseWorldOrigin, Vector MouseWorldDirection, Vector HitLocation, Vector HitNormal);

// Called when the left mouse button is released
function bool MouseLeftReleased(Vector MouseWorldOrigin, Vector MouseWorldDirection);

// Called when the right mouse button is pressed
function bool MouseRightPressed(Vector MouseWorldOrigin, Vector MouseWorldDirection, Vector HitLocation, Vector HitNormal);

// Called when the right mouse button is released
function bool MouseRightReleased(Vector MouseWorldOrigin, Vector MouseWorldDirection);

// Called when the middle mouse button is pressed
function bool MouseMiddlePressed(Vector MouseWorldOrigin, Vector MouseWorldDirection, Vector HitLocation, Vector HitNormal);

// Called when the middle mouse button is released
function bool MouseMiddleReleased(Vector MouseWorldOrigin, Vector MouseWorldDirection);

// Called when the middle mouse button is scrolled up
function bool MouseScrollUp(Vector MouseWorldOrigin, Vector MouseWorldDirection);

// Called when the middle mouse button is scrolled down
function bool MouseScrollDown(Vector MouseWorldOrigin, Vector MouseWorldDirection);

// Called when the mouse is moved over the actor
function bool MouseOver(Vector MouseWorldOrigin, Vector MouseWorldDirection);

// Called when the mouse is moved out from the actor (when it was previously over it)
function bool MouseOut(Vector MouseWorldOrigin, Vector MouseWorldDirection);

// Returns the hit location of the mouse trace
function Vector GetHitLocation();

// Returns the hit normal of the mouse trace
function Vector GetHitNormal();

// Returns the mouse world origin calculated by the deprojection within the canvas
function Vector GetMouseWorldOrigin();

// Returns the mouse world direction calculated by the deprojection within the canvas
function Vector GetMouseWorldDirection();
*/