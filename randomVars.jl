# here we put our code linked to random variables
# for example a function to simulate an exponential law

using Random

function exponentialLaw(lambda::Float64)::Float64
    return -1/lambda * log(rand())
end

function nExponentialLaw(n::Int, lambda::Float64)::Vector{Float64}
    unif = rand(n)
    return [-1/lambda * log(u) for u in unif]
end

function transitLaw(transitTime::Int)::Float64
    # To change if we consider a exponential, uniform...
    return transitTime
end
