#***********************************************************************************
using JuMP
using XLSX
using Gurobi
using Plots
using DataFrames
#***********************************************************************************


#***********************************************************************************
# Read data from excel file
xf = XLSX.readxlsx("vrpData.xlsx")
distances_sheet = xf["distances"] 
repairTimes_sheet = xf["repairTimes"]

Nodes = convert(Matrix{Int}, distances_sheet["A2:A32"]) # Number of nodes
Customers = convert(Matrix{Int}, distances_sheet["A3:A32"]) # Number of customers
Demand = convert(Matrix{Float64}, repairTimes_sheet["B2:B31"]) # Repair Demands in Time
Demand = vcat([0], Demand)

Cost = convert(Matrix{Float64}, distances_sheet["B2:AF32"]) # Distances/Transportation Costs

N = length(Nodes) # Set of Nodes with depot
C = length(Customers) # Number of customers
K = 10 # Number of technicians
working_capacity = 6.0 # Maximum working time (hours)
D = sum(Demand)  # Large constant for subtour elimination
#***********************************************************************************


#***********************************************************************************
VRP = Model(Gurobi.Optimizer)

# Decision variables
@variable(VRP, x[1:N, 1:N, 1:K], Bin) # If technician k is assigned to go directly from node i to node j
@variable(VRP, y[1:N, 1:K], Bin) # If technician K visits customer I
@variable(VRP, z[2:N, 1:K] >= 0) # Load carried by technician k arriving at customer i

# Objective function: Minimize total distance traveled
@objective(VRP, Min, sum(Cost[i,j] * x[i,j,k] for i in 1:N, j in 1:N, k in 1:K))

# Constraints
# 1. Each customer is visited exactly once
@constraint(VRP, [i in 2:N], sum(y[i,k] for k in 1:K) == 1) # Visit every customer exactly once

# 2. Time capacity for each technician
@constraint(VRP, [k in 1:K], sum(Demand[i] * y[i,k] for i in 2:N) <= working_capacity)

# 3.Flow conservation and linking x and y variables -It ensures that if a vehicle arrives at or leaves a node, that node must be visited by the vehicl
@constraint(VRP,[h = 1:N, k = 1:K], sum(i == h ? 0 : x[i, h, k] for i = 1:N) == y[h, k])
@constraint(VRP,[h = 1:N, k = 1:K], sum(j == h ? 0 : x[h, j, k] for j = 1:N) == y[h, k])

# 4. Subtour elimination with time load constraint
@constraint(VRP, [i in 2:N, j in 2:N, k in 1:K], z[i,k] - z[j,k] >= Demand[i] - (1 - x[i,j,k]) * D)

# 5. All technicians should start from the central location
@constraint(VRP, [i = 2:N, k = 1:K], y[1,k] >= y[i, k])

# 6. All technicians should end at the central location
@constraint(VRP, [k = 1:K], sum(x[i, 1, k] for i in 2:N) == 1)

# 7. If technician k visits customer i, his load should be at least d[i]
@constraint(VRP, [i in 2:N, k in 1:K], z[i, k] >= d[i]*y[i, k]) 

# 8. If technician k visits customer i, his load should be at most working_capacity
@constraint(VRP, [i in 2:N, k in 1:K], z[i, k] <= working_capacity*y[i, k])
#***********************************************************************************


#***********************************************************************************
# Solve the VRP
set_time_limit_sec(VRP, 10) # Time limit
optimize!(VRP)
#***********************************************************************************


#***********************************************************************************
println("------------------------------------")
global technicians = 0

for k = 1:K
    current_node = 1  # Start from the depot (node 0)
    route = []  # To store the route for technician k

    has_route = false

    while true
        push!(route, current_node - 1)  # Add current node to the route (adjusting for 0-indexing)
        next_node = 0  # Initialize the next node as 0 (depot)

        for j = 1:N
            if value(x[current_node, j, k]) >= 0.999999
                next_node = j
                has_route = true
                break
            end
        end

        if next_node == 1 || next_node == 0  # If we return to the depot or there's no further node
            push!(route, 0)
            break
        end

        current_node = next_node
    end

    if has_route
        println(join(route, " -> "))
        global technicians += 1
    end
end

println("====================================")
for k = 1:K
    println("Technician ", k, ":")
    for i = 1:N
        for j = 2:N
            if value(x[i, j, k]) >= 0.999999
                println(" - Arrives at customer ", j - 1, 
                        " (Demand serviced: ", d[j], ")", 
                        " with load (capacity left) ", round(value(z[j, k]), digits=3))
            end
        end
    end
    println("------------------------------------")
end
println("====================================")


println("------------------------------------")
total_demand_covered = zeros(K)
for k in 1:K
    total_demand_covered[k] = sum(value.(d[i])*value.(y[i, k]) for i in 2:N)
    println("Demand covered by technician ", k, ": ", round(total_demand_covered[k], digits=3))
end

println("Total demand covered: ", round(sum(total_demand_covered), digits = 3))


println("------------------------------------")
println("Total Cost = ", round(objective_value(model), digits=2))
println("Total technicians used: ", technicians)

