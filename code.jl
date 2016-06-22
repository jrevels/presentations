module ForwardDiffPresentation

using Plots
using ForwardDiff
using BenchmarkTools

# ForwardDiff vs. autograd benchmarks can be found in the ForwardDiff repository:
# https://github.com/JuliaDiff/ForwardDiff.jl

################################
# Test function and derivative #
################################

testf(x) = exp(x) / sqrt(sin(x)^3 + cos(x)^3)

function testderiv(x)
    numerator = 3*exp(x)*((sin(x)^2)*cos(x) - sin(x)*(cos(x)^2))
    denominator = 2*(sin(x)^3 + cos(x)^3)^(3//2)
    return testf(x) - numerator/denominator
end

#########################
# Approximation methods #
#########################

finitediff(f, x, h) = (f(x + h) - f(x - h)) / 2h
complexdiff(f, x, h) = imag(f(x + im*h)) / h
dualdiff(f, x, h = nothing) = ForwardDiff.partials(f(ForwardDiff.Dual(x, one(x))), 1)

##############################
# Error calculation/plotting #
##############################

const HRANGE = [10.0^i for i in -20:-1]

function deriverr(deriv, x, hrange = HRANGE)
    true_deriv = testderiv(x)
    return Float64[max(abs(deriv(testf, x, h) - true_deriv) / abs(true_deriv), eps(Float64)) for h in hrange]
end

function deriverr_plot(x, hrange = HRANGE)
    finite_error = deriverr(finitediff, x, hrange)
    complex_error = deriverr(complexdiff, x, hrange)
    dual_error = deriverr(dualdiff, x, hrange)
    plot(hrange, finite_error,
         ylims = (1.0e-17, 1.0),
         linestyle = :dot,
         linewidth = 3,
         lab = "finite")
    plot!(hrange, complex_error,
          ylims = (1.0e-17, 1.0),
          linestyle = :dash,
          linewidth = 3,
          lab = "complex")
    plot!(hrange, dual_error,
          ylims = (1.0e-17, 1.0),
          lab = "dual")
    xaxis!("\$h\$ size", :log10, fontsize = 10)
    yaxis!("relative error", :log10, fontsize = 10)
end

####################################
# Performance calculation/plotting #
####################################

function performance_plot()
    hard_time = 97 # time(minimum(@benchmark(testf(1.5))))
    finite_time = 261 # time(minimum(@benchmark(finitediff(testf, 1.5, 1e-5))))
    complex_time = 380 # time(minimum(@benchmark(complexdiff(testf, 1.5, 1e-10))))
    dual_time = 188 # time(minimum(@benchmark(dualdiff(testf, 1.5))))
    bar([1], [finite_time / hard_time], lab = "finite",
        bar_width = 0.5,
        xlims = (0.5, 3.5),
        ylims = (0.0, 5.0))
    bar!([2], [complex_time / hard_time], bar_width = 0.5, lab = "complex")
    bar!([3], [dual_time / hard_time], bar_width = 0.5, lab = "dual")
    xticks!(Real[])
    yaxis!("relative performance", fontsize = 10)
end

######################################
# Perturbation confusion pseudo-code #
######################################

# # D(f, x_0) -> df/dx evaluated at x_0
# const D = ForwardDiff.derivative
#
# # nested, closed over differentiation
# D(x -> x * D(y -> x + y, 1), 1)
#
# # correct answer
# df_dx_1 = D(x -> x * D(y -> x + y, 1), 1)
# df_dx_1 = D(x -> x * (y -> 1)(1), 1)
# df_dx_1 = D(x -> x, 1)
# df_dx_1 = (x -> 1)(1)
# df_dx_1 = 1
#
# # what ForwardDiff will compute
# df_dx_1 = D(x -> x * D(y -> x + y, 1), 1)
# df_dx_1 = D(x -> x * Eps[x + (1 + ϵ)], 1)
# df_dx_1 = Eps[(1 + ϵ) * Eps[(1 + ϵ) + (1 + ϵ)]]
# df_dx_1 = Eps[(1 + ϵ) * Eps[2 + 2ϵ]]
# df_dx_1 = Eps[(1 + ϵ) * 2]
# df_dx_1 = Eps[2 + 2ϵ]
# df_dx_1 = 2

end # module
