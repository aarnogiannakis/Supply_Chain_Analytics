# Facility Location Data Processing Script
# Author: Alexander Arnogiannakis
# Description: This script processes the facility location data from an Excel file, calculates the distances
# between customers and facilities, and prepares the necessary data for optimization models.

# Load required packages
using XLSX
using DataFrames
using Geodesics

# Step 1: Load the Excel file
# Replace with your file path or use a relative path if sharing with others
file_path = ________

# Read the Excel file
xlsx = XLSX.readxlsx(file_path)

# Access specific sheets by name
customers_sheet = xlsx["Customers"] 
facilities_sheet = xlsx["Facilities"]
scenarios_sheet = xlsx["Scenarios"]

# Load customer data (ID, Latitude, Longitude, Visits per Year)
Customers = XLSX.readdata(file_path, "Customers", "A1:D68")

# Load existing facilities data (Name, Latitude, Longitude, Closing Cost, Capacity)
Existing_Facilities = XLSX.readdata(file_path, "Facilities", "A2:E5")

# Load potential facilities data (Name, Latitude, Longitude, Opening Cost, Capacity)
Potential_Facilities = XLSX.readdata(file_path, "Facilities", "A8:E15")

# Load scenario data for customer demand under different scenarios
Scenarios_Demand_High_Scenario = XLSX.readdata(file_path, "Scenarios", "C3:L69")
Scenarios_Demand_Low_Scenario = XLSX.readdata(file_path, "Scenarios", "M3:V69")
Scenarios_Demand_Mixed_Scenario = XLSX.readdata(file_path, "Scenarios", "W3:AF69")

# Load facility capacities under different scenarios
Facility_Capacities_High_Scenario = XLSX.readdata(file_path, "Scenarios", "C70:L79")
Facility_Capacities_Low_Scenario = XLSX.readdata(file_path, "Scenarios", "M70:V79")
Facility_Capacities_Mixed_Scenario = XLSX.readdata(file_path, "Scenarios", "W70:AF79")

# Calculate distances between customers and facilities
Customer_Coordinates = Customers[2:end, 1:3]  # Customer ID, Latitude, Longitude
Existing_Facilities_Coord = Existing_Facilities[2:end, 2:3]  # Latitude, Longitude
Potential_Facilities_Coord = Potential_Facilities[2:end, 2:3]  # Latitude, Longitude

# Convert degrees to radians for distance calculation
Customer_Coordinates[:, 2:3] = deg2rad.(Customer_Coordinates[:, 2:3])
Existing_Facilities_Coord[:, :] = deg2rad.(Existing_Facilities_Coord[:, :])
Potential_Facilities_Coord[:, :] = deg2rad.(Potential_Facilities_Coord[:, :])

# Constants for the WGS84 ellipsoid
a = Geodesics.EARTH_R_MAJOR_WGS84  # Semimajor axis
f = Geodesics.F_WGS84  # Flattening

# Initialize matrices to store distances (67 customers, 3 existing facilities, 7 potential facilities)
Distances_to_Existing = zeros(size(Customer_Coordinates, 1), size(Existing_Facilities_Coord, 1))
Distances_to_Potential = zeros(size(Customer_Coordinates, 1), size(Potential_Facilities_Coord, 1))

# Calculate distances from each customer to each existing facility
for i in 1:size(Customer_Coordinates, 1)
    for j in 1:size(Existing_Facilities_Coord, 1)
        dist, _, _ = Geodesics.inverse((Customer_Coordinates[i, 2], Customer_Coordinates[i, 3], Existing_Facilities_Coord[j, 1], Existing_Facilities_Coord[j, 2])..., a, f)
        Distances_to_Existing[i, j] = dist
    end
end

# Calculate distances from each customer to each potential facility
for i in 1:size(Customer_Coordinates, 1)
    for j in 1:size(Potential_Facilities_Coord, 1)
        dist, _, _ = Geodesics.inverse((Customer_Coordinates[i, 2], Customer_Coordinates[i, 3], Potential_Facilities_Coord[j, 1], Potential_Facilities_Coord[j, 2])..., a, f)
        Distances_to_Potential[i, j] = dist
    end
end

# Convert distances from meters to kilometers
Distances_to_Existing ./= 1000
Distances_to_Potential ./= 1000

# Concatenate all facility coordinates and distances
Total_Latitude = vcat(Existing_Facilities[2:end, 2], Potential_Facilities[2:end, 2])
Total_Longtitude = vcat(Existing_Facilities[2:end, 3], Potential_Facilities[2:end, 3])

# Concatenate distances into a single matrix (67x10)
Total_Distances = hcat(Distances_to_Existing, Distances_to_Potential)

# Prepare the fixed cost vector, considering closing costs for existing facilities and opening costs for potential facilities
Fixed_Cost = vcat(-1 * Existing_Facilities[2:end, 4], Potential_Facilities[2:end, 4])

# Annual demand of visits per customer
h = Customers[2:end, 4]

# Transportation cost, based on distance
tsp_cost = 10 * Total_Distances

# Facility capacities
cap = vcat(Existing_Facilities[2:end, 5], Potential_Facilities[2:end, 5])

# The processed data is now ready to be used in optimization models.

