The work flow of the software is as follows:

* Describe your system of interest in a json file. This file is refered to as the *system description*. This file can have any name but we fill refer to it as `system.json` as an example
* Import the AggregatorX package, `using AggregatorX`.
* Build the system using `aggregator = buildaggregatorx("system.json")`. What this does is to create objects of AggregatorX types with the number and types of objects and their parameters based on the content of `system.json`. The aggregatorX objects are stored in the variable `aggregator` as a dictionary.
* Create and run optimization of system using `optimizeaggregator(aggregator, optimizer)`. This creates a JuMP model based on the information in the `aggregator` object. It then tries to optimize the model using the optimizer referred to by `optimizer`.



# Some words
Read the mathematical/conceptual description first

Seeks to maximize profits (costs are negative, revenue positive)

VariableRef

# The AggregatorX type hierarchy

The AggregatorX software defines a set of new abstract and concrete types (The concrete types are akin to classes in other OO languages. Abstract types cannot be instantiated, but can be used for dispatching on functions). All the information about the system under analysis is stored in instances of these types.

There is a hierarchy of abstract types. Not all levels of the hierarchy are in use, but as been implemented to provide conceptual overview of the types and with the idea that a sensible hierarchy will make extending the code easier in the future.

At the top is AggregatorXAny, which extended by three abstract types `Components`, `Groups`and `TimeStruct`. 

`Components` represent concrete elements in the system, either physical objects (batteries, EV charger, connections) or market places. It is the parent of four abstract types `Resources`, `Markets`, `Node`, `Grids` and `AbstractConnection`. `Resources` are components that represent flexible energy resources, conceptually they are either generation/loads or storage units. `Markets`are components where energy is bought or sold and typically adds terms to the objective function. `Grid` componets represent limitations or cost due to local distribution grid. `Node` represents a distribution point of energy among resources and markets. `AbstractConnection` represents connections between the other components.

One can visualize the `Components` as the nodes of the graph that represent the system. Conceptually one can think of the components as entities that exchange energy.

`Groups`are collections of resources that can participate in balancing markets. The groups keep track of reserved capacity and activated energy of the resources in the group and can sell this to various concrete balancing markets.

`TimeStruct` represents the timestep used in the system.

# The aggregator dictionary

The `aggregator` object is a dictionary with string keys that refer to particular abstract types: TimeStruct, Market, Resource, Node, Grid, Connection. The key points to a vector of instances of concrete types that are subtypes of these abstract types.

# Book-keeping
In general, each component has a dictionary power that reprsent the power flowing **from** the component. Each key is a component that is connected to an output from component, and the value is a vector of VariableRef that. Currently the `node` component is the only component that has multiple outputs, but the dictionary structure is used to maintain some unity in implementation and for flexibility in future versions that might require additional flexibility.

# Components



## Markets
Concrete market subtypes must implment at least the following fields: 

* power - Dict(Integer->Vector(VariableRef)) the power flowing to or from the market
* price - the cost of energy
* resource - the resource (component) the market is connected to
* sign - 1 if the market is a source of energy, 1 if the market is a sink of energy.
* id - A unique identifier.

The framework assumes that a market is only connected to a single entity.

If the market is to be connected to a group it must also implement a `class` field which represent the technical requirements of the market, and thus which groups may be connected to it (this is primarily a check for mistakes in the connections in the system description where wrong markets may be connected to wrong type of group/resources). An optional `name` may also be included which is used for labeling variables and constraints and may be useful when interogating the optimization solution.

When `buildaggregator()` the system reads all the market entries in the JSON file, determines the type it represents, and calls the appropriate constructor (dispatching on the market type). As a minimum, the constructur checks the connections and finds the market's id to determine which component it is connected to and assigns this to the resource field. 

It then instantiates power as a dictionary with one key value pair, Resource->empty vector of VariableRef (a julia type, note that this must be reimplemented to use the system with a different modelling package). This so that when the actual VariableRef is created, it can ba assigned to this key (**This seems redundant. One could to this instantiation in variable creation method.)

After building the aggregator object, the optimization problem is set up by calling `optimizeaggregator()`. This function goes through the three steps of setting up an optimization problem, define variables, define constraints, define objective function.

For markets the variable creation simply creates a vector of variable ref an assigns this to the power dictionary.

The markets do not have to impose any particular constraint. However, for markets that are sinks of energy (energy is sold to the market) the power is constrained to be equal to the output power of the connected resource

`optimizeaggregator()` calls `set_objective()`. This function loops over alle markets (other components that adds costs may be included, e.g. grid tariffs or degradation of batteries). For each market it calls `get_objective_term` that dispatches on the type of market. Any type of function of the variables may be used to describe the market (keeping in mind that anything but linear functions will make the problem harder to solve. Nonlinear functions is currently untested, there might be reasons why this will break the code, e.g. where variables are defined as AffExpr (linear expressions in JuMP)), but a typical implementation will be the price times the power * (-sign). Recall that the sign is 1 if power flow **from** the market, i.e. a cost (unless the price is negative). Power (as all varibles) is always positive (unidirectional connections).
