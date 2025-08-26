# Groups

This pages describes conceptually how *groups* work and how they interact with *markets* and *resources*

The essence of the group is that they aggregate the flexibility of the resources contained in the group and share this flexibillity among the markets attached to the group. At the same they ensure that requirements from the markets are met (requirements from the resources are handled by the resources)

Each group struct may define variables for *capacity*, *activation*, *energy_reserve*, both for up-regulation and down-regulation as needed. We will refer to these collectively as *balancing variables*. These variables represent the total balancing quantity provided by the resources in the group. E.g. for capacity ``r`` for a given group ``g``

```math
r_{gt} = \sum_{i\in R_g} r_{igt}
```

Since the value is tied to balancing variables attached to the resources, they are not strictly free decision variables, but rather secondary (convenience) expressions.

During construction these are generated as empty containers (at the moment only Vector{VariableRef}). The container type depends on the timestructure. The constructors calls different methods to initalize containers depending on the timestructure (not yet implemnted). 

The balancing variables for the groups represent the full stochastic timestructure if that is used. Resources may be first or second stage and resources which are first stage must then be spread acrosss the full set of the balancing structures. Similarly for markets.

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

A resource has a certain balancing capacity ``r_{it}`` which may be distributed accross the groups it is connected to ``G_i``. The capacity provided to the group is ``r_{igt}``. This last variable is defined as part of the resource.

```math
r_{it} \geq \sum_{g in G_i} r_{igt}
```

From the perspective of the group, it contains multiple resources ``R_g`` and the total capacity available to the group is

```math
r_{gt} = \sum_{i in R_g} r_{igt}
```

In a general stochastic setting the capacities from the resource may be both first and second stage variables. If second stage we get the relation

```math
r_{ist} \geq \sum_{g in G_i} r_{igst} \quad \forall s \in S
```

In a stochastic setting, from the perspective of the group, the group must be able to sum up both first and second stage variables. We thus get

```math
r_{gst} = \sum_{i in R_g} r_{igt} + r_{igst} \quad \forall s \in S
```

The capacity sold to markets may be both first ``r_{mt}`` and second stage ``r_{mst}`` variables. The total sold (x) by the group is thus

```math
r_{gst}^{x} = \sum_{m\in M_g} r_{mt} + r_{mst} \quad \forall s \in S
```

We thus get the constraint

```math
r_{gst}^{x} \leq r_{gst} \quad \forall s \in S
```

Problem: What if mix of first and second stage variables?