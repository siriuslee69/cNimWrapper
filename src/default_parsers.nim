# This module wires together the default parse order <- handled by buildDefaultRegistry().
# It registers parsers for concrete C forms in this order <- handled by buildDefaultRegistry():
# preprocessor (non-define/include), extern "C", #define, #include,
# static const, enum, macro-wrapped struct, struct, typedef, function prototype.
import parser_core
import define_parser
import enum_parser
import extern_parser
import function_parser
import include_parser
import macro_struct_parser
import preprocessor_parser
import static_const_parser
import struct_parser
import typedef_parser

proc buildDefaultRegistry*(): ParserRegistry =
  ## returns the default parser registry
  ## Registers the standard parsers in the preferred order.
  var
    reg: ParserRegistry = initRegistry()
  addParser(reg, tryParsePreprocessorDirective)
  addParser(reg, tryParseExternBlock)
  addParser(reg, tryParseExternClose)
  addParser(reg, tryParseDefine)
  addParser(reg, tryParseInclude)
  addParser(reg, tryParseStaticConst)
  addParser(reg, tryParseEnum)
  addParser(reg, tryParseMacroWrappedStruct)
  addParser(reg, tryParseStruct)
  addParser(reg, tryParseTypedef)
  addParser(reg, tryParseFunction)
  result = reg
