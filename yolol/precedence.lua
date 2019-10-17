return {
	unaryOpData={
		-- ["OPERATOR"]={Precedence, TypeName}
	},
	binaryOpData = {
		-- ["OPERATOR"]={Precedence, TypeName, RightAssoc}
		["^"]={7, "expression::binary_op", true},
		["*"]={6, "expression::binary_op", false},
		["/"]={6, "expression::binary_op", false},
		["%"]={6, "expression::binary_op", false},
		["+"]={5, "expression::binary_op", false},
		["-"]={5, "expression::binary_op", false},
		["<"]={4, "expression::binary_op", false},
		[">"]={4, "expression::binary_op", false},
		["<="]={4, "expression::binary_op", false},
		[">="]={4, "expression::binary_op", false},
		["!="]={3, "expression::binary_op", false},
		["=="]={3, "expression::binary_op", false},
		["or"]={2, "expression::binary_op", false},
		["and"]={1, "expression::binary_op", false},
	}
}
