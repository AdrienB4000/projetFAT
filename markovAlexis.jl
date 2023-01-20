include("readData.jl")
include("state.jl")
include("randomVars.jl")

validTransitions =[
        (1, 6),
        (1, 7),
        (1, 8),
        (1, 9),
        (2, 10),
        (2, 11),
        (2, 12),
        (2, 13),
        (3, 14),
        (3, 15),
        (3, 16),
        (3, 17),
        (4, 18),
        (4, 19),
        (4, 20),
        (4, 21),
        (5, 22),
        (5, 23),
        (5, 24),
        (5, 25),
        (6, 2),
        (7, 3),
        (8, 4),
        (9, 5),
        (10, 1),
        (11, 3),
        (12, 4),
        (13, 5),
        (14, 1),
        (15, 2),
        (16, 4),
        (17, 5),
        (18, 1),
        (19, 2),
        (20, 3),
        (21, 5),
        (22, 1),
        (23, 2),
        (24, 3),
        (25, 4),
    ]
    

function destination_from_route_colony(source_station::Int,k::Int)::Int
    road_from_source_number = ((k - 6) % 4) + 1
            
    if road_from_source_number < source_station
        return destination_station= road_from_source_number
    else
        return destination_station = road_from_source_number + 1
    end
end

function source_of_route_colony(destination_station::Int,j::Int)::Int
    return div(j - 6,4) + 1
end

function computeLambdasJK(data::Data, lambdas::Vector{Float64})::Dict{Tuple{Int64, Int64}, Float64}
    lambdasJK = Dict{Tuple{Int64, Int64}, Float64}()
    
    for (j,k) in validTransitions
        # Lambda_j_k for stations
        if j <= 5
            source_station = j
            
            destination_station = destination_from_route_colony(j,k)

            lambdasJK[(j,k)]= data.routage[source_station,destination_station] * lambdas[source_station]
        else
            source_station = div((j-6),4) + 1
    
            destination_station = k
    
            lambdasJK[(j,k)] = 1 / data.travelTime[source_station,destination_station]
        end
    end
    return lambdasJK
end

function computeInitialTransitionRates(lambdasJK::Dict{Tuple{Int64, Int64}, Float64}, data::Data)
    transitionRates = Dict{Tuple{Int64, Int64}, Float64}()

    for (j,k) in validTransitions
        if j <= 5
            if data.initialParked[j] == 0
                transitionRates[(j,k)]= 0
            else
                dest = destination_from_route_colony(j,k)
                transitionRates[(j,k)]= lambdasJK[(j,k)] * data.routage[j,dest]
            end
        else
            dest = k
            source = source_of_route_colony(dest,j)
            transitionRates[(j,k)]= 60* data.travelTime[source,dest]*data.initialTransit[source,dest]
        end
    end
    return transitionRates

end
function simulateMarkov(maxTime::Int)::Vector{Float64}
    """
    Returns:
        - part of the total time where each station was empty when a customer arrived.
    """

    data = readData("data_50uniform.txt")
    state = initState(data)
    events = vcat([i for i in 1:data.nbSt], [(i, j) for i in 1:data.nbSt for j in 1:data.nbSt if i!=j])
    lambdas = vcat(data.lambdas, [1/data.travelTime[i, j] for i in 1:data.nbSt for j in 1:data.nbSt if i!=j])
    
    lambdasJK = computeLambdasJK(readData("data_50uniform.txt"), lambdas)
    transitionRates = computeInitialTransitionRates(lambdasJK, data)
    eventsFrequency = 

    return []
end

simulateMarkov(10)


    """
    lambdasSum = sum(lambdas)
    eventsFrequency = [lamb/lambdasSum for lamb in lambdas]
    currentTime = 0
    nextTime = min(exponentialLaw(lambdasSum), maxTime)
    stationEmptinessTime = [0. for _ in 1:data.nbSt]

    nbEventsProcessed = 0
    while nextTime < maxTime
        nbEventsProcessed += 1
        # Store the amount of time where the station remained empty.
        for st in 1:data.nbSt
            if state.parkedBicycles[st] == 0
                stationEmptinessTime[st] += nextTime - currentTime
            end
        end
        event = sample(events, Weights(eventsFrequency))
        if typeof(event) == Int64
            # Here the event is that a customer arrives at a station
            if state.parkedBicycles[event] > 0
                j = sample(data.allSt, Weights(data.routage[event, :]))
                takeOneFromIToJ(state, event, j)
            end
        elseif typeof(event) == Tuple{Int64, Int64}
            # Here the event is that a customer finishes is travel from i to j
            if state.transitBicycles[event[1], event[2]] > 0
                arriveFromIAtJ(state, event[1], event[2])
            end
        else
            println("Big problem here")
        end
        currentTime = nextTime
        nextTime = min(currentTime + exponentialLaw(lambdasSum), maxTime)
    end
    # We finish the simulation between currentTime and maxTime
    for st in 1:data.nbSt
        if state.parkedBicycles[st] == 0
            stationEmptinessTime[st] += maxTime - currentTime
        end
    end
    println("Simulation ran for " * string(maxTime) * " hours")
    println(nbEventsProcessed, " events processed")
    return stationEmptinessTime / maxTime
end
    """
