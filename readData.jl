# here we put our code to read the xlsx file given for the project

mutable struct Data
    nbSt::Int
    allSt::Vector{Int}
    travelTime::Matrix{Float64}
    lambdas::Vector{Float64}
    routage::Matrix{Float64}
    initialParked::Vector{Int}
    initialTransit::Matrix{Int}

    function Data(n::Int, travel::Matrix{Int}, lambdas::Vector{Float64},
                  routage::Matrix{Float64}, initialParked::Vector{Int}, initialTransit::Matrix{Int})
        return new(n, [i for i in 1:n], travel, lambdas, routage, initialParked, initialTransit)
    end
end

function readData(path::String)::Data
    f = open(path);
    lines = readlines(f);
    currentIdx = 1
    n = parse(Int, lines[currentIdx][1])
    data = Data(n, zeros(Int, (n, n)), zeros(Float64, n), zeros(Float64, (n, n)),
                zeros(Int, n), zeros(Int, (n, n)))
    currentIdx += 2
    # First n lines are travel times
    for i in 1:n
        line = lines[currentIdx]
        splittedLine = split(line, ',')
        # travel Times are given in minutes
        # And lambdas in minutes-1
        # We take hours so divide travel times by 60
        data.travelTime[i, :] = [parse(Int, x)/60 for x in splittedLine]
        currentIdx += 1
    end

    currentIdx += 1
    # Then one line of intensity of arrival in each station
    line = lines[currentIdx]
    splittedLine = split(line, ',')
    data.lambdas = [parse(Float64, x) for x in splittedLine]
    currentIdx += 2

    # Then n lines of our routing matrix
    for i in 1:n
        line = lines[currentIdx]
        splittedLine = split(line, ',')
        data.routage[i, :] = [parse(Float64, x) for x in splittedLine]
        currentIdx += 1
    end

    currentIdx += 1

    # Then one line of the initial state (number of bikes) of each station
    line = lines[currentIdx]
    splittedLine = split(line, ',')
    data.initialParked = [parse(Int, x) for x in splittedLine]
    currentIdx += 2

    # And finally n lines of the matrix of the initially moving bikes
    for i in 1:n
        line = lines[currentIdx]
        splittedLine = split(line, ',')
        data.initialTransit[i, :] = [parse(Int, x) for x in splittedLine]
        currentIdx += 1
    end
    return data
end
