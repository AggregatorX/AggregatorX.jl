# Groups

This pages describes conceptually how groups work and how they interact with *markets* and *resources*

The essence of the group is that they aggregate the flexibility of the resources and share this flexibillity among the markets attached to the group. At the same they ensure that requirements from the markets are met (requirements from the resources are handled by the resources)

Each group may define variables for *capacity*, *activation*, *energy_reserve*, both for up-regulation and down-regulation as needed. During construction these are generated as empty containers of VariableRef (TODO: also support other timestructures). We will refer to these as *balancing variables*.

Similiarly resources may define variables for *capacity*, *activation*, *energy_reserve*. These are similiary generated as empty containers during construction (TODO: support other timestructures).

Finally the markets connected to the groups also set up the same containers for these variables. The markets are typically first stage variables, but may also be second stage variables.

When the optimization problem is set up the resources will initalize the balancing variables (for every group they belong to) in the model according to the TimeStruct and the component (first or second stage variables). Similarly the groups initalize balancing variables for the balancing variables for every resource in the group.

The resource define any constraints that constrain the balancing variables based on their physical (or other) limitations.

The groups are connected to set of markets and capacity and/or activation is sold to these markets. The group sums up all the available capacity from markets and sets a constrain that this must be larger or equal to what is sold to the markets.¨

The markets may also define a minimum energy endurance (maximum of the connected markets). This is multiplied by the sold capacity (maybe sum for each market) and defines a minimum energy reserve that must be available from the resources.

The groups sum up the capacities and activations of the connected markets. The capacity and activaiton variables of these markets may be a combination of first and second stage variables. The total sold to the market is defined as a second stage variable and calculated as

```math
r^T_{st} = \sum r_{it} + \sum r_{ist} \quad \forall s \in S
```

The relation between the balancing sold and balancing available must thus hold for all scenarios.

Problem: What if mix of first and second stage variables?