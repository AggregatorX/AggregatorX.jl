# Introduction

# Usage
Query variables using the registered name: var = model(:var).

## Terminology

* Component - one of the boxes in the figure
* Resources - one of the components that belongs to the aggregator

# Design



## Overall software design

The most general description of the package concept is illustrated in the figure. The aggregator is represented by the dashed line. The components 

## Variables
The main variables in the optimization problem are the power or energy flow between the different components of the model. For the variables that represent flow in or out of the aggregator, these variables are represented by two-dimensional vectors x[i,t] where i is the index of the component in a list of components of the same top level abstract type. These applies to grids, loads and markets. These variables are thus

* p_grid[i,t]
* p_load[i,t]
* a_market[m,t]
* r_market[m,t]

All these variables participate in the overall energy balance and thus enters the corresponding constraint in a similar way (an option would be to name every variable based on the concrete component type, but theis seems more cumpersome).

In addition comes the internal power flow for the aggregator, the interconnections and contributions to the markets.

The contribution to the acitvated markets from the individual components are

* a_resource[i,t]
* r_resource[i,t]

The power flow between resources is a variable in the model. The connection between resources is defined by a pair of numbers (i,j) that represent the id of the resources, as defined in the JSON model description file. After parsing the JSON file the connections between the resources is represented by a Vector  of 2 element vectors. [[i,j], [k,l], ...], where the elements are resource id's.

A JuMP array variable p_conn is created to represent the power flow. The length of the array is equal to the number of connections.

p_conn[k,t]

The jump name of the p_conn[k] elements are set to "p_i,j" where i and j are the corresponding element ids.

The choice of adding the "look up table" between the single index of p_conn and the id pair in the variable name is that it would be easier to inspect in model during runtime, as opposed to being some table hidden deeper in the program.

When a resource is initalized a power balance constraint is created. The program loops through the connections. If it finds the id of the resource it looks up the corresponding p_conn element corresponding to the id pair and adds this to the power balance. The element can be looked up by its name "p_i,j"

--- Another idea could be to add connections as another type

# Usage

## Creating new components

To create new components in the aggregator model the following steps must be taken:

* Create a new concret type, possibly with new abstract supertypes that are subtypes of one of the five top abstract types (AbstractTime, AbstractResource, AbstractGrid, AbstractMarket, Abstract Load)
* Create a new build...(::NewType, JSON data) method that is dispatched when calling with the new type and sets that appropriate fields of the new type according to the JSON data.


