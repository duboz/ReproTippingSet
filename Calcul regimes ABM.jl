include("Modele.jl")

# Paramètres pour le calcul des régimes
T = 50  # Horizon temporel (durée)
d = 0.75  # Seuil de durabilité (durée)
r = 0.1  # Seuil de résilience (durée)
N = 100  # Nombre de répliquas des trajectoires (pour des valeurs fixes de facteurs)
dt = 1   # Pas de temps du modèle
B_max = 4.0  # Capacité de charge du milieu
B_min = 1.0  # Seuil minimum de satisfaction pour B
B_0 = 1.0    # Biomasse à t=0
h_0 = 0.0    # Effort à t=0
Z = 100      # Le nombre d'intervalle de discrétisation de B dans [0;B_max]
H = 100      # Le nombre d'intervalle de discrétisation de h dans [0;1]

d_B = B_max / Z
Q = [0.0] # Valeurs de B à chaque pas de discrétisation
for z in 2:Z+1
    push!(Q, Q[end] + d_B)
end

S = falses(Z + 1) # 

function init_satisfaisant()
    for z in 1:Z+1
        if Q[z] >= B_min
            S[z] = true
        end
    end
end

init_satisfaisant()

# Fonction pour générer les facteurs
function facteurs(b_0,h)
    # T, B_0, g, K, α, h, σ_B, Δt -> factors
    f = [T, b_0, 0.25, B_max, 0.25, h, 0.3, dt]
    return f
end

# Temps de séjour
function calcul_ST(trajectoire)
    # calcul du temps de séjour
    traj = columns(trajectoire)[1]
    st_up = st_down = 0.
    for i in 1:length(traj)
    	if traj[i] >= B_min
			st_up += 1. # si delta t == 1
		else
			st_down += 1.
		end
	end
    if traj[1] >= B_min
		return st_up
	else
		return st_down
	end
end

# Temps median de première sortie
function calcul_FET(trajectoire)
    # calcul du temps de première sortie
    traj = columns(trajectoire)[1]
    i = 1
    while i <= length(traj) && traj[i] >= B_min
    	i += 1
    end
    if i > 1
    	return i
    end
    while i <= length(traj) && traj[i] <= B_min
    	i += 1
    end
    if i > 1
    	return i
    end
end

m_trajectoire = zeros(H+1, Z+1, T+1)
regime_MST = zeros(Int, H+1, Z+1)
regime_MFET = zeros(Int, H+1, Z+1)

h_i = 1
for h in range(0,1,H+1)
	MST  = zeros(Z + 1)
	for z in 1:Z+1
		FET = zeros(N)
    	f = facteurs(Q[z], h)
    	for n in 1:N
        	trajectoire, t = model_simulation(f)
        	ST = calcul_ST(trajectoire)
        	MST[z] += ST
        	FET[n] = calcul_FET(trajectoire)
        	m_trajectoire[h_i, z, :] += columns(trajectoire)[1]
    	end
    	m_trajectoire[h_i, z, :] /= N

    	if S[z]
        	if MST[z] / N >= d * T
        	    regime_MST[h_i, z] = 1  # satisfaisant durable
        	else
        	    regime_MST[h_i, z] = 2  # satisfaisant non durable
        	end
    	else
        	if MST[z] / N >= d * T
            	regime_MST[h_i, z] = 3  # non satisfaisant durable
        	else
            	regime_MST[h_i, z] = 4  # non satisfaisant non durable
        	end
    	end
	
    	FET_sorted = sort(FET)
    	fet = 0.
    	if (Z+1) % 2 == 0
        	fet = (FET_sorted[(Z+1)÷2] + FET_sorted[(Z+2)÷2]) / 2
    	else
        	fet = FET_sorted[(Z+1)÷2]
    	end

    	if S[z]
        	if fet >= d * T
        	    regime_MFET[h_i, z] = 1  # satisfaisant durable
        	else
        	    regime_MFET[h_i, z] = 2  # satisfaisant non durable
        	end
    	else
        	if fet >= d * T
        	    regime_MFET[h_i, z] = 3  # non satisfaisant durable
        	else
        	    regime_MFET[h_i, z] = 4  # non satisfaisant non durable
        	end
    	end
	end
	global h_i += 1
end

# Calcul des états résilients
#############################
# Les Q[z] satisfaisants non durables (avec regime_X[z] == 2)
# et non satisfaisants non durables (avec regime_X[z] == 4) appartiennent à
# l'ensemble de points de bascule entre une satisfaction durable et une insatisfaction durable
h_i = 1
for h in range(0,1,H+1)
	for z in 1:Z+1
    	if regime_MST[h_i, z] == 4
        	t = 1
        	while t * dt <= r * T
            	if m_trajectoire[h_i, z, t] >= B_min
                	regime_MST[h_i, z] = 5  # résilient satisfaisant durable
                	break
            	end
            	t += 1
        	end
    	elseif regime_MST[h_i, z] == 2
        	t = 1
        	while t * dt <= r * T
            	if m_trajectoire[h_i, z, t] < B_min 
                	regime_MST[h_i, z] = 6  # résilient non satisfaisant durable
                	break
            	end
            	t += 1
        	end
    	end
	end

	for z in 1:Z+1
    	if regime_MFET[h_i, z] == 4
        	t = 1
        	while t * dt <= r * T
            	if m_trajectoire[h_i, z, t] >= B_min
            	    regime_MFET[h_i, z] = 5  # résilient satisfaisant durable
            	    break
            	end
            	t += 1
        	end
    	elseif regime_MFET[h_i, z] == 2
        	t = 1
        	while t * dt <= r * T
        	    if m_trajectoire[h_i, z, t] < B_min
        	        regime_MFET[h_i, z] = 6  # résilient non satisfaisant durable
        	        break
        	    end
        	    t += 1
        	end
    	end
	end
	global h_i += 1
end

