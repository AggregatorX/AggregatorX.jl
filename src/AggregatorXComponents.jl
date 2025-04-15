### Abstract types ###

abstract type AggregatorXAny end

abstract type TimeStruct <: AggregatorXAny end

abstract type AbstractConnection <: AggregatorXAny end

abstract type Component <: AggregatorXAny end

abstract type Group <: AggregatorXAny end

abstract type Market <: Component end

abstract type FCRMarket <: Market end

abstract type FCR_LERMarket <: FCRMarket end

abstract type Resource <: Component end

abstract type Grid <: Resource end

abstract type Load <: Resource end

abstract type Node <: Component end

### Concrete types ###

# -------------------
# - Time structure -
# -------------------

# IndexedTimeStruct has no relation to absolute time, it is simply an index.
struct IndexedTimeStruct <: TimeStruct 
    periods::Int # The number of time steps
end

# -------------
# - Components
# -------------

# - Node -
mutable struct StandardNode <: Node
    power::Dict{Integer, Vector{VariableRef}}
    sources::Vector{Integer}
    id::Integer
end

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
    power::Dict{Integer, Vector{VariableRef}}
    sources::Vector{Integer}
    state_of_charge::Vector{VariableRef}
    up_capacity::Dict{Integer, Vector{VariableRef}}
    down_capacity::Dict{Integer, Vector{VariableRef}}
    up_activation::Dict{Integer, Vector{VariableRef}}
    down_activation::Dict{Integer, Vector{VariableRef}}
    up_energy_reserve::Dict{Integer, Vector{VariableRef}}
    down_energy_reserve::Dict{Integer, Vector{VariableRef}}
    capacity::AbstractFloat
    initial_charge::AbstractFloat
    max_charge::AbstractFloat
    max_discharge::AbstractFloat
    class::String
    id::Integer
end

# - Generation -
mutable struct Generation <: Resource
    power::Dict{Integer, Vector{VariableRef}}
    pmax::Vector{Real}
    pmin::Vector{Real}
    id::Integer
end

# ----------
# - Loads -
# ----------

struct MinLoad <: Load # Depreceated, use VariableLoad with fixed lower_bound and no upper_bound (e.g. infinity)
    pmin::Number
    source::Integer
    id::Integer
end

struct MinAverageLoad <: Load
    pmin::Number # minimum average power
    id::Integer
end

struct FixedLoad <: Load
    source::Integer
    load::Vector{Real}
    constraint::Dict{String, Vector{ConstraintRef}}
    scalar_constraint::Dict{String, ConstraintRef}
    id::Integer
end

struct VariableLoad <: Load
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

# ----------
# - Grids -
# ----------

struct LinearTariff <: Grid
    power::Dict{Integer, Vector{VariableRef}}
    sources::Vector{Integer}
    price::Vector{Real}
    upper_bound::Vector{Real}
    id::Integer
end

# -----------
# - Groups -
# -----------

mutable struct FFRGroup <: Group
    up_capacity::Vector{AffExpr}
    resources::Set{Int} # ids of resources in the group.
    markets::Set{Int} # ids of markets connected to the group.
    class::String  
    id::Integer
end

mutable struct FCRGroup <: Group
    up_capacity::Vector{AffExpr}
    down_capacity::Vector{AffExpr}
    up_activation::Vector{AffExpr}
    down_activation::Vector{AffExpr}
    resources::Set{Int} # ids of resources in the group.
    markets::Set{Int} # ids of markets connected to the group.
    class::String  
    id::Integer
end

mutable struct FCReGroup <: Group
    up_capacity::Vector{AffExpr}
    down_capacity::Vector{AffExpr}
    up_energy_reserve::Vector{AffExpr}
    down_energy_reserve::Vector{AffExpr}
    up_energy_reserve_factor::Number
    down_energy_reserve_factor::Number
    resources::Set{Int} # ids of resources in the group.
    markets::Set{Int} # ids of markets connected to the group.
    id::Integer
end
# ------------
# - Markets -
# ------------

struct SimpleMarket <: Market
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
    capacity_sold::Vector{VariableRef}
    up_capacity::Vector{AffExpr}
    down_capacity::Vector{AffExpr}
    up_capacity_sold::Vector{AffExpr}
    down_capacity_sold::Vector{AffExpr}
    up_energy_reserve::Vector{AffExpr}
    down_energy_reserve::Vector{AffExpr}
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

# Outer constructor
FCRD_Up_LER(energy_endurance, capacity_factor, price, sign, id) = 
FCRD_Up_LER(Vector{VariableRef}(), Vector{AffExpr}(), Vector{AffExpr}(), energy_endurance, capacity_factor, price, sign, id )

# ----------------
# - Connections -
# ----------------

struct Connection <: AbstractConnection
    source::Integer
    sink::Integer
end