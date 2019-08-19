local _parse = require "yolol.parse"
return {
	tests=require "yolol.tests.init",
	parse=_parse.parse,
	parseLine=_parse.parseLine,
	defs=_parse.defs
}
