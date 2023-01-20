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

function simulateMarkov(maxTime::Int, verbose::Bool=true)::Vector{Float64}
    """
    Returns:
        - part of the total time where each station was empty when a customer arrived.
    """

    data = readData("data_50uniform.txt")
    #data = readData("data_1.txt")
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
    arrivalsAtStation = 0
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
            arrivalsAtStation += 1
            # Here the event is that a customer arrives at a station
            source = event
            destination = sample(data.allSt, Weights(data.routage[event, :]))
            takeOneFromIToJ(state, source, destination)

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
            arriveFromIAtJ(state, source, destination)
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

    if verbose
        println("Simulation ran for " * string(maxTime) * " hours")
        println(nbEventsProcessed, " events processed")
        println(arrivalsAtStation, " arrivals at station")
    end

    return stationEmptinessTime / maxTime
end

function simulateMarkovWithUselessEvents(maxTime::Int, verbose::Bool=true)::Vector{Float64}
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
            lambdas[i] = unitaryLambdas[i]
            """
            if data.initialParked[i] == 0
                lambdas[i] = 0
            else
                lambdas[i] = unitaryLambdas[i]
            end
            """
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
    arrivalsAtStation = 0
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
            arrivalsAtStation +=1
            if state.parkedBicycles[event] == 0
                currentTime = nextTime
                nextTime = min(currentTime + exponentialLaw(lambdasSum), maxTime)
                continue
            end
            # Here the event is that a customer arrives at a station
            source = event
            destination = sample(data.allSt, Weights(data.routage[event, :]))
            takeOneFromIToJ(state, source, destination)

            route_colony = route_colony_from_source_and_dest(source, destination)
            # Update lambda for the route
            lambdas[route_colony] += unitaryLambdas[route_colony]
            lambdasSum += unitaryLambdas[route_colony]

            # If last customer of station, event becomes impossible
            """
            if state.parkedBicycles[event] == 0
                lambdasSum -= unitaryLambdas[event]
                lambdas[event] = 0
            end
            """

        elseif typeof(event) == Tuple{Int64, Int64}
            # Here the event is that a customer finishes is travel from i to j
            source = event[1]
            destination = event[2]
            # First route from the source
            route_colony = route_colony_from_source_and_dest(source, destination)
            arriveFromIAtJ(state, source, destination)
            # Reduce lambda for route
            lambdas[route_colony] -= unitaryLambdas[route_colony]
            lambdasSum -= unitaryLambdas[route_colony]

            # If station was empty but isn't anymore
            """
            if state.parkedBicycles[destination] ==1
                lambdasSum += unitaryLambdas[destination]
                lambdas[destination] = unitaryLambdas[destination]
            end
            """
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

    if verbose
        println("Simulation ran for " * string(maxTime) * " hours")
        println(nbEventsProcessed, " events processed")
        println(arrivalsAtStation, " arrivals at station")
    end

    return stationEmptinessTime / maxTime
end

function simulationMeanTime(nRuns::Int, runLenght::Int)::Float64
    runTime = 0
    for i in 1:nRuns
        start = time()
        a= simulateMarkov(runLenght, false)
        runTime += time() - start
    end
    return round(runTime/nRuns, digits=6)
end

function meanSimulateMarkov(numberOfRuns::Int, maxTime::Int)::Vector{Float64}
    summedEmptiness = [0. for _ in 1:5]
    for i in 1:numberOfRuns
        summedEmptiness += simulateMarkov(maxTime, false)
    end
    return summedEmptiness/numberOfRuns

end

"""


nruns = 10
meanRuns = 10000
timeLength = 150
emptinessMatrix = [[] for _ in 1:nruns]
for i in 1:nruns
    global emptinessMatrix[i] =meanSimulateMarkov(meanRuns, timeLength)
end
#println(emptinessMatrix)

# Store and display biggest difference
biggestDiff = [0. for _ in 1:5]
for station in 1:5
    for firstRun in 1:nruns
        for secondRun in 1:nruns
            difference = abs(emptinessMatrix[firstRun][station] - emptinessMatrix[secondRun][station])
            if difference > biggestDiff[station]
                global biggestDiff[station] = difference
            end
        end
    end
end
println(biggestDiff)
"""

"""
Comparaison de dix runs sur 150 heures en fonction du nombre de runs moyennées
si 10 runs : en gros de l'ordre de 5%
si 100 runs : en gros de l'ordre de 1,5% (1,6 à 2% avec 20 runs de 100 moyennées)
si 1000 runs : en gros de l'ordre de 0.4 à 0.5%
si 10000 runs : en gros reste de l'ordre de 0.4 à 0.5%

Comparaison de dix runs sur 1500 heures en fonctions du nombre de runs moyennées
si 10 runs : en gros de l'ordre de 1.6 à 2.3%
si 100 runs : en gros de l'ordre de 0.5% à 1%
"""