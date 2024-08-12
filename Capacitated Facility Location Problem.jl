# Capacitated Facility Location Problem (CFLP) Optimization Script
# Author: Alexander Arnogiannakis
# Description: This script uses Gurobi to solve the Capacitated Facility Location Problem (CFLP).
# The goal is to determine which facilities to open and which customers each facility should serve
# to minimize the total cost while respecting facility capacities.

# Load required packages
using Gurobi
using JuMP
using Plots

# Load facility location data (assumed to be in the same directory or adjust the path accordingly)
include("Facility_Location_Data.jl")

# Number of customers and facilities
C = length(Total_Distances[:, 1])  # Number of customers
F = length(Fixed_Cost)  # Number of facilities

# Initialize the optimization model
CFLP = Model(Gurobi.Optimizer)

# Decision variables:
@variable(CFLP, x[1:F], Bin)  # Binary variable indicating if a facility f is open
@variable(CFLP, y[1:C, 1:F] >= 0)  # Fraction of customer c’s demand satisfied by facility f

# Objective function: Minimize the total cost
@objective(CFLP, Min, sum(x[f] * Fixed_Cost[f] for f in 1:F) +
                      sum(h[c] * tsp_cost[c, f] * y[c, f] for c in 1:C, f in 1:F))

# Constraints:
@constraint(CFLP, demand[c = 1:C], sum(y[c, f] for f in 1:F) == 1)  # Ensure each customer's demand is fully met
@constraint(CFLP, open_facility[c = 1:C, f = 1:F], y[c, f] <= x[f])  # A facility can only serve a customer if it is open
@constraint(CFLP, capacity[f = 1:F], sum(h[c] * y[c, f] for c in 1:C) <= cap[f])  # Facility capacity constraint

# Solve the model
optimize!(CFLP)
println("Termination status: $(termination_status(CFLP))")

# Report results
println("-------------------------------------------------------------")
if termination_status(CFLP) == MOI.OPTIMAL
    println("RESULTS:")
    println("The minimum-cost for this CFLP is $(objective_value(CFLP))")

    for f in 1:F
        if value(x[f]) > 0.99  # Facility is considered open if x[f] > 0.99
            customers_served_by_f = []  # Initialize an empty list to hold the IDs of customers served by facility f
            for c in 1:C
                if value(y[c, f]) > 0.99  # Customer is considered served if y[c, f] > 0.99
                    push!(customers_served_by_f, c)  # Add the customer to the list
                end
            end
            println("Facility $f serves customers: ", join(customers_served_by_f, ", "))
        end
    end
else
    println("No solution")
end
println("-------------------------------------------------------------")

# Plot results

# Extract latitudes and longitudes for customers
customer_lats = Float64.(Customers[2:end, 2])
customer_longs = Float64.(Customers[2:end, 3])

# Extract latitudes and longitudes for existing and potential facilities
facility_lats = Float64.(Total_Latitude[:])
facility_longs = Float64.(Total_Longtitude[:])

# Determine which facilities are open based on the solution
facility_status = [value(x[f]) for f in 1:F]

# Plot customers
scatter(customer_longs, customer_lats, label="Customers", color=:blue, markersize=5)

# Plot opened facilities
opened_facilities_lats = [facility_lats[f] for f in 1:F if facility_status[f] > 0.99]
opened_facilities_longs = [facility_longs[f] for f in 1:F if facility_status[f] > 0.99]
scatter!(opened_facilities_longs, opened_facilities_lats, label="Opened Facilities", color=:red, markersize=8)

# Optionally, draw lines from facilities to customers they serve to visualize the connections
for f in 1:F
    if facility_status[f] > 0.99
        for c in 1:C
            if value(y[c, f]) > 0.99
                plot!([facility_longs[f], customer_longs[c]], [facility_lats[f], customer_lats[c]], line=:dash, color=:gray, label="")
            end
        end
    end
end

# Set plot size and move the legend to the bottom right
plot!(size=(1200, 800))
plot!(legend=:bottomright)

# Finalize the plot with titles and labels
plot!(xlabel="Longitude", ylabel="Latitude", title="Facility-Customer Allocation Map")
gui()  # Display the plot

# Indicate successful completion
println("Successful end of script.")
