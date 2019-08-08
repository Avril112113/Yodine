---@type fun(name:string,f:function):nil
local pushTest = pushTest
---@type fun(codeStr:string):ParseResult
local parse = parse
---@type YDEFS
local defs = defs

---@type fun(codeStr:string,expectedAST:YAST_Program,name:string):boolean
local checkAST = checkAST

---@vararg table
local function astLines(...)
	local lines = {}
	for i, v in pairs({...}) do
		table.insert(lines, {
			type="line",
			code=v
		})
	end
	return {
		type="program",
		lines=lines
	}
end

pushTest("math", function()
	local ok = true
	ok = checkAST("2+2*2-1^3", astLines({
		{
			type="add",
			left={
				type="number",
				num="2"
			},
			right={
				type="add",
				left={
					type="mul",
					left={
						type="number",
						num="2"
					},
					right={
						type="number",
						num="2"
					},
					operator="*"
				},
				right={
					type="exp",
					left={
						type="number",
						num="1"
					},
					right={
						type="number",
						num="3"
					},
					operator="^"
				},
				operator="-"
			},
			operator="+"
		}
	}), "math") and ok
	ok = checkAST("1 and 1 or 0 == 1 != 0 > 0 <= 1 < 2 >= -1", astLines({
		{
			type="add",
			left={
				type="number",
				num="2"
			},
			right={
				type="add",
				left={
					type="mul",
					left={
						type="number",
						num="2"
					},
					right={
						type="number",
						num="2"
					},
					operator="*"
				},
				right={
					type="exp",
					left={
						type="number",
						num="1"
					},
					right={
						type="number",
						num="3"
					},
					operator="^"
				},
				operator="-"
			},
			operator="+"
		}
	}), "boolean math") and ok
	-- TODO
	-- ok = checkAST("y=x!=12 y=x!!=12 y=x!==12", astLines({}), "factorial math") and ok
	return ok
end)
