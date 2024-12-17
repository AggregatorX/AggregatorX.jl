
# Introduction

AggregatorX provides a high level, efficient modelling framework for the analysis of distributed, flexible energy resources and their participation in various energy markets. By analysis, we here primarily mean optimization.

# Usage and documentation
There are three sources of documentation:

* A mathamatical description of the software is provided in a LaTeX document `mathematical-description.tex` which can be found in the `\tex` folder. This provides a precise mathematical description of the the optimization model (i.e variables, constraints and objective function`. However it does not provide much information about the software implementation. That can be found in the next bullet point.
* The file `design.md` provides a more detailed description of the software, how it is structured, and importantly how it can be extended if the current functionality is not sufficient. 
* To get started with using the software, a jupyter notebook is provided that provides some simple examples of how the software is used.

## Prerequisites

AggregatorX uses various other pieces of software and a knowledge of this will help in it's understanding

* The software is written in *Julia*.
* To express the optimization the modelling language *JuMP* is used (this allows your own choice of solver).
* The system you want to study must be expressed in a *JSON* format.
* Documentation is written in *LaTeX*, *Markdown* and *Jupyter Notebook*

If there are some of these you havn't heard of, it might be a good idea to check out an introductio to them first. 

## Nano-introduction

Please refer to the above list of documentation for a solid introduction. Here follows a miniscule to description to explain how things are put togheter.

The first thing you do is decide upon the system you want to study (resources, markets, and how these are connected and grouped, parameters, etc.). This information is entered into a JSON file. By passing this file to a function in the software, the information is converted to an internal data structure in the software. Next you call another function wich takes this information, sets up the optimization problem automatically (using JuMP) and tells it to solve the problem with the solver you have specified. Done! Simple, eh?
