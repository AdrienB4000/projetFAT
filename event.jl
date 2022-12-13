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

function departureFromStation(event::Event, state::State, pq::PriorityQueue{Event, Float64}, data::Data)
    # We select the destination j with the routage Matrix
    # Then we change the state and create the next events
    if state.parkedBicycles[event.i] > 0
        j = sample([jP for jP in 1:data.nbSt], Weights(data.routage[event.i, :]))
        takeOneFromIToJ(state, event.i, j)
        arrivalTime = event.endingTime + transitLaw(data.travelTime[event.i, j])
        arrivalEvent = Event(arrivalTime, event.i, j, arrivalAtStation, arrivalOutput)
        enqueue!(pq, arrivalEvent, arrivalTime)
    end

    nextDepartureTime = event.endingTime + exponentialLaw(data.lambdas[event.i])
    nextDepartureEvent = Event(nextDepartureTime, event.i, -1, departureFromStation, departureOutput)
    enqueue!(pq, nextDepartureEvent, nextDepartureTime)
end

function arrivalOutput(io::IO, event::Event)
    print("Arrival at station " * string(event.j))
    print(" from station " * string(event.i))
    println(" at time " * string(event.endingTime))
end

function arrivalAtStation(event::Event, state::State, pq::PriorityQueue{Event, Float64}, data::Data)
    arriveFromIAtJ(state, event.i, event.j)
end

function initQueue(data::Data)::PriorityQueue{Event, Float64}
    events = PriorityQueue{Event, Float64}()
    # First we create the events linked to the next departures from each station
    for i in 1:data.nbSt
        finishingTime = exponentialLaw(data.lambdas[i])
        departEvent = Event(finishingTime, i, -1, departureFromStation, departureOutput)
        enqueue!(events, departEvent, finishingTime)
    end

    # Then we create the events linked to the next arrivals at each station
    for i in 1:data.nbSt
        for j in 1:data.nbSt
            nbTransiting = data.initialTransit[i, j]
            for _ in 1:nbTransiting
                finishingTime = transitLaw(data.travelTime[i, j])
                arrivalEvent = Event(finishingTime, i, j, arrivalAtStation, arrivalOutput)
                enqueue!(events, arrivalEvent, finishingTime)
            end
        end
    end
    return events
end

function main(maxTime::Int)
    data = readData("data.txt")
    state = initState(data)
    events = initQueue(data)
    println(state)
    println(events)
    while length(events) > 0
        ev = dequeue!(events)
        if ev.endingTime >= maxTime
            break
        end
        ev.endAction(ev, state, events, data)
    end
end
