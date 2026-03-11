# AggregatorX

AggregatorX is a software (and a framework) with a goal to facilitate the analysis of optimal operation of aggregated energy resources that pariticpate in multiple markets.

### Motivation

Determining the optimal operation of energy resources in some markets is a typical goal for actors or researchers working in the energy sector. However, when there are many different, interdependent resources that can paricipate in many different balancing or energy markets, the task of setting up an optimization problem can be quite time consuming and challenging. 

The goal of AggregatorX is to facilitate this process. By automating a lot of the manual work for setting up the problem, the user can focus on more 'higher order' questions about how the system behaves. 

AggregatorX is both a framework and a piece a software. The framework is general and could in principle be implemented in any software stack. The current implementation is in the Julia programming language, the JuMP optimization modelling language and using JSON for describing system (The framwork could just as well be implemented in a stack using Python, Pyomo and YAML respectively). A particular optimization solver is not part of the framework and can be freely choosen by the user as long as it is compatiple with the optimization modelling language, being JuMP for the current implementation (HiGHS is currently used for all examples and tests).

The main idea behind the framework is that energy resources and markets can be modelled as *discrete* components connected by ideal connections for transfer of energy. The idea is that most flexible energy resource and markets have many similar features and the software automates all the manual work of setting up the the optimization model (variables, constraints, objective function) based on a high level description of the system under study. Another key features is the ability og *aggregate* multiple resources for a single bid to a given balancing market. 

The system comes with many predfined 'components' (and more are added continously) and the user can just 'connect' these components and give them the correct parameters (in the JSON system file) to define the system and then only a single function call is necessary to run the optimization. Having predefined components reduces implementation time and chance for errors. 

A user can also (relatively) easily define new components if the existing are not sufficient to describe the system of interest.

### Work flow

Here is a short description of a typical the work flow, hopefully to illustrate the simplicity of setting up and running an optimization model:

* Describe your system of interest in a JSON file. This file is refered to as the *system description*. This file can have any name but typically called `system.json` and we will use this as a name in the documentation.
* Import the AggregatorX package, `using AggregatorX`.
* Build the system using `aggregator = buildaggregatorx("system.json")`. What this does is to create objects of AggregatorX types with the number and types of objects and their parameters based on the content of `system.json`. The aggregatorX objects are stored in the variable `aggregator` as a dictionary.
* Create and run an optimization of the system with `optimizeaggregator(aggregator, optimizer)`. This creates a JuMP model based on the information in the `aggregator` object. It then tries to optimize the model using the solver referred to by `optimizer`.