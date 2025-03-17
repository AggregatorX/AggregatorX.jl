@testset verbose = true "Thermal load" begin
    failed = false

    @testset  "Thermal load defined" begin
        t = @test @isdefined(ThermalLoad);
        failed = isa(t,Test.Fail) ? true : false
    end

    if !failed
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
    else
        println("Test of definition of thermal load failed, skipping remainin tests")
    end
end