include("readData.jl")

mutable struct State
    parkedBicycles::Vector{Int}
    transitBicycles::Matrix{Int}

    function State(parked::Vector{Int}, transit::Matrix{Int})
        return new(parked, transit)
    end
end

function initState(data::Data)::State
    st = State(data.initialParked, data.initialTransit)
end

function takeOneFromIToJ(state::State, i::Int, j::Int)
    if i == j
        println("Problem : can't go from i to i")
    end
    state.parkedBicycles[i] -= 1
    state.transitBicycles[i, j] += 1
end

function arriveFromIAtJ(state::State, i::Int, j::Int)
    if i == j
        println("Problem : can't go from i to i")
    end
    state.parkedBicycles[j] += 1
    state.transitBicycles[i, j] -= 1
end

function nbParkedAtI(state::State, i::Int)
    return state.parkedBicycles[i]
end

function nbTransitsFromIToJ(state::State, i::Int, j::Int)
    return state.transitBicycles[i, j]
end
