local lyaml = require "lyaml"
lyaml.functional = require "lyaml.functional"
lyaml.implicit = require "lyaml.implicit"
lyaml.explicit = require "lyaml.explicit"

return {
	explicit_scalar = {
		["tag:yaml.org,2002:bool"] = lyaml.explicit.bool,
		["tag:yaml.org,2002:float"] = lyaml.explicit.float,
		["tag:yaml.org,2002:int"] = lyaml.explicit.int,
		["tag:yaml.org,2002:null"] = lyaml.explicit.null,
		["tag:yaml.org,2002:str"] = lyaml.explicit.str,
	},
	implicit_scalar = lyaml.functional.anyof {
		lyaml.implicit.null,
		lyaml.implicit.octal,
		lyaml.implicit.decimal,
		lyaml.implicit.float,
		lyaml.implicit.bool,
		lyaml.implicit.inf,
		lyaml.implicit.nan,
		lyaml.implicit.hexadecimal,
		lyaml.implicit.binary,
		lyaml.implicit.sexagesimal,
		lyaml.implicit.sexfloat,
		lyaml.functional.id,
	}
}
