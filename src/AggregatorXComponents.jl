# Type definitions

# =============== Abstract types ====================

abstract type AggregatorXAny end

abstract type TimeStruct         <: AggregatorXAny end
abstract type AbstractConnection <: AggregatorXAny end
abstract type Component          <: AggregatorXAny end
abstract type Group              <: AggregatorXAny end

abstract type Node      <: Component end
abstract type Market    <: Component end
abstract type Resource  <: Component end

abstract type FCRMarket     <: Market end
abstract type FCR_LERMarket <: FCRMarket end

abstract type Grid <: Resource end
abstract type Load <: Resource end

# ================ Concrete types ==================

# ---------------- Time structures -----------------

"""
    IndexedTimeStruct

A time structure represented by a single index representing time points.
"""
mutable struct IndexedTimeStruct <: TimeStruct 
    periods::Int 
end

struct StochasticTimeStruct <: TimeStruct
    scenarios   :: Vector{Any}
    probability :: Vector{Real}
    periods     :: Int
end

# ---------------- Components ---------------------

# --- Nodes ---

mutable struct StandardNode <: Node
    power   ::Dict{Integer, AbstractArray{VariableRef}}
    sources ::Vector{Integer}
    id      ::Integer
end

# --- Resources ---

# - SimpleCharger -
mutable struct SimpleCharger <: Resource 
    power::Dict{Integer, Vector{VariableRef}}
    up_capacity::Dict{Integer, Vector{VariableRef}}
    down_capacity::Dict{Integer, Vector{VariableRef}}
    up_activation::Dict{Integer, Vector{VariableRef}}
    down_activation::Dict{Integer, Vector{VariableRef}}
    sources::Vector{Integer}
    max_power::Real
    id::Integer
end

# - SimpleBattery -
mutable struct SimpleBattery <: Resource
    power::             Dict{Integer, AbstractArray{VariableRef}}
    sources::           Vector{Integer}
    state_of_charge::   AbstractArray{VariableRef}
    up_capacity::       Dict{Integer, AbstractArray{VariableRef}}
    down_capacity::     Dict{Integer, AbstractArray{VariableRef}}
    up_activation::     Dict{Integer, AbstractArray{VariableRef}}
    down_activation::   Dict{Integer, AbstractArray{VariableRef}}
    up_energy_reserve:: Dict{Integer, AbstractArray{VariableRef}}
    down_energy_reserve::Dict{Integer, AbstractArray{VariableRef}}
    capacity::      AbstractFloat
    initial_charge::AbstractFloat
    max_charge::    AbstractFloat
    max_discharge:: AbstractFloat
    class::         String
    id::            Integer
end

mutable struct SimpleBatteryVarParam <: Resource
    power::             Dict{Integer, AbstractArray{VariableRef}}
    sources::           Vector{Integer}
    state_of_charge::   AbstractArray{VariableRef}
    up_capacity::       Dict{Integer, AbstractArray{VariableRef}}
    down_capacity::     Dict{Integer, AbstractArray{VariableRef}}
    up_activation::     Dict{Integer, AbstractArray{VariableRef}}
    down_activation::   Dict{Integer, AbstractArray{VariableRef}}
    up_energy_reserve:: Dict{Integer, AbstractArray{VariableRef}}
    down_energy_reserve::Dict{Integer, AbstractArray{VariableRef}}
    capacity::          AbstractArray{<:Real} # Variable parameter
    initial_charge::    AbstractFloat
    max_charge::        AbstractArray{<:Real} # Variable parameter
    max_discharge::     AbstractArray{<:Real} # Variable parameter
    class::             String
    id::                Integer
end

mutable struct StandardBattery <: Resource
    power::             Dict{Integer, AbstractArray{VariableRef}}
    sources::           Vector{Integer}
    state_of_charge::   AbstractArray{VariableRef}
    up_capacity::       Dict{Integer, AbstractArray{VariableRef}}
    down_capacity::     Dict{Integer, AbstractArray{VariableRef}}
    up_activation::     Dict{Integer, AbstractArray{VariableRef}}
    down_activation::   Dict{Integer, AbstractArray{VariableRef}}
    up_energy_reserve:: Dict{Integer, AbstractArray{VariableRef}}
    down_energy_reserve::Dict{Integer, AbstractArray{VariableRef}}
    capacity::          AbstractFloat
    initial_charge::    AbstractFloat
    max_charge::        AbstractFloat
    max_discharge::     AbstractFloat
    charging_loss::     AbstractFloat
    discharging_loss::  AbstractFloat
    throughput_cost::   AbstractFloat
    class::             String
    id::                Integer
end

mutable struct Generation <: Resource
    power   ::Dict{Integer, AbstractArray{VariableRef}}
    cost    ::Vector{Real}  
    pmax    ::Vector{Real}
    pmin    ::Vector{Real}
    id      ::Integer
end

# --- Loads ---

# Depreceated, use VariableLoad with fixed lower_bound and no upper_bound (e.g. infinity)
mutable struct MinLoad <: Load 
    pmin::Number
    source::Integer
    id::Integer
end

mutable struct MinAverageLoad <: Load
    pmin::Number # minimum average power
    id::Integer
end

mutable struct FixedLoad <: Load
    source::Integer
    load::AbstractArray
    constraint::Dict{String, AbstractArray} #AbstractArray{ConstraintRef} not working
    scalar_constraint::Dict{String, ConstraintRef}
    id::Integer
end

mutable struct VariableLoad <: Load
    power::Dict{Integer, Vector{VariableRef}}
    sources::Vector{Integer}
    lower_bound::Vector{Real}
    upper_bound::Vector{Real}
    id::Integer
end

mutable struct ThermalLoad <: Load
    power              ::Vector{AffExpr}
    load               ::Vector{Real}
    up_capacity        ::Dict{Integer, Vector{VariableRef}}
    down_capacity      ::Dict{Integer, Vector{VariableRef}}
    up_activation      ::Dict{Integer, Vector{VariableRef}}
    down_activation    ::Dict{Integer, Vector{VariableRef}}
    up_energy_reserve  ::Dict{Integer, Vector{VariableRef}}
    down_energy_reserve::Dict{Integer, Vector{VariableRef}}
    temperature        ::Vector{VariableRef}
    inital_temperature ::Real
    max_temperature    ::Real
    min_temperature    ::Real
    ambient_temperature::Vector{Real}
    heat_capacity      ::Real
    heat_loss_factor   ::Real
    max_power          ::Real
    constraints        ::Vector{Any}
    source             ::Integer
    id                 ::Integer
end

# --- Grids ---


mutable struct LinearTariff <: Grid
    power::Dict{Integer, Vector{VariableRef}}
    sources::Vector{Integer}
    price::Vector{Real}
    upper_bound::Vector{Real}
    id::Integer
end

"""
    LimitedConnection

Represents a physical grid with a limited capacity. Reserved capacity and direct
activation markets are taken into account.
"""
mutable struct LimitedConnection <: Grid
    power               ::Dict{Integer, Vector{VariableRef}}
    sources             ::Vector{Integer}
    upper_bound         ::Vector{Real}
    capacity_markets    ::Vector{Integer}
    activation_markets  ::Vector{Integer}
    id                  ::Integer
end

# --- Groups ---

"""
# FFRGroup
    # JSON template
'''
{
    "class" : "FFRGroup",
    "resources" : [],
    "markets" : [],
    "id" : 7
}
'''
"""
mutable struct FFRGroup <: Group
    up_capacity::Vector{AffExpr}
    resources::Set{Int} # ids of resources in the group.
    markets::Set{Int} # ids of markets connected to the group.
    class::String  
    id::Integer
end

mutable struct FCRGroup <: Group
    up_capacity::AbstractArray{AffExpr}
    down_capacity::AbstractArray{AffExpr}
    up_activation::AbstractArray{AffExpr}
    down_activation::AbstractArray{AffExpr}
    resources::Set{Int} # ids of resources in the group.
    markets::Set{Int} # ids of markets connected to the group.
    class::String  
    id::Integer
end

"""
# FCReGroup

## JSON template
'''
{
    "type" : "FCRGroup",
    "resources" : [],
    "markets" : [],
    "id" : N 
    "class" : "FCR"
}
'''
-resources: Vector of resource ids
-markets:   Vector of market ids
-id:        Integer id of the group
-class:     String # Mandatory but not used, to be removed in future versions.
"""
mutable struct FCReGroup <: Group
    up_capacity::AbstractArray{AffExpr}
    down_capacity::AbstractArray{AffExpr}
    up_energy_reserve::AbstractArray{AffExpr}
    down_energy_reserve::AbstractArray{AffExpr}
    up_energy_reserve_factor::Number
    down_energy_reserve_factor::Number
    resources::Set{Int} # ids of resources in the group.
    markets::Set{Int} # ids of markets connected to the group.
    id::Integer
end

# --- Markets ---

mutable struct SimpleMarket <: Market
    power::Dict{Integer, Vector{VariableRef}}
    price:: Array{AbstractFloat}
    resource::Integer       
    sign::Integer
    class::String
    id::Integer
end

mutable struct SimpleDAMarket <: Market
    power::Dict{Integer, Vector{VariableRef}}
    price::Vector{AbstractFloat}
    resource::Integer       
    sign::Integer
    class::String
    id::Integer
end

"""
# FFRProfil

    # JSON template
'''
{
    "type" : "FFRProfil",
    "price" : N,
    "armed" : [],
    "sign" : -1,
    "class" : "FFR",
    "id" : N
    "minimum_bid" : N
}
'''
Required fields:
-price: Vector of AbstractFloat
-armed: Vector of Bool
-sign: Integer
-class: String
-id: Integer
Optional fields:
-minimum_bid: AbstractFloat

"""
mutable struct FFRProfil <: Market
    up_capacity_common::Union{VariableRef, Nothing} # Nothing to allow uninitalized during construction
    up_capacity::Vector{AffExpr} # Reserved capacity.
    price::Vector{AbstractFloat}
    minimum_bid::AbstractFloat
    participating::Union{VariableRef, Nothing}
    armed::Vector{Bool} # Time steps where FFR is armed.
    constraint::Dict{String, Vector{ConstraintRef}}
    scalar_constraint::Dict{String, ConstraintRef}
    sign::Integer
    class::String
    id::Integer
end

mutable struct FCRN <: Market
    up_capacity::Vector{VariableRef}
    down_capacity::Vector{VariableRef}
    up_activation::Vector{VariableRef}    
    down_activation::Vector{VariableRef}
    price_capacity::Vector{AbstractFloat}
    price_up_activation::Vector{AbstractFloat}
    price_down_activation::Vector{AbstractFloat}
    df::Vector{AbstractFloat} # Frequency deviation in Hz.
    dfmax::AbstractFloat # Maximum frequency deviation in Hz.
    sign::Integer
    class::String
    id::Integer
end

mutable struct FCRNe <: Market
    #capacity_sold::Vector{VariableRef}
    #up_capacity::Vector{AffExpr}
    #down_capacity::Vector{AffExpr}
    #up_capacity_sold::Vector{AffExpr}
    #down_capacity_sold::Vector{AffExpr}
    #up_energy_reserve::Vector{AffExpr}
    #down_energy_reserve::Vector{AffExpr}
    capacity_sold::AbstractArray{VariableRef}
    up_capacity::AbstractArray{AffExpr}
    down_capacity::AbstractArray{AffExpr}
    up_capacity_sold::AbstractArray{AffExpr}
    down_capacity_sold::AbstractArray{AffExpr}
    up_energy_reserve::AbstractArray{AffExpr}
    down_energy_reserve::AbstractArray{AffExpr}
    energy_endurance::Real
    capacity_factor::Real
    price::Vector{Real}
    sign::Integer
    id::Integer
end

mutable struct FCRD_Up_LER <: FCR_LERMarket
    capacity_sold       ::Vector{VariableRef}
    up_capacity         ::Vector{AffExpr}
    down_capacity       ::Vector{AffExpr}
    #up_energy_reserve   ::Vector{AffExpr}
    #down_energy_reserve ::Vector{AffExpr}
    energy_endurance    ::Real
    capacity_factor     ::Real
    price               ::Vector{Real}
    sign                ::Integer
    id                  ::Integer
end

# Outer constructors
FCRD_Up_LER(energy_endurance, capacity_factor, price, sign, id) = 
FCRD_Up_LER(Vector{VariableRef}(), Vector{AffExpr}(), Vector{AffExpr}(), 
            energy_endurance, capacity_factor, price, sign, id )

# --- Connections ---

mutable struct Connection <: AbstractConnection
    source::Integer
    sink::Integer
end