# AggregatorX - software design

This document explains how (and to some degree why) the package AggregatorX is designed and used. The main purpose is to enable users to efficiently extend and contribute to the code.

# The type hierarchy

A core idea is that a system of interest can be represented by discrete components and that these discrete componets can be reused across different systems. These components are represented by composite types (`struct`) in Julia and the type hierachy gives a succinct exposition of the philosophy behind the software design as well as the terms that are used to describe the software.

`AggregatorXAny` is the top level type. The top level type has four subtypes

* `TimeStruct`
* `AbstractConnection`
* `Groups`
* `Components`

The first three are more `structural elements` which defines how things are connected, and the 'space' (typically time... ;D) over which variables are defined. The last `Components` is the supertype of all the discrete types that make up the system (covering the range of concepts from a battery to a balancing market).

The first three also have subtypes but the `Component` type has the richest set of suptypes. It has (currently) four different subtypes

* `Resources`
* `Markets`
* `Node`
* `Grids`


## Some words (of wisdom)
A conceptual and mathematical description of what the software does is provided in the document `tex\mathematical-description.tex`. It is probably a good idea to read this document first to understand to what the software tries to acheive, before diving into the nitty-gritty of the software design. 

There are also some design-choices that might be somewhat non-intuitive (hopefully they will gradually become intuitive, otherwise it was probably a bad design-choice...). We provide a list of these here in an attempt at explnation (and justification) of the choice. You can skip this on a first read and refer back to it when necessary.

* The objective sees to *maximize* profits. Any revenue (e.g. selling energy) should therefore be *positive*, and costs (e.g. buying energy) should be *negative*.
* *Parts*. You will see later that there is a hierarchy of different types in the system (e.g. Resources, Markets, etc.). To refer to all of them we will use the term *parts* (also in code). Hence, anything that is a subtype of `AggregatorXAny` is a part (you can think of all the parts that make the clockwork tick...)

Some users may also not be familiar with the Julia programming language or the JuMP modelling language. We therefore provide a list of some terms that are used in the following that might be unfamiliar for these readers. Again, this may be skipped on a first read, and refered back to when confusion sets in.

* `VariableRef`. This is a Julia type defined by JuMP. An instance of this type is a reference to an internal JuMP optimization variable. I.e it provides access to the optimization variable from the scope where the VariableRef is defined. A Variable ref is returned by JuMP macros that create variables.

# Software design

OK, let's take a deep dive into the nitty gritty (Oh boy, I can't wait...)



# Software design

## Location of system description and data files

AggregatorX needs some data to work with. The system that you wish to analyse is stored in a  `*.json file`. This is assumed to be located in the working directory of the current Julia instance. However the global variable `SYSTEMDIR` might be set using the function setsystemdir(directory) where directory is relative to julia working directory

The system description might load parameters from other filese rather than hardcoding them directly. The location of these files might changed by changing the global variable DATADIR using setdatadir(directory) where the directory is releativ to SYSTEMDIR, ie. wd + systemdir + directory.

## The AggregatorX type hierarchy

The AggregatorX software defines a set of new abstract and concrete types (The concrete types are akin to classes in other OO languages. Abstract types cannot be instantiated, but can be used for dispatching on functions). All the information about the system under analysis is stored in instances of these types.

There is a hierarchy of abstract types. Not all levels of the hierarchy are in use, but has been implemented to provide conceptual overview of the types and with the idea that a sensible hierarchy will make extending the code easier in the future.

At the top is AggregatorXAny, which is extended by three abstract types `Components`, `Groups`and `TimeStruct`. 

`Components` represent concrete elements in the system, either physical objects (batteries, EV charger, connections) or markets. It is the parent of five abstract types `Resources`, `Markets`, `Node`, `Grids` and `AbstractConnection`. `Resources` are components that represent flexible energy resources, conceptually they are either generation/loads or storage units. `Markets`are components where energy is bought or sold and typically adds terms to the objective function. `Grid` componets represent limitations or cost due to local distribution grids. `Node` represents a distribution point of energy among resources and markets. `AbstractConnection` represents connections between the various components.

One can visualize the `Components` as the nodes of the graph that represent the system. Conceptually one can think of the components as entities that exchange energy.

`Groups`are collections of resources that can participate in balancing markets. The groups keep track of reserved capacity and activated energy of the resources in the group and can sell this to various balancing markets.

`TimeStruct` represents the timestep used in the system.

## The aggregator dictionary

The `aggregator` object is a dictionary with string keys that refer to particular abstract types: TimeStruct, Market, Resource, Node, Grid, Connection. The key points to a vector of instances of concrete types that are subtypes of these abstract types. This dictionary holds all the information about the system.

### Keeping track of the energy
In general, each component has a dictionary `power` that reprsent the power flowing **from** the component. Each key in the dictionary is the id of a component that is connected to an output from the component, and the value is a vector of VariableRef that. Currently the `node` component is the only component that has multiple outputs, but the dictionary structure is used to maintain some unity in implementation and for flexibility in future versions that might require additional flexibility.

## Components

### Resources

### Markets
Concrete market subtypes must implment at least the following fields: 

* `type` - type of market, ie the concrete type
* `power` - the power flowing to or from the market (`Dict(Integer->Vector(VariableRef))`)
* `price` - the cost of energy
* `resource` - the resource (component) the market is connected to (note this is different from source in other componets which is the input of the component. Resource can be both input and output depending on wether energy is bought or sold in the market.)
* `sign` : 1 if the market is a source of energy, (-1) if the market is a sink of energy.
* `id` - A unique identifier.

The framework assumes that a market is only connected to a single component.

The concrete market objects are stored in a vector of type market. This vector is stored in a dictionary value in the aggregator object

The markets do not in general have to impose any real constraints. However, for markets that are sinks of energy (energy is sold to the market) the power is constrained to be equal to the output power of the connected resource (this is just a convenience implementation, having the power to the market available in the market object is more convenient than having to query the power in the resource connecte to the market)

### Node
A node is a lossless transmitter of energy between componets.

A node has the following fields

* `power` A dictionary where the key is a target component and the value is a vector of VariableRef that represents the flow of energy to each resource
* `sources` A vector of integers that represent the id of the components that send energy to the node.
* `id`

In the JSON file the node simply needs to set and id (and connections).

Buildaggregator calls constructor for each node in json list. The constructor resolves connections and sets power and sources.

Optimizeaggregator sets the inputs equal to the outputs. No new variables are needed.

### Grids

### Connections
Simplify determines which components are connected, i.e. can exchange energy. For balancing markets, the Group object defines which resources are connected to the different markets. 

## Groups

## TimeStruct

# Making new components
An important feature of AggregatorX is that new components can be added to represent physics, markets, resources or behaviour that are not possible with the existing library of components. This section describes the steps that are necessary for adding new components to the software. It simultanously suggest a best practice workflow where some things are not absolutly necessary but will decrease likelihood of errors and make the software and ecosystem easier to maintain.

* Start with a mathematical description, preferably in the style of the Mathematical description of AggregatorX.
* Add new type description. 
    * First write a test that creates an object of the struct (In the following, always start each step by writing a test. Much less likelihood of logical errors and much quicker to remove simple typos).
    * Implement the new struct/type in `AggregatorXComponents`.
    * Add type to the export list of the package and run the test.
    * Add tests for fieldnames and fieldtypes
* Add constructor for the new type
    * Test default constructor
    * Write a test that creates the object. For this you need a system description that includes the new component. The test should then call `buildaggregator()` using the system description.
    * Write a method in `AggregatorXConstructors` that returns the initalized object (make sure it will be called from buildaggregator - check calling signature) and test it.
* Add methods to set variables, constraints and objective terms.
    * Make a test for each method. The type of test will depend on the particular component and method content.
    * Implement method and test it.
    * Remember to include files defined in folder components.
* Make test cases
    * One or more test cases that implements the component and with analytical results
    * Focus on edge cases
    * Test large systems

## Type description

The first step is to define the type as a mutable struct in the AggregatorXMethods file. Making the concrete type a subtype of a meaningful parent is important. Some methods dispatch on the parent type. The necessary field types will vary somewhat between the types. All components must have an id field.

The type must be added to the export list of the package in `AggregatorX.jl`

The "type" key in the JSON file refers to this concrete type and used to dispatch the correct constructor.

## Make constructor

## Methods to define optimization problem

## Testing

The script `runtests.jl` runs a series of test that can be used to verify system behavior after changes have been maded. It uses system descriptions from the `test-systems` folder. 

# Working with the solution

Here are some tips for how to look at the output from the optimization. It primarily a review of key JuMP commands

The JuMP model is stored in the variable `model`. This object contains all the results from the optimization.

Before doing anything else, first check that an optimum has been found `is_solved_and_feasible(model)`. If that is the case then information about the solution can be found with `solution_summary(model)`. 

Next you would probably like to acces the values of the variables in the optimal solution. To do this you need a reference a `VariableRef` object that points to a particular variable in the model. These reference are stored in the the different components. There are several ways to get this. One quick way is if you know the id of the component (see the system description). You can then use `get_component(id, aggregator)` which returns a reference to the component. The component typically has a field (e.g. `power`) which stores a `VariableRef` object. Letting the `VariableRef` object be called `ref`, you can then use `value(ref)`to get its value. Usually one gets a `Vector` of `VariableRef` and you have to use the broadcasting operator in Julia `.`,   `value.(ref)`.

Another way is to access the variables by name. You can find these from `all_variables(model)` that lists all variable names. To get a reference to the variable you can use `variable_by_name(model, "name")`