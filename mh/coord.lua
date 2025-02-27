---
-- @module Coord
local Coord = {}
local matrix =require("matrix")

Coord.__index = Coord

EPSILON = math.epsilon or 1e-10 -- Small threshold for near-zero comparison
HPI = 0.5*math.pi
PI2 = 2*math.pi
---
function math.sign(x, epsilon)
	local eps = epsilon or EPSILON
    if math.abs(x) < eps then
        return 0
    elseif x > 0 then
        return 1
    else
        return -1
    end
end

---
-- Checks if distance between a and b smaller then EPSILON
function math.nbh(a,b) return (math.sign(a-b)==0) end
---
--
function Coord.new(vect,type)
	local type = type or 'c'
	local  self = setmetatable({},Coord)
	local vector={}

	self.dimension = #vect
	self.vector={}

	if type=='pd' or type=='gd' then -- if degree make rad
		for i=1,self.dimension-1 do vector[i]=math.pi*vect[i]/180.0 end
		vector[self.dimension]=vect[self.dimension]
	else
		vector=vect
	end

	if type=='c' then --cartesian
		for i,v in ipairs(vector) do self.vector[i] = vector[i]	end
	elseif type == 'p' or type == 'pd' then -- polar rad or degree
		self.vector[1]=vector[3]*math.cos(vector[1])*math.sin(vector[2]) -- X coordinate
		self.vector[2]=vector[3]*math.sin(vector[1])*math.sin(vector[2]) -- Y coordinate
		self.vector[3]=vector[3]*math.cos(vector[2])                     -- Z (vertical) coordinate
	elseif type == 'g' or type == 'gd' then -- global rad or degree
		self.vector[1]=vector[3]*math.sin(vector[1])*math.cos(vector[2]) -- X coordinate
		self.vector[2]=vector[3]*math.cos(vector[1])*math.cos(vector[2]) -- Y coordinate
		self.vector[3]=vector[3]*math.sin(vector[2])                     -- Z (vertical) coordinate
	end
	return self
end

function Coord.global2polar(x,y,r)	return HPI-x,HPI-y,r end
Coord.polar2global=Coord.global2polar

function Coord:get(i) return self.vector[i]	end

function Coord:set(i,v) self.vector[i]=v end


function Coord:x() return self.vector[1] end
function Coord:y() return self.vector[2] end
function Coord:z() return self.vector[3] end


---
-- Polar Coordinate System
function Coord:PCSrad()
	local v,l = Coord.normalize(self)

	local ya = math.acos(v:z())
	local sinya = math.sin(ya)
	if math.abs(sinya) <0.0000000000001 then return 0,ya,l end
	local xa = math.acos(v.vector[1]/sinya)
	if self.vector[2]<0 then xa = xa + math.pi end
	return xa,ya,l
end
function Coord:PCSdeg()
	local xa,ya,l = Coord.PCSrad(self)
	return 180*xa/math.pi,180*ya/math.pi,l
end
Coord.PCS = Coord.PCSdeg

---
-- Global Coordinate System
--function Coord:geographic()
--	local l      = Coord.length(self)
--	local phi    = math.asin(self.vector[3]/l)
--	local cosphi = math.cos(phi)
--	local alpha =  math.asin(self.vector[1]/(l*cosphi))
--	if self.vector[2]<0 then alpha = math.pi -alpha end
--	return alpha*180/math.pi, phi*180/math.pi, l
--end
function Coord:GCSrad()
	--Coord.print(self)
	local v,l = Coord.normalize(self)

	local ya = math.asin(v:z())
	if math.abs(math.abs(ya)-0.5*math.pi) <0.0000000000001 then return 0,ya,l end

	local cosy = math.cos(ya)
--print(cosy,v.vector[2]/cosy)
	local temp=v.vector[1]/cosy
	if math.abs(temp)>1 then temp = math.sign(temp)*1 end

	local xa = math.asin(temp)
	if self.vector[2]<0 then xa = math.pi -xa end
	while (xa>math.pi)  do xa = xa-2*math.pi end
	while (xa<-math.pi) do xa = xa+2*math.pi end
	return xa,ya,l
end

function Coord:GCSdeg()
	local xa,ya,l = Coord.GCSrad(self)
	return 180*xa/math.pi,180*ya/math.pi,l
end

Coord.GCS = Coord.GCSdeg

---
-- rotation
function printmatrix(m,format)
	local format = format or "%9.2f "
	for j=1,#m do
		for i=1,#m[j] do
			io.write(string.format(format, m[j][i]))
		end
		io.write("\n")
	end
end

function Coord:string(formatstring)
	local formatstring = formatstring or "%7.2f"
	local str="("
	for i=1,self.dimension do
		str = str .. string.format(formatstring,self.vector[i])
	end
	return str..")"
end

function mmulti(m1,m2)
	local mr = {}
	local n  = #m1
	for j=1,n do
		mr[j]={}
		for i=1,n do
			mr[j][i] = 0
			for k=1,n do
				mr[j][i]= mr[j][i] + m1[j][k]*m2[k][i]
			end
		end
	end
	return mr
end
---
-- @param a rotation angle x-ax
-- @param b rotation angle y-ax
-- @param c rotation angle z-ax
-- @param order optional parametr to give order of rotations
function Coord.rotation_matrix(a,b,c,order)
	local order = order or {1,2,3}

	local m = {}
	m[1] ={ --rotation x-ax
		{1,0,0},
		{0,math.cos(a),-math.sin(a)},
		{0,math.sin(a),math.cos(a) }}
	m[2] ={ --rotation y-ax
		{math.cos(b),0,math.sin(b)},
		{0,1,0},
		{-math.sin(b),0,math.cos(b) }}
	m[3] ={ --rotation z-ax
		{math.cos(c),-math.sin(c),0},
		{math.sin(c),math.cos(c),0},
		{0,0,1} }

--	printmatrix(rmx)
--	printmatrix(rmy)
--	printmatrix(rmz)
--	printmatrix(matrix.mul(matrix.mul(rmx,rmy),rmz))
	local mt = mmulti(m[order[1]],m[order[2]])

	--print("tussen:")printmatrix(mt)
	mt = mmulti(mt,m[order[3]])
	--print("eind")printmatrix(mt)
	return mt
end

---
-- rotation over x (a) y (b) and z (c) axeis
function Coord:rotation(a,b,c)
	printmatrix(Coord.rotation_matrix(a,b,c))
	local p=Coord.proj(self,Coord.rotation_matrix(a,b,c))
	print(p.vector[1],p.vector[2])
	return Coord.proj(self,Coord.rotation_matrix(a,b,c))
end

function Coord.empty(l)
	local v={}
	for i=1,l do v[i]=0 end
	return Coord.new(v)
end

function Coord:print(format)
	local format =format or "%7.2f, "
	for i,v in ipairs(self.vector) do
		io.write(string.format(format,v))
	end
	print()
end

function Coord:proj(mtx) 
	local projection = Coord.empty(#mtx)
	--Coord.print(projection)
	for i,v1 in ipairs(mtx) do
		assert(#v1 == #self.vector,"Projection matrix and coord vector not the same dimension")
		for j,v in ipairs(v1) do 
			projection.vector[i]=projection.vector[i]+self.vector[j]*v
		end
	end
	return projection
end

---
-- Distance between two coords
-- @param c second coord
-- @return disance, squared_distance
function Coord:distance(c)
	assert(self.dimension == c.dimension, "coords are of different langth ("..self.dimension.." <->"..c.dimension..")")
	local d=0
	for i,v in ipairs(self.vector) do
		d = d + (v-c.vector[i])*(v-c.vector[i])
	end
	return math.sqrt(d), d
end

function Coord:scalar(s)
	local scaled = Coord.new(self.vector)
	for i=1,scaled.dimension do
		scaled.vector[i] = scaled.vector[i]*s
	end
	return scaled
end

---
-- returns length of coord vector
function Coord:length()
	local l=0
	for i=1,self.dimension do
		l=l+self.vector[i]^2
	end
	return math.sqrt(l)
end
---
-- Normalize coord
-- @return normalized coord
function Coord:normalize()
	local l = Coord.length(self)
 	return Coord.scalar(self,1/l), l
end

--function Coord:add(i,v) self.vector[i]= self.vector[i] + v end
---
-- @param p if is integer than add change to self.vector[i] else
-- @param change is true self.vector += p.vector else (default)
-- return self.vector + p.vector
-- @return result
function Coord:add(p,change)
	if type(p)=="integer" then  self.vector[i]= self.vector[i] + v; return self end
	if change then
		for i=1,self.dimension do
			self.vector[i] = self.vector[i]+p.vector[i]
		end
		return self
	else
		local res={}
		for i=1,self.dimension do
			res[i]=self.vector[i]+p.vector[i]
		end
		return Coord(res)
	end
end

function Coord:sub(p)
	local res={}
	for i=1,self.dimension do
		res[i]=self.vector[i]-p.vector[i]
	end
	return Coord(res)
end

---
-- @param p
-- Calculate the inproduct beween two coords
function Coord:inprod(p)
	local res=0
	for i=1,self.dimension do
		res =res + self.vector[i]*p.vector[i]
	end
	return res
end

function solve(v1,v2,ord)
	local ret={}
--print(v1[1],v1[2],v1[3])
--print(v2[1],v2[2],v2[3])
	local im = {{v2[ord[2]],-v1[ord[2]]},{-v2[ord[1]],v1[ord[1]]}}
--print("SOLVE",ord[1],ord[2])
--printmatrix(im)
--print(-v1[ord[3]],-v2[ord[3]])

	local n = Coord({-v1[ord[3]],-v2[ord[3]]}):proj(im)
	local d = v1[ord[1]]*v2[ord[2]] - v1[ord[2]]*v2[ord[1]]
	--Coord.print(n)
	ns=Coord.scalar(n,1.0/d)

--	Coord.print(ns)
	table.insert(ns.vector,1)

	return {ns.vector[ord[1]],ns.vector[ord[2]],ns.vector[ord[3]]}
end
---
-- Calculates the norm of a surface through the origin and two points
 -- @param self first point
-- @param p second point
-- @return norm vector (z-value = 1)
function Coord:norm_surface_org(p)
	-- calculate inv matrix ((x1,y1)(x2,y2))
	local v1=self.vector
	local v2=p.vector
	local r
	if math.abs(v1[1]*v2[2] - v1[2]*v2[1]) > EPSILON then  r=solve(v1,v2,{1,2,3})
	elseif math.abs(v1[1]*v2[3] - v1[3]*v2[1]) > EPSILON then  r=solve(v1,v2,{1,3,2})
	elseif math.abs(v1[2]*v2[3] - v1[3]*v2[2]) > EPSILON then  r=solve(v1,v2,{3,2,1})
	else
		print(" Depended system!!")
	end
	--print(r[1],r[2],r[3])
	return r
end

---
-- gives the normal vector of surface through points
function Coord:normal(...)
    local args = {...}
	local dim = self.dimension
	--make matrix
	local m = {}
	if dim==#args+1 then table.insert(m,self.vector) end
	for i=1,#args do
		table.insert(m,args[i].vector)
	end
	mx=matrix(m)
	-- check if one row is origin and add {1,1,1}
	local det = matrix.det(mx)
	if math.sign(det) == 0 then	mx=matrix.addnum(mx,1) det =matrix.det(mx) end
	if math.sign(det) == 0 then	mx=matrix.addnum(mx,1,0,1) det =matrix.det(mx) end
	if math.sign(det) == 0 then	mx=matrix.addnum(mx,1,0,2) det =matrix.det(mx) end
	--matrix.print(mx)
	assert(math.sign(det) ~=0, "Depening system")

	mxinv = matrix.invert(mx)
	local res = matrix.mul(mxinv,matrix(dim,1,1))
--	print("INV:")matrix.print(mxinv)
--	print(matrix(dim,1,3))

--	print("NORM:")matrix.print(res)
	local norm={}
	for i=1,dim do norm[i]=res[i][1] end
	return norm
end

setmetatable(Coord, {
    __call = function(cls,v,t)
        return cls.new(v,t)
    end,
	__sub = function(cls,p1,p2)
		cls.print(p1)
		cls.print(p2)
		return 2
	end,
--	__index = function(cls,idx)
--		print(idx,cls.print())
--		return "index"--cls.vector[idx]
--	end,

	__newindex = function(cls,idx,v)
		cls.vector[idx]=v
	end,

--	__pairs = function(_)
--        return family_iterator, order, 0  -- Return the custom iterator function, table, and initial index
--	end
})

if arg ~= nil and arg[0] == string.sub(debug.getinfo(1,'S').source,2) then
	if #arg<1 then
	local a = Coord({1,2,3})
	local b = Coord({4,5,6})
	local mtx = {{1,0,0.0},{0,1,0}}
	a:print()
	c=a:sub(b)
	c:print()
	b=Coord({0,0,1})
	a=Coord({0.5*math.sqrt(2),0.5*math.sqrt(2),0})
	--print(a:sphere())
	print(math.asin(-0.2))
	print(math.acos(-0.2))
	--d=a-b
	a:proj(mtx)
	a:proj(mtx,true):print()
	local p = Coord({1,0,0})
	print("x,y,l=",Coord({1,0,0}):PCS())
	print("x,y,l=",Coord({-1,0,0}):PCS())
	print("x,y,l=",Coord({0,1,0}):PCS())
	print("x,y,l=",Coord({0,-1,0}):PCS())
	print("x,y,l=",Coord({0,0,1}):PCS())
	print("x,y,l=",Coord({0,0,-1}):PCS())
	print("x,y,l=",Coord({1,1,0}):PCS())
	print(math.acos(0.999999999999))

	local rm = Coord.rotation_matrix(0.5*math.pi,0,0)
	printmatrix(rm)
	local p  = Coord({1,0,0})
	local x,y,_ =p:PCSrad()
	print("GCS= ",x,y)
	local rp = p:rotation(0,0,x)
	print("Rotation", p:string(),rp:string())
	print(Coord({0,0.15,0.99}):GCS())

		print("USE new solve surface")

	elseif arg[1]=="solve" then
		local p1 = Coord({1,0,0}) local p2 = Coord({0,1,0})
		p1:print() p2:print()
		Coord.norm_surface_org(p1,p2)
		p1 = Coord({0,1,0}) p2 = Coord({0,0,1})
		p1:print() p2:print()
		Coord.norm_surface_org(p1,p2)
		Coord.norm_surface_org(p2,p1)
		--p1 = Coord({1,0,0}) p2 = Coord({0,0,1})
		--p1:print() p2:print()
		--Coord.norm_surface_org(p1,p2)

		p1 = Coord({1,0,1}) p2 = Coord({0,-1,1})
		--p1:print() p2:print()
		--Coord.norm_surface_org(p1,p2)

		p1 = Coord({0.7,0.7,0}) p2 = Coord({0,0,1})
		--p1:print() p2:print()
		--Coord.norm_surface_org(p1,p2)
		--Coord.norm_surface_org(p2,p1)


	elseif arg[1]=="surface"then

		local p1 = Coord({1,0,1}) local p2 = Coord({0,-1,1}) local p3 = Coord({1,-1,1})
		p1:normal(p2,p3)
		p1 = Coord({1,0,0}) p2 = Coord({0,1,0})  p3 = Coord({0,1,1})
		p1:normal(p2,p3)
		p1 = Coord({0,0,1}) p2 = Coord({0.71,0.71,0})  p3 = Coord({0,0,0})
		p1:normal(p2,p3)
	elseif arg[1]=="new"then
		local v = {90,0,1}
		Coord(v):print("%5.2f, ")
		io.write("global    : ")  Coord(v,"g"):print("%7.3f, ")
		io.write("polar     : ")  Coord(v,"p"):print("%7.3f, ")
		io.write("global deg: ") Coord(v,"gd"):print("%7.3f, ")
		io.write("polar deg : ") Coord(v,"pd"):print("%7.3f, ")
		v = {0,90,1}
		Coord(v):print("%5.2f, ")
		io.write("global    : ")  Coord(v,"g"):print("%7.3f, ")
		io.write("polar     : ")  Coord(v,"p"):print("%7.3f, ")
		io.write("global deg: ") Coord(v,"gd"):print("%7.3f, ")
		io.write("polar deg : ") Coord(v,"pd"):print("%7.3f, ")
	elseif arg[1]=="add" then
		p=Coord.empty(3)
		p:print()
		p1=Coord({0.00000000001,0.2,0.3})
		p=p:add(p1)
		p:print()
	end
else
	return Coord
end
