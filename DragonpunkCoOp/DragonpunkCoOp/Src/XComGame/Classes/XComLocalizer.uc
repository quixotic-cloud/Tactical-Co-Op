class XComLocalizer extends Object
	native(Core);

/*
* Tokenize the string. Given "Sometext <With:Tag/> MoreText", the resulting
* tokens would be "Sometext", "<With:Tag/>", and "MoreText". Any escape chacaters
* are removed.
*/
private static native function EscapeAndTokenize(out array<string> OutTokens, string InString);
private static native function bool ExtractTag(string InString, out string TagName, out string OptName, out int ExtraOptions);
native static function string ExpandString(string StringToExpand);