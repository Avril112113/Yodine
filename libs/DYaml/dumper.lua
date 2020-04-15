-- Adapted from https://github.com/gvvaughan/lyaml/blob/master/lib/lyaml/init.lua
local yaml = require "yaml"
local lyaml = require "lyaml"
lyaml.functional = require "lyaml.functional"
lyaml.implicit = require "lyaml.implicit"
lyaml.explicit = require "lyaml.explicit"

local default = require "DYaml.default"


local YamlDumper = {}
YamlDumper.__index = YamlDumper

function YamlDumper.dump(documents, opts)
	local dumper = YamlDumper.new(opts or {})

	dumper:emit {type="STREAM_START", encoding="UTF8"}
	for _, document in ipairs(documents) do
		dumper:dump_document(document)
	end
	local ok, stream = dumper:emit {type="STREAM_END"}
	return stream
end

function YamlDumper.new(opts)
	local anchors = {}
	if opts.anchors ~= nil then
		for k, v in pairs(opts.anchors) do
			anchors[v] = k
		end
	end
	local self = {
		aliased = {},
		anchors = anchors,
		emitter = yaml.emitter(),
		tags = opts.tags or {}
	}
	return setmetatable(self, YamlDumper)
end

-- Emit EVENT to the LibYAML emitter.
function YamlDumper:emit(event)
	return self.emitter.emit(event)
end

-- Look up an anchor for a repeated document element.
function YamlDumper:get_anchor(value)
	local r = self.anchors[value]
	if r then
		self.aliased[value], self.anchors[value] = self.anchors[value], nil
	else
		local vmt = getmetatable(value)
		if vmt ~= nil and vmt.__yaml_anchor ~= nil then
			r = vmt.__yaml_anchor
			self.aliased[value] = r
		end
	end
	return r
end

-- Look up an already anchored repeated document element.
function YamlDumper:get_alias(value)
	return self.aliased[value]
end

-- Dump ALIAS into the event stream.
function YamlDumper:dump_alias(alias)
	return self:emit {
		type = "ALIAS",
		anchor = alias,
	}
end

-- Dump MAP into the event stream.
function YamlDumper:dump_mapping(map)
	local alias = self:get_alias(map)
	if alias then
		return self:dump_alias(alias)
	end

	local anchor = self:get_anchor(map)
	local tag
	map, tag = self:get_tagged(map)
	self:emit {
		type = "MAPPING_START",
		anchor = anchor,
		style = "BLOCK",
		tag = tag,
		implicit = false
	}
	local mmt = getmetatable(map)
	local order_table = mmt and mmt.__yaml_order
	if order_table then
		local ordered_map = {}
		for k, v in pairs(map) do
			table.insert(ordered_map, {k=k, v=v})
		end
		table.sort(ordered_map, function(kv1, kv2)
			return (order_table[kv1.k] or -1) > (order_table[kv2.k] or -1)
		end)
		for _, kv in ipairs(ordered_map) do
			self:dump_node(kv.k)
			self:dump_node(kv.v)
		end
	else
		for k, v in pairs(map) do
			self:dump_node(k)
			self:dump_node(v)
		end
	end
	return self:emit {type="MAPPING_END"}
end

-- Dump SEQUENCE into the event stream.
function YamlDumper:dump_sequence(sequence)
	local alias = self:get_alias(sequence)
	if alias then
		return self:dump_alias(alias)
	end

	local anchor = self:get_anchor(sequence)
	local tag
	sequence, tag = self:get_tagged(sequence)
	self:emit {
		type   = "SEQUENCE_START",
		anchor = anchor,
		style  = "BLOCK",
		tag = tag,
		implicit = false
	}
	for _, v in ipairs(sequence) do
		self:dump_node(v)
	end
	return self:emit {type="SEQUENCE_END"}
end

-- Dump a null into the event stream.
function YamlDumper:dump_null()
	return self:emit {
		type = "SCALAR",
		value = "~",
		plain_implicit = true,
		quoted_implicit = true,
		style = "PLAIN",
	}
end

-- Dump VALUE into the event stream.
function YamlDumper:dump_scalar(value)
	local alias = self:get_alias(value)
	if alias then
		return self:dump_alias(alias)
	end

	local anchor = self:get_anchor(value)
	local tag
	value, tag = self:get_tagged(value)
	local itsa = type(value)
	local style = "PLAIN"
	if itsa == "string" and default.implicit_scalar(value) ~= value then
		-- take care to round-trip strings that look like scalars
		style = "SINGLE_QUOTED"
	elseif value == math.huge then
		value = ".inf"
	elseif value == -math.huge then
		value = "-.inf"
	elseif value ~= value then
		value = ".nan"
	elseif itsa == "number" or itsa == "boolean" then
		value = tostring(value)
	elseif itsa == "string" and string.find(value, "\n") then
		style = "LITERAL"
	end
	return self:emit {
		type = "SCALAR",
		anchor = anchor,
		tag = tag,
		value = value,
		-- TODO: fix lyaml to actually use thes 2 fields, lyaml never gets these values
		-- https://github.com/gvvaughan/lyaml/issues/36
		plain_implicit = true,
		quoted_implicit = true,
		style = style,
	}
end

function YamlDumper:get_tagged(node)
	local yamlTagStr
	for name, tag in pairs(self.tags) do
		if tag.check(node) then
			node = tag.serialize(node)
			local nodeType = type(node)
			if nodeType == "string" or nodeType == "boolean" or nodeType == "number" then
				print("WARNING: bug in lyaml prevents tags on scalars. A " .. nodeType .. " was returned from " .. name .. ".serialize()")
			end
			yamlTagStr = name
			break
		end
	end
	local nmt = getmetatable(node)
	if nmt ~= nil and nmt.__yaml_tag ~= nil then
		yamlTagStr = nmt.__yaml_tag
	end
	return node, yamlTagStr
end

-- Decompose NODE into a stream of events.
function YamlDumper:dump_node(node)
	local itsa = type(node)
	if lyaml.functional.isnull(node) then
		return self:dump_null()
	elseif itsa == "string" or itsa == "boolean" or itsa == "number" then
		return self:dump_scalar(node)
	elseif itsa == "table" then
		local nmt = getmetatable(node) or {}
		if (nmt.__yaml_mapping == nil and #node <= 0) or nmt.__yaml_mapping == true then
			return self:dump_mapping(node)
		else
			return self:dump_sequence(node)
		end
	else -- unsupported Lua type
		error("cannot dump object of type '" .. itsa .. "'", 2)
	end
end

-- Dump DOCUMENT into the event stream.
function YamlDumper:dump_document(document)
	self:emit {type="DOCUMENT_START"}
	self:dump_node(document)
	return self:emit {type="DOCUMENT_END"}
end


return YamlDumper
