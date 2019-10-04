return {
	unaryOpData={
		
	},
	binaryOpData = {
		-- ["OPERATOR"]={Precedence, RightAssoc, TypeName}
		["^"]={7, true, "exp"},
		["*"]={6, false, "mul"},
		["/"]={6, false, "mul"},
		["%"]={6, false, "mul"},
		["+"]={5, false, "add"},
		["-"]={5, false, "add"},
		["<"]={4, false, "neq"},
		[">"]={4, false, "neq"},
		["<="]={4, false, "neq"},
		[">="]={4, false, "neq"},
		["!="]={3, false, "eq"},
		["=="]={3, false, "eq"},
		["or"]={2, false, "or"},
		["and"]={1, true, "and"},
	}
}
