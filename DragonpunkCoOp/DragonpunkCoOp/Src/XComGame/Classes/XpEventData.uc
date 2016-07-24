class XpEventData extends Object native(Core);

var StateObjectReference    XpEarner;
var StateObjectReference    EventTarget;

static function XpEventData NewXpEventData(StateObjectReference kXpEarner, StateObjectReference kEventTarget)
{
	local XpEventData EventData;

	EventData = new(class'X2EventManager'.static.GetEventManager()) class'XpEventData';
	EventData.XpEarner = kXpEarner;
	EventData.EventTarget = kEventTarget;
	return EventData;
}