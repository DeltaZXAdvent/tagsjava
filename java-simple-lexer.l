// stop...
%%
WhiteSpace_ " "+
Identifier_ IdentifierChars
IdentifierChars {JavaLetter}{JavaLetterOrDigit}*
JavaLetter [A-Za-z$_]
JavaLetterOrDigit [A-Za-z$_0-9]
ReservedKeyword (abstract)|(continue))|(assert)|(default)|(boolean)|(do)|(break)|(double)|(byte)|(else)|(case)|(enum)|(catch)|(extends)|(char)|(final)|(class)|(finally)|(const)|(float)|_|(for)|(if)|(goto)|(implements)|(import)|(instanceof)|(int)|(interface)|(long)|(native)|(new)|(package)|(private)|(protected)|(public)|(return)|(short)|(static)|(strictfp)|(super)|(switch)|(synchronized)|(this)|(throw)|(throws)|(transient)|(try)|(void)|(volatile)|(while)
BooleanLiteral (true)|(false)
