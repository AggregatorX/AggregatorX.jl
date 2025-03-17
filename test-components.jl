@testset verbose = true "Thermal load" begin
    failed = false

    @testset  "Thermal load defined" begin
        t = @test @isdefined(ThermalLoad);
        failed = isa(t,Test.Fail) ? true : false
    end

    if !failed
        # Field names
        field_names = fieldnames(ThermalLoad)
        @test field_names == (
            :power,
            :load,
            :up_capacity,
            :down_capacity,
            :up_activation,
            :down_activation,
            :up_energy_reserve,
            :down_energy_reserve,
            :temperature,
            :max_temperature,
            :min_temperature,
            :ambient_temperature,
            :heat_capacity,
            :heat_loss_factor,
            :max_power,
            :id
        )

        # Field types
        field_types = [fieldtype(ThermalLoad, i) for i in 1:length(field_names)]
        @test field_types == [
            Vector{AffExpr},
            Vector{Real},
            Dict{Integer, Vector{VariableRef}},
            Dict{Integer, Vector{VariableRef}},
            Dict{Integer, Vector{VariableRef}},
            Dict{Integer, Vector{VariableRef}},
            Dict{Integer, Vector{VariableRef}},
            Dict{Integer, Vector{VariableRef}},
            Vector{Real},
            Real,
            Real,
            Vector{Real},
            Real,
            Real,
            Real,
            Integer
        ]

        # Default constructr
        va = Vector{AffExpr}()
        vr = Vector{Real}()
        d = Dict{Integer, Vector{VariableRef}}()
        r = 1.1
        i = 1.0
        thermalload = ThermalLoad(va,vr, d, d, d, d, d, d, vr, r, r, vr, r, r, r, i)
        @test isa(thermalload, ThermalLoad)

        # Access and modification
        thermalload.id = 2
        @test thermalload.id == 2
    else
        println("Test of definition of thermal load failed, skipping remainin tests")
    end
end