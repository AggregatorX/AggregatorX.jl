This piece of software is currently under **Development**. While it is the intention that the main branch is stable and provides the described functionality, testing is limted so far and breaking changes may occur. **Contributions** are welcome and may speed up the process to an inital (alpha/beta) release.


# Introduction

AggregatorX provides a high level, efficient modelling framework for the analysis of distributed, flexible energy resources and their participation in various energy markets. By analysis, we here primarily mean optimization.

# Usage and documentation
To get started check out the [documentaiont](https://aggregatorx-f00494.pages.sintef.no/). The Introduction section gives a conceptual overview of the framework, while the Tutorial section gives a minmal working example. For a deeper dive, read through the rest of the documentation.

To get started, the `examples` folder contains a few Jupyter notebooks that can serve as good tutorials to get started. If you download this files, make sure you also get the `data` folder which contains data needed in the examples.

(An incomplete, but more mathematically detailed description can be found as a LaTeX document `mathematical-description.tex` which can be found in the `docs\tex` folder. This file is at the moment not complete and can not be used as a reference but can be used to get some background information on how the optimization model is constructed)

## Prerequisites

AggregatorX uses various other pieces of software and a knowledge of this will help in it's understanding

* The software is written in *Julia*.
* To express the optimization the modelling language *JuMP* is used (this allows your own choice of solver).
* The system you want to study must be expressed in a *JSON* format.

If there are some of these you havn't heard of, it might be a good idea to check out an introductio to them first. 

## Nano-introduction

Please refer to the above list of documentation for a solid introduction. Here follows a nanoscopic description to explain how things are put togheter.

First add the necessary package to Julia

```
Pkg.add("git@gitlab.sintef.no:securel/securel-wp2/AggregatorX.git")
Pkg.add("HiGHS") # arbitrary solver supported by JuMP

using AggregatorX
using HiGHS 
```

Then decide upon the system you want to study (resources, markets, and how these are connected and grouped, parameters, etc.). This information is entered into a JSON file. Refer to the documentation for the syntax.

You then pass this JSON file to the software, which generates the appropriate internal representation of the system.

```
sys, aggregator = buildaggragtor("system.json")
```
Next you call another function wich takes this information, sets up the optimization problem automatically (using JuMP) and tells it to solve the problem with the solver you have specified. 

```
model = optimizeaggregator(aggregator, HiGHS.Optimizer)
```

That's it! Simple, eh? The model object contains the optimal solution. See the documentation for how to access it.

# Reference

If you use this package, please refer to one of these references.

# Acknowledgements

This work has been supported by...