function FixModel!(model::Model)
    solution = Dict(
        v => value(v) for v in all_variables(model)
    )
    for v in all_variables(model)
        if is_binary(v)
            unset_binary(v)
            fix(v, solution[v]; force = true)
        elseif is_integer(v)
            unset_integer(v)
            fix(v, solution[v]; force = true)
        else
            nothing
        end
    end
    return
end
