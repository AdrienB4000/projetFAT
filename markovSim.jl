include("readData.jl")
include("state.jl")
include("randomVars.jl")

function simulateMarkov(maxTime::Int)::Vector{Float64}
    """
    Returns:
        - part of the total time where each station was empty when a customer arrived.
    """

    data = readData("data_1.txt")
    state = initState(data)
    events = vcat([i for i in 1:data.nbSt], [(i, j) for i in 1:data.nbSt for j in 1:data.nbSt])
    lambdas = vcat(data.lambdas, [i == j ? 0 : 1/data.travelTime[i, j] for i in 1:data.nbSt for j in 1:data.nbSt])
    lambdasSum = sum(lambdas)
    lambdasFeasible = vcat([state.parkedBicycles[i] == 0 ? 0 : data.lambdas[i] for i in 1:data.nbSt],
                           [state.transitBicycles[i, j] == 0 ? 0 : 1/data.travelTime[i, j] for i in 1:data.nbSt for j in 1:data.nbSt])
    lambdasFeasibleSum = sum(lambdasFeasible)
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
        event = sample(events, Weights(lambdasFeasible))
        if typeof(event) == Int64
            # Here the event is that a customer arrives at a station
            if state.parkedBicycles[event] > 0
                j = sample(data.allSt, Weights(data.routage[event, :]))
                if state.transitBicycles[event, j] == 0
                    lambdasFeasible[data.nbSt + (event - 1) * data.nbSt + j] += lambdas[data.nbSt + (event - 1) * data.nbSt + j]
                    lambdasFeasibleSum += lambdas[data.nbSt + (event - 1) * data.nbSt + j]
                end
                takeOneFromIToJ(state, event, j)
                if state.parkedBicycles[event] == 0
                    lambdasFeasible[event] = 0
                    lambdasFeasibleSum -= lambdas[event]
                end
            end
        elseif typeof(event) == Tuple{Int64, Int64}
            # Here the event is that a customer finishes is travel from i to j
            if state.transitBicycles[event[1], event[2]] > 0 #useless if lambdasFeasible is OK
                if state.parkedBicycles[event[2]] == 0
                    lambdasFeasible[event[2]] = lambdas[event[2]]
                    lambdasFeasibleSum += lambdas[event[2]]
                end
                arriveFromIAtJ(state, event[1], event[2])
                lambdasFeasible[data.nbSt + (event[1] - 1) * data.nbSt + event[2]] -= lambdas[data.nbSt + (event[1] - 1) * data.nbSt + event[2]]
                lambdasFeasibleSum -= lambdas[data.nbSt + (event[1] - 1) * data.nbSt + event[2]]
            end
        else
            println("Big problem here")
        end
        currentTime = nextTime
        nextTime = min(currentTime + exponentialLaw(lambdasFeasibleSum), maxTime)
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
