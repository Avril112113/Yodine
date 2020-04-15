-- Adapted from https://github.com/gvvaughan/lyaml/blob/master/lib/lyaml/init.lua
local yaml = require "yaml"
local lyaml = require "lyaml"
lyaml.functional = require "lyaml.functional"
lyaml.implicit = require "lyaml.implicit"
lyaml.explicit = require "lyaml.explicit"

local default = require "DYaml.default"


local YamlLoader = {}
YamlLoader.__index = YamlLoader


function YamlLoader.default_unhandled_tag(tag, value)
	print("WARNING: unhandled tag '" .. tag .. "'")
end


function YamlLoader.load(s, opts)
	local documents = {}
	opts = opts or {}

	local parser = YamlLoader.new(s, opts)

	if parser:parse() ~= "STREAM_START" then
		error("expecting STREAM_START event, but got " .. parser:type(), 2)
	end

	while parser:parse() ~= "STREAM_END" do
		local document = parser:load_node()
		if document == nil then
			error("unexpected " .. parser:type() .. " event")
		end

		if parser:parse() ~= "DOCUMENT_END" then
			error("expecting DOCUMENT_END event, but got " .. parser:type(), 2)
		end

		-- save document
		documents[#documents + 1] = document

		-- reset anchor table
		parser.anchors = {}
	end

	return (opts.all == nil or opts.all) and documents or documents[1]
end

-- Parser object constructor.
function YamlLoader.new(s, opts)
	local object = {
		anchors = {},
		explicit_scalar = opts.explicit_scalar or default.explicit_scalar,
		mark = {line=0, column=0},
		next = yaml.parser(s),
		tags = opts.tags or {},
		unhandled_tag = opts.unhandled_tag or YamlLoader.default_unhandled_tag
	}
	return setmetatable(object, YamlLoader)
end

-- Return the type of the current event.
function YamlLoader:type()
	return tostring(self.event.type)
end

-- Raise a parse error.
function YamlLoader:error(errmsg, ...)
	error(string.format("%d:%d: " .. errmsg, self.mark.line,
					 self.mark.column, ...), 0)
end

-- We save anchor types that will match the node type from expanding
-- an alias for that anchor.
local alias_type = {
	MAPPING_END = "MAPPING_END",
	MAPPING_START = "MAPPING_END",
	SCALAR = "SCALAR",
	SEQUENCE_END = "SEQUENCE_END",
	SEQUENCE_START = "SEQUENCE_END",
}
-- Save node in the anchor table for reference in future ALIASes.
function YamlLoader:add_anchor(node)
	if self.event.anchor ~= nil then
		self.anchors[self.event.anchor] = {
			type = alias_type[self.event.type],
			value = node,
		}
	end
end

-- Fetch the next event.
function YamlLoader:parse()
	local ok, event = pcall(self.next)
	if not ok then
		-- if ok is nil, then event is a parser error from libYAML
		self:error(string.gsub(event, " at document: .*$", ""))
	end
	self.event = event
	self.mark = {
		line = self.event.start_mark.line + 1,
		column = self.event.start_mark.column + 1,
	}
	return self:type()
end

-- Construct a Lua hash table from following events.
function YamlLoader:load_map()
	local tag = self.event.tag
	local map = {}
	self:add_anchor(map)
	while true do
		local key = self:load_node()
		local tag = self.event.tag
		if tag then
			tag = string.match(tag, "^tag:yaml.org,2002:(.*)$")
		end
		if key == nil then
			break
		end
		if key == "<<" or tag == "merge" then
			tag = self.event.tag or key
			local node, event = self:load_node()
			if event == "MAPPING_END" then
				for k, v in pairs(node) do
					if map[k] == nil then
						map[k] = v
					end
				end

			elseif event == "SEQUENCE_END" then
				for i, merge in ipairs(node) do
					if type(merge) ~= "table" then
						self:error("invalid '%s' sequence element %d: %s",
							tag, i, tostring(merge))
					end
					for k, v in pairs(merge) do
						if map[k] == nil then
							map[k] = v
						end
					end
				end

			else
				if event == "SCALAR" then
					event = tostring(node)
				end
				self:error("invalid '%s' merge event: %s", tag, event)
			end
		else
			local value, event = self:load_node()
			if value == nil then
				self:error("unexpected %s event", self:type())
			end
			map[key] = value
		end
	end
	map = self:load_tagged(tag, map)
	return map, self:type()
end

-- Construct a Lua array table from following events.
function YamlLoader:load_sequence()
	local tag = self.event.tag
	local sequence = {}
	self:add_anchor(sequence)
	while true do
		local node = self:load_node()
		if node == nil then
			break
		end
		sequence[#sequence + 1] = node
	end
	sequence = self:load_tagged(tag, sequence)
	return sequence, self:type()
end

-- Construct a primitive type from the current event.
function YamlLoader:load_scalar()
	local value = self.event.value
	local tag = self.event.tag
	local explicit = self.explicit_scalar[tag]

	-- Explicitly tagged values.
	if explicit then
		value = explicit(value)
		if value == nil then
			self:error("invalid '%s' value: '%s'", tag, self.event.value)
		end

	-- Otherwise, implicit conversion according to value content.
	elseif self.event.style == "PLAIN" then
		value = default.implicit_scalar(self.event.value)
	end
	self:add_anchor(value)
	value = self:load_tagged(tag, value)
	return value, self:type()
end

function YamlLoader:load_alias()
	local anchor = self.event.anchor
	local event = self.anchors[anchor]
	if event == nil then
		self:error("invalid reference: %s", tostring(anchor))
	end
	return event.value, event.type
end

function YamlLoader:load_node()
	local dispatch = {
		SCALAR = self.load_scalar,
		ALIAS = self.load_alias,
		MAPPING_START = self.load_map,
		SEQUENCE_START = self.load_sequence,
		MAPPING_END = function() end,
		SEQUENCE_END = function() end,
		DOCUMENT_END = function() end
	}

	local event = self:parse()
	if dispatch[event] == nil then
		self:error("invalid event: %s", self:type())
	end
	return dispatch[event](self)
end

function YamlLoader:load_tagged(tag, node)
	if tag == nil then return node end
	local tagHandler = self.tags[tag]
	if tag:gsub("^tag:yaml.org", "") ~= tag then return node end
	if tagHandler == nil then
		local value = self.unhandled_tag(tag, node)
		if value == nil then return node end
		return value
	end
	return tagHandler.deserialize(node)
end


return YamlLoader
