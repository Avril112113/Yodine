-- used to test yolol parser when developing stuff for it

--[[
function debug.relabelDbgFilter(ruleName)
	local bl = {
		Sp=true
	}
	return bl[ruleName] ~= true and #ruleName > 1
end
--]]

local re = require "relabel"
local yolol = require "yolol.init"
local helpers = require "yolol.tests.helpers"

local input = [[
// Code copied from the starbase yolol feature video
x=:Tx-:0x-:Cx ABy=:Ty-:Cy-:Dy z=:Tz-:Oz-:Cz xz=SQRT(x^2+z^2)
ABx=x-(x/xz*:Dxz) ABz=z-(z/xz*:Dxz)
ABxz=xz-:Dxz AB=SQRT(ABxz^2+ABy^2)
:d0=ASIN(ABx/ABxz) :d2=180-ACOS((:A^2+:B^2-AB^2)/(2*:A*:B))
if (ABS :d0)>90 then g1=ACOS(ABy/AB)+90 else g1=(ASIN(ABy/AB)) end
:d1=90-(ACOS((:A^2-:B^2)/(2*:A*AB)))-g1
Axz=SIN(:d1)*:A Ay=COS(:d1)*:A Az=COS(:d0)*Axz Ax=SIN(:d0)*Axz
Bx=ABx-Ax By=ABy-Ay Bz=ABz-Az Bxz=SQRT(Bx^2+Bz^2)
kx=Bx/:B ky=By/:B kz=Bz/:B kxz=SQRT(kx^2+kz^2)
ix=kz iy=0 iz=-kx i=SQRT(ix^2+iy^2+iz^2) ix/=i iy/=i iz/=i
jy=kxz jxz=-ky kx=(SIN :d0)*jxz jz=(COS :d0)*jxz
j=SQRT(jx^2+jy^2+jz^2) jx/=j jy/=j jz/=j Ci=:Cx*ix+:Cy*iy+:Cz*iz
Cj=:Cx*jx+:Cy*jy+:Cz*jz Ck=:Cx*kx+:Cy*ky+:Cz*kz :d3=ACOS(Ck/:C)
:d4=(90*(Ci>0)-90*(Ci<0))*(Cj==0)+180*(Ci==0 and Cj>0) //j==0
if Ci<0 and Cj<0 then :d4=ATAN(ABS(Ci/Cy)) end //i<0 j<0
if Ci<0 and Cj>0 then :d4=180-(ATAN(ABS(Ci/Cj))) end //i<0 j>0
if Ci>0 and Cj<0 then :d4=-(ATAN(ABS(Ci/Cj))) end //i>0 j<0
if Ci>0 and Cj>0 then :d4=(ATAN(ABS(Ci/Cj))) end //i>0 j>0
:calcWait=-1 goto 1
]]
local result = yolol.parse(input)

print("Took " .. tostring(result.parseTime) .. "s odd to parse.")

if result.errPos ~= nil then
	local ln, col = re.calcline(input, result.errPos)
	print("Failed at " .. tostring(ln) .. ":" .. tostring(col) .. " with")
	print(yolol.defs[result.errMsg])
end
print()
if #result.errors > 0 then
	print(tostring(#result.errors) .. " errors reported.")
	for i, v in ipairs(result.errors) do
		local ln, col = re.calcline(input, v.pos)
		print(tostring(ln) .. ":" .. tostring(col) .. " " .. v.msg)
	end
else
	print("No errors reported.")
end
print()
if result ~= nil then
	print()
	print("Parsed data.")
	print("AST")
	helpers.printAST(result.ast, "   |")
	print()
	print("Checking and calculating any statment expression's.")
	for i, line in pairs(result.ast.lines) do
		if line.code ~= nil and #line.code == 1 then
			local v = line.code[1]
			if type(v) == "table" and v.type == "expression" then
				local ok, calcResult = pcall(helpers.calc, v.expression)
				if not ok then
					calcResult = calcResult:gsub(".*:%d+:", ""):gsub("^ *", "")
				end
				print("Calc ln " .. helpers.strValueFromType(i) .. ":", tostring(calcResult))
			end
		end
	end
	-- print(); print(helpers.serializeTable(result.ast))
else
	print("No parsed data.")
end