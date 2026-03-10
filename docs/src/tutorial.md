# Tutorial

This chapter goes through the bare minimum steps for setting up a system for analysis. To goal is to get you going as fast as possible.

A good place to get familiar with the system is also to explore the examples which are provided in the form of jupyter notebooks in the [example folder](https://gitlab.sintef.no/securel/securel-wp2/AggregatorX/-/tree/main/examples) in the the git hub repo.

## Installing packages
You need to install `AggregatorX`. The package is not currently registered in Julia's general registry so you need to install it directly from gitlab

```
Pkg.add("git@gitlab.sintef.no:securel/securel-wp2/AggregatorX.git")
```
Especially on windows, the git and ssh libraries causes some glitches and setting these environment variables may help:
```
>ENV["JULIA_SSL_CA_ROOTS_PATH"] = ""
>ENV["JULIA_PKG_USE_CLI_GIT"]=true
```
You will need an optimizer to pass to JuMP (here we chose HiGHS) and it is also often to have access to JuMP functions to analyze the solution
```
Pkg.add("JuMP")
Pkg.add("HiGHS")
```
Finally
```
using AggregatorX, JuMP, HiGHS
```

## Defining your system

Define json file

`sys, aggregator = buildaggregator()`

## Running the optimization

`model = optimizeaggregator(aggregator, HiGHS.optimizer)`

## Analysis

We will just provide some points for how to analyse your solution.

The function `component = get_component(id, aggregator)` is very useful. You just pass it your aggregator object and the component id (defined in your `system.json` file).