
# --- Optimization propblem definition functions ---

## - Set up variables 

# These are jump specific and should then perhaps be located in a different place
# SimpleBattery
function set_optimization_variables(model::Model, battery::SimpleBattery, timestruct::TimeStruct) 
    @variable(model, charge[1:timestruct.periods])
    # Maybe a dict which relates each load variable to load object that defined it
end

## - Set up constraints - 