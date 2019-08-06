local _parse = require "yolol.parse"
return {
	tests=require "yolol.tests.init",
	parse=_parse.parse,
	defs=_parse.defs
}
