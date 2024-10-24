The work flow of the software is as follows:

* Describe your system of interest in a json file. This file is refered to as the *system description*. This file can have any name but we fill refer to it as `system.json` as an example
* Import the AggregatorX package, `using AggregatorX`.
* Build the system using `aggregator = buildaggregatorx("system.json")`. What this does is to create objects of AggregatorX types with the number and types of objects and their parameters based on the content of `system.json`. The aggregatorX objects are stored in the variable `aggregator` as a dictionary.
* Create and run optimization of system using `optimizeaggregator(aggregator, optimizer)`. This creates a JuMP model based on the information in the `aggregator` object. It then tries to optimize the model using the optimizer referred to by `optimizer`.
* 