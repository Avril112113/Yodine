local _parse = require "yolol.parse"
local helpers = require "yolol.tests.helpers"
local re = require "relabel"

local tests
---@param name string
---@param f function
local function pushTest(name, f)
	tests[name] = f
end
local function checkAST(codeStr, expectedAST, name)
	name = name or "<NO_NAME>"
	local result = _parse.parse(codeStr .. "\n")
	if result.errMsg ~= nil then
		if result.errPos ~= nil then
			local ln, col = re.calcline(codeStr, result.errPos)
			print("Failed at " .. tostring(ln) .. ":" .. tostring(col) .. " with")
			print(_parse.defs[result.errMsg])
		end
		return false
	else
		local ok = helpers.tblEqual(expectedAST, result.ast)
		if not ok then
			print("checkAST failed test " .. name .. " with the following difference's")
			helpers.printAST(result.ast)
			helpers.printAST(expectedAST)
			helpers.tblPrint(expectedAST, result.ast)
		end
		return ok
	end
end

local testEnv = setmetatable({
	pushTest=pushTest,
	parse=_parse.parse,
	defs=_parse.defs,

	checkAST=checkAST
}, {__index=_G})
---@param path string
local function loadFileOfTests(path)
	setfenv(assert(loadfile(path)), testEnv)()
end

local function loadTests()
	tests = {}
	loadFileOfTests("yolol/tests/math.lua")
end

local function runTest(name)
	if tests == nil then
		loadTests()
	end
	print("Running test " .. name .. "...")
	local ok = tests[name]()
	if ok == nil then
		print("Test was run. (Test is missing a return)")
	elseif ok then
		print("Test was successful.")
	else
		print("Test failed.")
	end
	return ok
end
local function runAllTests()
	if tests == nil then
		loadTests()
	end
	for i, _ in pairs(tests) do
		runTest(i)
	end
end

return {
	tests=tests,
	loadTests=loadTests,
	runTest=runTest,
	runAllTests=runAllTests
}
