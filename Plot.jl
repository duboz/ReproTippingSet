using CairoMakie

# Choose the data to plot (regime_MST or regime_MFET)
data = regime_MST
file_name = "regime_MST"

# Prepare data for plotting
function build_results_for_plot(r)	
	copy_r = r[:,:]
	indices = findall(x -> x == 2, r[:,:])
	for i in indices
		copy_r[i] = 5
	end
	indices = findall(x -> x == 4, r[:,:])
	for i in indices
		copy_r[i] = 5
	end
	indices = findall(x -> x == 5, r[:,:])
	for i indices in
		copy_r[i] = 2
	end
	indices = findall(x -> x == 6, r[:,:])
	for i in indices
		copy_r[i] = 4
	end
	return copy_r
end

data  = build_results_for_plot(data)

# Variables for figure and color settings
figure_size = (600, 400)
font = "CMU Serif"
color_gradient = cgrad([:green, :lightgreen, :red, :pink, :white], categorical = true)
color_range = (1., 5)
aspect_ratio = Aspect(1, 0.9)
cbar_label = "Régime"
cbar_ticks = ([1.44, 2.22, 3., 3.78, 4.56], [
    "sat. durable", "rés. sat. durable",
    "non sat. durable",
    "rés. non sat. durable", "ens. de bascule"
])


# Function to create and return the figure
function create_heatmap(regime)
	fig = Figure()
	Label(fig[1,1],file_name,tellwidth=false, fontsize=12, halign=:center)
	ax = Axis(fig[2, 1], xlabel=L"h", ylabel=L"B", aspect=DataAspect()) 
    hm = heatmap!(ax, regime, figure=(size=figure_size, font=font), colormap=color_gradient)
	
    hm.colorrange = color_range
    
    # Add color bar with specific ticks and labels
    cbar = Colorbar(fig[2, 2], hm, label=cbar_label)
    cbar.ticks = cbar_ticks
    
    # Set the xticks for the heatmap, normalizing from 0-100 to 0-1
    ax.xticks = (0:20:100, string.(0:0.2:1))  # X-axis ticks positions and corresponding labels
    ax.yticks = (0:25:100, string.(0:1:4))                         # Y-axis ticks from 0 to 4
    
    # Adjust the layout size
    colsize!(fig.layout, 1, Auto(1))
    rowsize!(fig.layout, 2, Auto(1))
    return fig
end
# Generate, save and display the figure
fig = create_heatmap(data)
save(string(file_name,".png"),fig)
fig

