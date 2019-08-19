-- This file is dedicated to providing typing info using EmmyLua
-- and is only used when the types can no be spesified in existing code


---@class ParseResult
local ParseResult = {
	---@type YAST_Program|nil
	ast=nil,
	---@type number
	totalParseTime=nil
}

---@class YAST_Program
local YAST_Program = {
	type="program",
	---@type YAST_Line[]
	lines=nil
}

---@class YAST_Line
local YAST_Line = {
	type="line",
	---@type any[]
	code=nil,
	---@type table
	errors=nil,
	---@type string|nil
	errMsg=nil,
	---@type number|nil
	errPos=nil,
	---@type number
	parseTime=nil
}
