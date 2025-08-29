In the system description file (json), there are many parameters that need to be given values. There are several ways that this information can be provided, and the way it is interpreted depends on other information in the system, primarily the timestructure object. It is the job of `parse_data()` to handle all the possible cases smoothly.

The `data` read from the json file is in the component constructor sent to a method of the form `parse_data(data::*, aggregator::Aggregator)`. The aggregator is passed to have access to all relevant information, especially the `TimeStruct`.  The `data` element can either be a number, a string, a vector or a dictionary (the only things returned by the json parser). The following methods exists

`parse_data(::Dict, ::Aggregator)` A dictionary is returned if the parameter is stochastic, with different values for different scenarios (dictionary keys). Calls `parse_data(::Dict, ::StochasticTimeStruct)`
`parse_data(::Any, ::Aggregator)` This should be the fallback method, but currently handles all other cases. It currently handles cases if the first parameter is string, differently if it is a full path or a filename. Calls `parse_data(::String)`

(The remaining parse_data should be renamed to _parse_data to indicate they are "local".)

`parse_data(::Dict, ::StochasticTimeStruct)` A dictionary where each value is the value of the parameter for each scenario. Currently assumes `data` is a vector for each key and looops through elle keys/vector elements and assigns to DenseAxisArray which is returned. MISSING: Single values, strings

`parse_data(::String)` Assumes this is a path to a file which contains a column of numbers which is returned.

`parse_data(::Vector{<:Number})` Simply returns the number

`parse_data(::Vector{<:Any})`. Obsolete. Checks if elments are strings or numbers. It then dispatches on the element type as below. The Number version is never reached since the previous method is called first. The vector of string version should also be first by first passing through the above methods

`parse_data(element::Number, data::Vector{Any})` Called from `parse_data(::Vector{<:Any})`, never reached.

`parse_data(element::AbstractString, data::Vector{Any})`. For future versions. A vector of string that can pass functions that provide the necessary parameters.