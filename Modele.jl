using DynamicalSystems
using Random
using Distributions

function exploited_ecosystem_rule(u, p, n) # here `n` is "time", but we don't use it.
    Bn = u[1]
    g, K, α, h, σ_B, Δt  = p # system parameters
    ϵ = rand(Normal(0., 0.3))
    for i in 1:8
    	Bn += (g * (K - Bn) * (Bn - α) - h * Bn +  σ_B * ϵ) * Δt/8.
    	if Bn < 0
    		Bn = 0.
    	end
    end
    return SVector(Bn)
end

function model_simulation(factors)
	# factors[1] = duration
	# factors[2] = B0
	# factors[2:length(factors)] = parameters
	exploited_ecosystem = DeterministicIteratedMap(exploited_ecosystem_rule, factors[2], factors[3:length(factors)])
	X, t = trajectory(exploited_ecosystem, factors[1])
	return X, t
end

## Simuler
#f = [100, 0.5, 0.25, 4., 0.25, 0.8, 0.3, 1.]
#trajectoire, t = model_simulation(f)

## Visualiser les résultats
#using CairoMakie
#plot(trajectoire[:,1])


