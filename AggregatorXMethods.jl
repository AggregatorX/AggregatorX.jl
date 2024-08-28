
# --- Optimization component specific methods ---
# When new AggregatorX components are introduced, new methods for variables and constraints must be set
# These are JuMP specific and should be loaded before and as part of optimizeaggregator() call

# - Variables -

# SimpleBattery
function set_optimization_variables(model::Model, battery::SimpleBattery, timestruct::TimeStruct) 
    battery.chargeref = @variable(model, [1:timestruct.periods])
    typestring = lstrip_last_dot(string(typeof(battery)))
    for i in 1:length(battery.chargeref)
        set_name(battery.chargeref[i], typestring * string(battery.id) * "_charge_"  * "[" * string(i) * "]" )
    end
    # Maybe a dict which relates each load variable to load object that defined it
end

function set_optimization_variables(model::Model, battery::SimpleCharger, timestruct::TimeStruct) 
    # No additional variables needed.
end


## - Constraints -

function set_constraints(model::Model, charger::SimpleCharger, timestruct::TimeStruct)
    
end