#=
since we're dealing with user input, it makes sense to build in some checks to the functions 
so that mistakes are obvious and not mysterious.
=#
# verify that a linecode is one that makes sense
function verify_line_inputs(line_input)
    line_colors = ["RD", "BL", "YL", "OR", "GR", "SV", "All"]
    if !(line_input in line_colors)
        error("ERROR: line must be one of: RD, BL, YL, OR, GR, SV, or All")
    else 
        return(line_input)
    end
end



