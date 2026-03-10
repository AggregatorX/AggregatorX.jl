## File structure

Let us first point to where you can find things. 

`AggregatorX.jl`

This is where the main module is defined. It only contains a list of function which the module exports (available when `using` the package) as well as an `include` statement for all the files where all the other code as been organized.

`AggregatorXComponents.jl`

The type system is often an essential part of a piece of Julia software and important for software design. This file describes the hierarchy of new abstract types defined in AggregatorX as well as all the conrecte types (i.e `structs`) that may be instantiated. These concrete types typically represent physical (e.g. battery) or conceptual (e.g. a market) objects in the system we want to study. When you want to create a new type to represent some new physical object, you start here by defining the necessary fields that describe the characteristics of the object. The system description you write provide the parameter values that go into these types during a particular run of the software.

`AggregatorXExceptions.jl`

Defines specialized exceptions that are used by the package to provide detailed error information.

`BuildAggregatorX.j`

This file defines the function `buildaggregator()`. What this function does is to take the path of the system description as an argument and return a dictionary that contains instances of the various components defined in `AggregatorXComponents.jl`. It basicall translates what you have defined in your system description to the internal data structure of AggregatorX. The function first parses the system description file into individual components. Each component has a `type` field in the JSON file. The software translates this to an AggregatorX type using a dictionary (called typetable) which translates string type descriptions to a Julia type. It then calls `build_aggregatorx_object()` with the type as an argument. This function call dispatches to different functions depending on the type argument, which contains the appropriate code for that given type. All the instantiated objects are grouped in a dictionary which is returned by `buildaggregator()`. We will refer to this dictionary as the `aggregator` object/dictionary.

`AggregatorXConstructors.jl`

This file contains the definitions of all the different `build_aggregatorx_object()` functions called from `buildaggregator()`. Each of these functions takes the data from the system description file and instantiates the AggragatorX objects with the appropriate fields with data from the system description. Each function returns the instantiated object.

`OptimizeAggregator.jl`

This file contains the single function `optimizeaggregator()`. This function does two things. First it sets up the optimization problem based on the information in the `aggregator` object. This is done by repeated calls to `set_optimization_variables()`, `set_optimization_constraints()` and `set_objective()` which respectively defines the variables, constraints and objective function in a JuMP model. Finally it calls `optimize!(model)` to try to optimize the model and return the (hopefully) feasible solution.

`AggregatorXMethods.jl`

This is the meat and potatoes of the software. This is were the JuMP optimization model is set up. There are specialiced functions for each type of component. The most complex part of the software is how the constrains are set up.

`plz_solve_my_problem.jl`

This friendly file solves whatever problems you might have:D. Just kidding, it is just a script that contains all the commands needed to run the whole optimization procedure. All you need to do is changed the system description file.