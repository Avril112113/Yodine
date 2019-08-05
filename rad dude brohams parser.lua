local l = require "lpeg"
local lP, lS, lR, lCg, lCt, lV, lCc = l.P, l.S, l.R, l.Cg, l.Ct, l.V, l.Cc
local lCmt, lC = l.Cmt, l.C

local rws = lS" \t\v"^1
local ows = lS" \t\v"^0

local function insen_bool(s)
	return s:lower() == "true" or s:lower() == "false"
end

local function insen_named_func(s)
	local sl = s:lower()
	local funcs = {"abs", "sqrt", "sin", "cos",
		"tan", "arcsin", "arccos", "arctan", "not"}
	
	for _,v in ipairs(funcs) do
		if v == sl then return true end
	end
	
	return false
end

local name = (lR"az" + lR"AZ" + "_") * (lR"az" + lR"AZ" + "_" + lR"09") ^ 0
local var = lP{"var",
	ivar = lCg(lCc(false), "extern") * lCg(name, "name"),
	evar = ":" * ows * lV"ivar" * lCg(lCc(true), "extern"),
	var = lCt(lCg(lCc"var", "type") * (lV"ivar" + lV"evar"))
}
local literal = lP{"literal",
	str_raw = '"' * lCg((lP(1) - lS'"\\' + '\\"' + "\\")^0, "value") * '"',
	str = lCt(lCg(lCc"string", "type") * lV"str_raw", "value"),
	
	sign = lCg(lS"+-", "sign")^-1,
	-- Requires whole, optional decimal
	num_1 = lCg(lR"09"^1, "whole") * ("." * lCg(lR"09"^0, "dec"))^-1,
	-- Optional whole, requires decimal
	num_2 = lCg(lR"09", "whole")^-1 * ("." * lCg(lR"09"^1, "dec")),
	num = lCt(lCg(lCc"number", "type") * lV"sign" * (lV"num_1" + lV"num_2")),
	
	bool_raw = lCmt(lP(4), insen_bool) + lCmt(lP(5), insen_bool),
	bool = lCt(lCg(lCc"bool", "type") * lCg(lV"bool_raw", "value")),
	
	literal = lV"str" + lV"num" + lV"bool",
}

local expr = lP{"expr",
	direct_val = literal + var + lV"group",
	group = "(" * ows * lCg(lV"expr") * ows * ")",
	
	prec_0 = lV"direct_val",
	
	prepost_op = lCg(lP"++" + "--", "op"),
	unary_pre = lCt(lV"prepost_op" * ows * lCg(var) *
		lCg(lCc(true), "pre")),
	unary_post = lCt(lCg(var) * ows * lV"prepost_op" *
		lCg(lCc(false), "pre")),
	prec_1 = lV"unary_post" + lV"unary_pre" + lV"prec_0",
	
	neg = lCt("-" * lCg(lCc"neg", "op") * ows * lCg(lV"prec_1")),
	prec_2 = lV"neg" + lV"prec_1",
	
	fact1 = lCt(lCg(lV"prec_2") * ows * lCg(lP"!", "op")),
	fact2 = lCt(lCg(lV"fact1") * ows * lCg(lP"!", "op")),
	prec_3 = lV"fact2" + lV"fact1" + lV"prec_2",
	      
	named = lCt(lCg(lCmt(name, insen_named_func), "op") * ows *
	        lCg(lV"prec_3")),
	prec_4 = lV"named" + lV"prec_3",
	      
	exp = lCt((lCg(lV"prec_4") * ows * lCg("^") * ows)^1 *
	        lCg(lV"prec_4") * lCg(lCc"exp", "op")),
	prec_5 = lV"exp" + lV"prec_4",
	      
	mul = lCt((lCg(lV"prec_5") * ows * lCg(lS"*/%") * ows)^1 *
	        lCg(lV"prec_5") * lCg(lCc"mul", "op")),
	prec_6 = lV"mul" + lV"prec_5",
	
	add = lCt((lCg(lV"prec_6") * ows * lCg(lS"+-") * ows)^1 *
		lCg(lV"prec_6") * lCg(lCc"add", "op")),
	prec_7 = lV"add" + lV"prec_6",
	
	neq_op = (lS"<>" * "=") + lS"<>",
	neq = lCt((lCg(lV"prec_7") * ows * lCg(lV"neq_op") * ows)^1 *
		lCg(lV"prec_7") * lCg(lCc"neq", "op")),
	prec_8 = lV"neq" + lV"prec_7",
	
	eq_op = lS"!=" * "=",
	eq = lCt((lCg(lV"prec_8") * ows * lCg(lV"eq_op") * ows)^1 *
		lCg(lV"prec_8") * lCg(lCc"eq", "op")),
	prec_9 = lV"eq" + lV"prec_8",
	
	or_op = ows * lCg(lS"oO" * lS"rR") * ows,
	orexpr = lCt(lCg(lV"prec_9") * (lV"or_op" * lCg(lV"prec_9"))^1),
	prec_10 = lV"orexpr" + lV"prec_9",
	
	and_op = ows * lCg(lS"aA" * lS"nN" * lS"dD") * ows,
	andexpr = lCt(lCg(lV"prec_10") * (lV"and_op" * lCg(lV"prec_10"))^1),
	prec_11 = lV"andexpr" + lV"prec_10",
	
	expr = lV"prec_11"
}

local statement = lP{"stmt",
	assignop = lCg(lS"+-*/%"^-1 * "=", "op") * lCg(lCc"compass", "type"),
	assign = lCt(lCg(var) * ows * lV"assignop" * ows * lCg(expr)),
	
	body = lCt((lV"stmt" * rws)^0 * lV"stmt"),
	if_ins = lCg(lS"iI" * lS"fF", "if_op") * lCg(lCc"ifstmt", "type") * rws,
	then_ins = lCg(lS"tT" * lS"hH" * lS"eE" * lS"nN", "then_op") * rws,
	end_ins = lCg(lS"eE" * lS"nN" * lS"dD", "end_op"),
	if_op = lCt(lV"if_ins" * lCg(expr, "cond") * lV"then_ins" * lV"body" *
		lV"end_ins"),
	
	goto_ins = lCg(lS"gG" * lS"oO" * lS"tT" * lS"oO", "goto_op") * rws,
	goto_op = lCt(lV"goto_ins" * lCg(lCc("gotostmt", "type")) *
		lCg(expr, "whereto")),
	
	stmt = ows * (lV"assign" + lV"if_op" + lV"goto_op" + expr),
}

local script = lCt((statement * rws)^0 * statement)

return function(text)
	return script:match(text)
end
