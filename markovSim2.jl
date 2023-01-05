include("readData.jl")
include("state.jl")
include("randomVars.jl")
using StatsBase

function route_colony_from_source_and_dest(source::Int, destination::Int)::Int
    first_route = 6 + 4 * (source- 1)
    if source < destination
        route_colony = first_route + destination - 2
    else
        route_colony = first_route + destination - 1
    end
    return route_colony
end

function simulateMarkov(maxTime::Int)::Vector{Float64}
    """
    Returns:
        - part of the total time where each station was empty when a customer arrived.
    """

    #data = readData("data_50uniform.txt")
    data = readData("data_1.txt")
    state = initState(data)
    events = vcat([i for i in 1:data.nbSt], [(i, j) for i in 1:data.nbSt for j in 1:data.nbSt if i!=j])
    
    # Gamma is 1/lambda where lambda is the parameter of the exponential law.
    unitaryLambdas = vcat(data.lambdas, [1/data.travelTime[i, j] for i in 1:data.nbSt for j in 1:data.nbSt if i!=j])
    
    lambdas = [0. for i in 1:length(unitaryLambdas)]
    for i in 1:length(unitaryLambdas)
        if i <= 5
            if data.initialParked[i] == 0
                lambdas[i] = 0
            else
                lambdas[i] = unitaryLambdas[i]
            end
        else
            if data.initialTransit[i - 5] == 0
                lambdas[i] = 0
            else
                lambdas[i] = unitaryLambdas[i] * data.initialTransit[i - 5]
            end
        end
    end

    lambdasSum = sum(lambdas)

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

        event = sample(events, Weights(lambdas))
        if typeof(event) == Int64
            # Here the event is that a customer arrives at a station
            j = sample(data.allSt, Weights(data.routage[event, :]))
            takeOneFromIToJ(state, event, j)

            source = event
            destination = j
            route_colony = route_colony_from_source_and_dest(source, destination)
            # Update lambda for the route
            lambdas[route_colony] += unitaryLambdas[route_colony]
            lambdasSum += unitaryLambdas[route_colony]

            # If last customer of station, event becomes impossible
            if state.parkedBicycles[event] == 0
                lambdasSum -= unitaryLambdas[event]
                lambdas[event] = 0
            end

        elseif typeof(event) == Tuple{Int64, Int64}
            # Here the event is that a customer finishes is travel from i to j
            source = event[1]
            destination = event[2]
            # First route from the source
            route_colony = route_colony_from_source_and_dest(source, destination)
            arriveFromIAtJ(state, event[1], event[2])
            # Reduce lambda for route
            lambdas[route_colony] -= unitaryLambdas[route_colony]
            lambdasSum -= unitaryLambdas[route_colony]

            # If station was empty but isn't anymore
            if state.parkedBicycles[destination] ==1
                lambdasSum += unitaryLambdas[destination]
                lambdas[destination] = unitaryLambdas[destination]
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

println(simulateMarkov(150))