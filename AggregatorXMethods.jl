
# --- Optimization propblem definition functions ---

## - Set up variables 

# These are jump specific and should then perhaps be located in a different place
# SimpleBattery
function set_optimization_variables(model::Model, battery::SimpleBattery, timestruct::TimeStruct) 
    battery.chargeref = @variable(model, [1:timestruct.periods])
    typestring = lstrip_last_dot(string(typeof(battery)))
    for i in 1:length(battery.chargeref)
        set_name(battery.chargeref[i], typestring * string(battery.id) * "_charge_"  * "[" * string(i) * "]" )
    end
    # Maybe a dict which relates each load variable to load object that defined it
end

## - Set up constraints - 

function set_constraints(model::Model, charger::SimpleCharger, timestruct::TimeStruct)
    
end