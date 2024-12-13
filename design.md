# AggregatorX - software design

This document explains how (and to some degree why) the package AggregatorX is designed and used. The main purpose is to enable users to efficiently extend and contribute to the code.

# Introduction

## Usage

Before diving into the details let us give a breif description of the motivation of the software and a typical workflow.

### Motivation

The main motivation for AggregatorX is to create a piece of software that simplifies the analysis of use flexible energy resources and their participation in multiple energy and balancing markets. By analysis we here mean optimization models that try to optimize the scheduled energy flow according to some defined profit. The idea is that must flexible energy resource and markets have many similar features and the software automates all the manual work of setting up the the optimization model (variables, constraints, objective function) based on a high level description of the system under study.

### Work flow

Here is a short description of atypical the work flow, hopefully to illustrate the simplicity of setting up and running an optimization model:

* Describe your system of interest in a JSON file. This file is refered to as the *system description*. This file can have any name but typically called `system.json` and we will use this as a name in the following.
* Import the AggregatorX package, `using AggregatorX`.
* Build the system using `aggregator = buildaggregatorx("system.json")`. What this does is to create objects of AggregatorX types with the number and types of objects and their parameters based on the content of `system.json`. The aggregatorX objects are stored in the variable `aggregator` as a dictionary.
* Create and run optimization of system using `optimizeaggregator(aggregator, optimizer)`. This creates a JuMP model based on the information in the `aggregator` object. It then tries to optimize the model using the optimization solver referred to by `optimizer`.

## Some words (of wisdom)
A conceptual and mathematical description of what the software does is provided in the document `mathematical-description.tex`. It is probably a got idea to read this document first to understand to what the software tries to acheive, before diving into the nitty-gritty of the software design. 

There are also some design-choices that might be somewhat non-intuitive (hopefully they will gradually become intuitive, otherwise it was probably a bad design-choice). We provide a list of these here and an attempt at explnation (and justification of the choice). You can skip this on a first read and refer back to it when necessary.

* The objective sees to *maximize* profits. Any revenue (e.g. selling energy) should therefore be *negative*, and costs (e.g. buying energy) should be *positive*.

Some users may also not be familiar with the Julia programming language or the JuMP modelling language. We therefore provide a list of some terms that are used in the following that might be unfamiliar for these readers. Again, this may be skipped on a first read, and refered back to when confusion sets in.

* `VariableRef`. This is a Julia type defined by JuMP. An instance of this type is a reference to an internal JuMP optimization variable. I.e it provides access to the optimization variable from the scope where the VariableRef is defined. A Variable ref is returned by JuMP macros that create variables.

# Software design

OK, let's take a deep dive into the nitty gritty (Oh boy, I can't wait...)

## File structure

Let us first point to where you can find things. 

`AggregatorX.jl`

This is where the main module is defined. It only contains a list of function which the module exports (available when `using` the package) as well as an `include` statement for all the files where all the other code as been organized.

`AggregatorXComponents.jl`

The type system is often an essential part of a piece of Julia software and important for software design. This file describes the hierarchy of new abstract types defined in AggregatorX as well as all the conrecte types (i.e `structs`) that may be instantiated. These concrete types typically represent physical (e.g. battery) or conceptual (e.g. a market) objects in the system we want to study.

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

# Connections
Between components. Groups store internally the connected resources and balancing markets. 


# Components



## Markets
Concrete market subtypes must implment at least the following fields: 

* type - type of market, ie the concrete type
* power - Dict(Integer->Vector(VariableRef)) the power flowing to or from the market
* price - the cost of energy
* resource - the resource (component) the market is connected to (note this is different from source in other componets which is the input of the component. Resource can be both input and output.)
* sign : 1 if the market is a source of energy, (-1) if the market is a sink of energy.
* id - A unique identifier.

The framework assumes that a market is only connected to a single component.

If the market is to be connected to a group it must also implement a `class` field which represent the technical requirements of the market, and thus which groups may be connected to it (this is primarily a check for mistakes in the connections in the system description where wrong markets may be connected to wrong type of group/resources). An optional `name` may also be included which is used for labeling variables and constraints and may be useful when interogating the optimization solution.

When `buildaggregator()` is called the system reads all the market entries in the JSON file, determines the type they represents, and calls the appropriate constructor (dispatching on the market type). As a minimum, the constructur checks the connections and finds the market's id to determine which component it is connected to and assigns this to the resource field. 

It then instantiates power as a dictionary with one key value pair, Resource->empty vector of VariableRef (a julia type, note that this must be reimplemented to use the system with a different modelling package). This so that when the actual VariableRef is created, it can ba assigned to this key (**This seems redundant. One could to this instantiation in variable creation method. No probably need it for instantiating market object**)

The concrete market objects are stored in a vector of type market. This vector is stored in a dictionary value in the aggregator object

After building the aggregator object, the optimization problem is set up by calling `optimizeaggregator()`. This function goes through the three steps of setting up an optimization problem: define variables, define constraints, define objective function.

For markets the the minimum variable creation simply is a vector of variable ref an assigns this to the power dictionary. Special markets might add additional variables

The markets do not in general have to impose any real constrainta. However, for markets that are sinks of energy (energy is sold to the market) the power is constrained to be equal to the output power of the connected resource (this is just a convenience implementation, having the power to the market available in the market object is more convenient than having to query the power in the resource connecte to the market)

`optimizeaggregator()` calls `set_objective()`. This function loops over alle markets (other components that adds costs may be included, e.g. grid tariffs or degradation of batteries). For each market it calls `get_objective_term` that dispatches on the type of market. Any type of function of the variables may be used to describe the market (keeping in mind that anything but linear functions will make the problem harder to solve. Nonlinear functions is currently untested, there might be reasons why this will break the code, e.g. where variables are defined as AffExpr (linear expressions in JuMP)), but a typical implementation will be the price times the power * (-sign). Recall that the sign is 1 if power flow **from** the market, i.e. a cost (unless the price is negative). Power (as all varibles) is always positive (unidirectional connections).

## Node
A node is a lossless transmitter of energy between componets.

A node has the following fields

* `Power` A dictionary where the key is a target component and the value is a vector of VariableRef that represents the flow of energy to each resource
* `Sources` A vector of integers that represent the id of the components that send energy to the node.
* `id`

In the json file the node simply needs to set and id (and connections).

Buildaggregator calls constructor for each node in json list. Constructur resolves connections and sets power and sources.

Optimizeaggregator sets the inputs equal to the outputs. No new variables are needed

## Making new components
An important feature of AggregatorX is that new components can be added to represent physics, markets, resources or behaviour that are not possible with the existing library of components. This section describes the steps that are necessary for adding new components to the software. It simultanously suggest a best practice workflow where some things are not absolutly necessary but will decrease likelihood of errors and make the software and ecosystem easier to maintain.

* Start with a mathematical description, preferably in the style of the Mathematical description of AggregatorX.
* Add new type description. 
    * First write a test that creates an object of the struct (In the following, always start each step by writing a test. Much less likelihood of logical errors and much quicker to remove simple typos).
    * Implement the new struct/type in `AggregatorXComponents`.
    * Add type to the export list of the package and run the test.
* Add constructor for the new type
    * Write a test that creates the object. For this you need a system description that includes the new component.. The test should then call `buildaggregator()` using the system description.
    * Write a method in `AggregatorXComponents` that returns the initalized object (make sure it will be called from buildaggregator - check calling signature) and test it.
* Add methods to set variables, constraints and objective terms.
    * Make a test for each method. The type of test will depend on the particular component and method content.
    * Implement method and test it.
* Make test cases
    * One or more test cases that implements the component and with analytical results
    * Focus on edge cases
    * Test large systems

### Type description

The first step is to define the type as a mutable struct in the AggregatorXMethods file. Making the concrete type a subtype of a meaningful parent is important. Some methods dispatch on the parent type. The necessary field types will vary somewhat between the types. All components must have an id field.

The type must be added to the export list of the package in `AggregatorX.jl`

The "type" key in the Josn file refers to this concrete type and used to dispatch the correct constructor.

## Working with solution
The JuMP model is stored in the variable `model`

is_solved_and_feasible(model)

solution_summary(model)

A good place to start is `all_variables(model)` that lists all variable names

most of the interesting power flows are stored in the power field of the different resources which is a vector of variableref. Use value.(x) to get value



To get a variable you can assign x = variable_by_name(model, "name")