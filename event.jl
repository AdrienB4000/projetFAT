include("readData.jl")
include("state.jl")
include("randomVars.jl")

using DataStructures
using StatsBase

mutable struct Event{actionFunc<:Function, outputFunc<:Function}
    endingTime::Float64
    i::Int
    j::Int # unused for departure events
    endAction::actionFunc
    output::outputFunc

    function Event(endTime::Float64, i::Int, j::Int, action::Function, output::Function)::Event
        return new{typeof(action), typeof(output)}(endTime, i, j, action, output)
    end
end

Base.show(io::IO, event::Event) = event.output(io, event)

function departureOutput(io::IO, event::Event)
    print("Departure from station " * string(event.i))
    println(" at time " * string(event.endingTime))
end

function endingTime(event::Event)
    return event.endingTime
end

function departureFromStation(event::Event, state::State, pq::AbstractHeap, data::Data)
    # We select the destination j with the routage Matrix
    # Then we change the state and create the next events
    if state.parkedBicycles[event.i] > 0
        j = sample(data.allSt, Weights(data.routage[event.i, :]))
        takeOneFromIToJ(state, event.i, j)
        arrivalTime = event.endingTime + transitLaw(data.travelTime[event.i, j])
        arrivalEvent = Event(arrivalTime, event.i, j, arrivalAtStation, arrivalOutput)
        push!(pq, arrivalEvent)
    end

    nextDepartureTime = event.endingTime + exponentialLaw(data.lambdas[event.i])
    nextDepartureEvent = Event(nextDepartureTime, event.i, -1, departureFromStation, departureOutput)
    push!(pq, nextDepartureEvent)
end

function arrivalOutput(io::IO, event::Event)
    print("Arrival at station " * string(event.j))
    print(" from station " * string(event.i))
    println(" at time " * string(event.endingTime))
end

function arrivalAtStation(event::Event, state::State, pq::AbstractHeap, data::Data)
    arriveFromIAtJ(state, event.i, event.j)
end

function initQueue(data::Data)::AbstractHeap
    events = BinaryHeap(Base.By(endingTime), Event[])
    # First we create the events linked to the next departures from each station
    for i in 1:data.nbSt
        finishingTime = exponentialLaw(data.lambdas[i])
        departEvent = Event(finishingTime, i, -1, departureFromStation, departureOutput)
        push!(events, departEvent)
    end

    # Then we create the events linked to the next arrivals at each station
    for i in 1:data.nbSt
        for j in 1:data.nbSt
            nbTransiting = data.initialTransit[i, j]
            for _ in 1:nbTransiting
                finishingTime = transitLaw(data.travelTime[i, j])
                arrivalEvent = Event(finishingTime, i, j, arrivalAtStation, arrivalOutput)
                push!(events, arrivalEvent)
            end
        end
    end
    return events
end

function simulateWithMeans(maxTime::Int)::Tuple{Vector{Float64}, Matrix{Float64}, Vector{Float64}, Float64}
    """
    Returns:
        - mean parked bicycles by station over time
        - mean bicycles in transition between i and j
        - part of the total time where each station was empty when a customer arrived.
    """

    data = readData("data_50uniform.txt")
    state = initState(data)
    events = initQueue(data)
    nbEvents = 0
    currentTime = 0
    meanParkedBicycles = [0. for _ in 1:data.nbSt]
    meanTransitBicycles = zeros(Float64, (data.nbSt, data.nbSt))
    stationEmptinessTime = [0. for _ in 1:data.nbSt]
    wholeEmptyTime = 0

    while length(events) > 0
        ev = pop!(events)
        nextTime = min(ev.endingTime, maxTime)
        meanParkedBicycles = meanParkedBicycles + (nextTime - currentTime) * state.parkedBicycles
        meanTransitBicycles = meanTransitBicycles + (nextTime - currentTime) * state.transitBicycles
        # Store the amount of time where the station remained empty.

        allEmpty = true
        for st in 1:data.nbSt
            if state.parkedBicycles[st] == 0
                stationEmptinessTime[st] += nextTime - currentTime
            else
                allEmpty = false
            end
        end
        if allEmpty
            wholeEmptyTime += nextTime - currentTime
        end

        currentTime = ev.endingTime
        nbEvents += 1
        if currentTime >= maxTime
            break
        end
        ev.endAction(ev, state, events, data)
    end
    println("Simulation ran for " * string(maxTime) * " hours")
    println(nbEvents, " events dequeued")
    return meanParkedBicycles / maxTime, meanTransitBicycles / maxTime, stationEmptinessTime / maxTime, wholeEmptyTime / maxTime
end

function simulate(maxTime::Int)::Vector{Float64}
    """
    Returns:
        - part of the total time where each station was empty when a customer arrived.
    """

    data = readData("data_50uniform.txt")
    state = initState(data)
    events = initQueue(data)
    nbEvents = 0
    currentTime = 0
    stationEmptinessTime = [0. for _ in 1:data.nbSt]

    while length(events) > 0
        ev = pop!(events)
        nextTime = min(ev.endingTime, maxTime)
        # Store the amount of time where the station remained empty.
        for st in 1:data.nbSt
            if state.parkedBicycles[st] == 0
                stationEmptinessTime[st] += nextTime - currentTime
            end
        end

        currentTime = ev.endingTime
        nbEvents += 1
        if currentTime >= maxTime
            break
        end
        ev.endAction(ev, state, events, data)
    end
    # println("Simulation ran for " * string(maxTime) * " hours")
    # println(nbEvents, " events dequeued")
    return stationEmptinessTime / maxTime
end

function calculateEmptinessSd()::Tuple{Vector{Int}, Vector{Float64}}
    maxTimesToTest = [150, 1500, 5000, 15000, 30000, 50000]
    maxRelativeSd = []
    for maxTime in maxTimesToTest
        println("Processing " * string(maxTime))
        nbSamples = 50
        emptinessResults = Vector{Float64}[]
        for j in 1:nbSamples
            push!(emptinessResults, simulate(maxTime));
        end
        meanEmptiness = sum(emptinessResults) / length(emptinessResults)
        varianceByStation = [0 for i in 1:length(meanEmptiness)]
        for j in 1:nbSamples
            varianceByStation += (emptinessResults[j] - meanEmptiness) .* (emptinessResults[j] - meanEmptiness)
        end
        varianceByStation = 1/nbSamples * varianceByStation
        sdByStation = [sqrt(v) for v in varianceByStation]
        relativeSdByStation = [sdByStation[s]/meanEmptiness[s] for s in 1:length(varianceByStation)]
        push!(maxRelativeSd, maximum(relativeSdByStation))
    end
    return maxTimesToTest, maxRelativeSd
end
