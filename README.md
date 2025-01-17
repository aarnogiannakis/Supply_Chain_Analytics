# Optimization of Facility Locations and Technician Routing

This repository contains all the code and documentation for a two-part project aimed at enhancing operational efficiency for Company A. The project focuses on strategic optimization of facility locations and efficient routing of technicians within City AB. The project is inspired by the course 42380 Supply Chain analytics taught by Allan Larsen at DTU.

**Project Overview**

**Part 1: Facility Location Optimization**

The first part of the project is dedicated to optimizing the distribution of Company A's service centers. Using both deterministic and stochastic models, the analysis explores the necessity of maintaining existing facilities and the potential benefits of opening new locations. The goal is to improve service delivery efficiency and minimize operational costs, while considering the uncertainties inherent in future demand and facility performance.

**Part 2: Routing Technicians in City AB**

The second part addresses the logistical challenge of routing technicians to provide repair services to private customers in City AB. This component models a typical Vehicle Routing Problem (VRP) where technicians depart from a central distribution center and serve multiple customers without the need to return to the base between visits. The constraints of the problem include repair time per customer, the technician's maximum working hours, and the non-restrictive capacity of their vans.

**Assumptions**

1) The distance from a service center to a customer is equal to the great circle distance between the locations

2) Company A uses a per kilometer transportation cost of 10$.

3) Assume that each scenario occurs with equal probability and that the transportation cost is the same as in the deterministic setting
