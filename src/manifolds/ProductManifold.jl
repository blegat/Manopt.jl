#
#      Productmanifold – the manifold generated by the product of manifolds.
#
# Manopt.jl, R. Bergmann, 2018-06-26
import Base: exp, log, show

export ProductManifold, ProdMPoint, ProdMTVector
export distance, dot, exp, log, manifoldDimension, norm, parallelTransport
export show

struct ProductManifold <: Manifold
  name::String
  manifolds::Array{Manifold}
  dimension::Int
  abbreviation::String
  ProductManifold(mv::Array{Manifold}) = new("ProductManifold",
    mv,prod(manifoldDimension.(mv)),string("Prod(",join([m.abbreviation for m in mv],", "),")") )
end
struct ProdMPoint <: MPoint
  value::Array{MPoint}
  ProdMPoint(v::Array{MPoint}) = new(v)
end

struct ProdMTVector <: MTVector
  value::Array{MTVector}
  base::Nullable{ProdMPoint}
  ProdMTVector(value::Array{MTVector}) = new(value,Nullable{ProdMPoint}())
  ProdMTVector(value::Array{MTVector},base::ProdMPoint) = new(value,base)
  ProdMTVector(value::Array{MTVector},base::Nullable{ProdMPoint}) = new(value,base)
end

function addNoise(M::ProductManifold, p::ProdMPoint,σ)::ProdMPoint
  return ProdMPoint([addNoise.(M.manifolds,p.value,σ)])
end


function distance(M::ProductManifold, p::ProdMPoint,q::ProdMPoint)::Float64
  return sqrt(sum( distance.(manifolds,p.value,q.value).^2 ))
end

function dot(M::ProductManifold, ξ::ProdMTVector, ν::ProdMTVector)::Float64
  if checkBase(ξ,ν)
    return sum(dot.(M.manifolds,ξ.value,ν.value))
  else
    throw(ErrorException("Can't compute dot product of two tangential vectors
		belonging to different tangential spaces."))
  end
end

function exp(M::ProductManifold, p::ProdMPoint,ξ::ProdMTVector,t::Number=1.0)::ProdMPoint
  return ProdMPoint( exp.(M.manifolds,p.value,ξ.value) )
end

function log(M::ProductManifold, p::ProdMPoint,q::ProdMPoint,includeBase::Bool=false)::ProdMTVector
  if includeBase
    return ProdMTVector(log.(M.manifolds,p.value,q.value),p)
  else
    return ProdMTVector(log.(M.manifolds,p.value,q.value))
  end
end

function manifoldDimension(p::ProdMPoint)::Int
  return prod( manifoldDimension.(p.value) )
end
function manifoldDimension(M::ProductManifold)::Int
  return prod( manifoldDimension.(M.manifolds) )
end
function norm(M::ProductManifold, ξ::ProdMTVector)::Float64
  return sqrt( dot(M,ξ,ξ) )
end
#
#
# Display functions for the structs
function show(io::IO, M::ProductManifold)
  print(io,string("The Product Manifold of [ ",
    join([m.abbreviation for m in M.manifolds])," ]"))
end
function show(io::IO, p::ProdMPoint)
    print(io,string("ProdM[",join(repr.(p.value),", "),"]"))
end
function show(io::IO, ξ::ProdMTVector)
  if !isnull(ξ.base)
    print(io,String("ProdMT_(",repr(ξ.base),")[", join(repr.(ξ.value),", "),"]"))
  else
    print(io,String("ProdMT[", join(repr.(ξ.value),", "),"]"))
  end
end
