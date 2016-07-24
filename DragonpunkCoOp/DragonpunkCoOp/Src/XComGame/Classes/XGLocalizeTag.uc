class XGLocalizeTag extends Object native(Core);

var string Tag;
var XGTacticalGameCoreNativeBase m_kGameCore;

native function GetTacticalGameCore();
native function bool Expand(string InString, out string OutString);