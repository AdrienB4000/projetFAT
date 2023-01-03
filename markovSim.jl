include("readData.jl")
include("state.jl")
include("randomVars.jl")

function simulateMarkov(maxTime::Int)::Vector{Float64}
    """
    Returns:
        - part of the total time where each station was empty when a customer arrived.
    """

    data = readData("data_50uniform.txt")
    state = initState(data)
    events = vcat([i for i in 1:data.nbSt], [(i, j) for i in 1:data.nbSt for j in 1:data.nbSt if i!=j])
    lambdas = vcat(data.lambdas, [1/data.travelTime[i, j] for i in 1:data.nbSt for j in 1:data.nbSt if i!=j])
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
