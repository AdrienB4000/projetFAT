# here we put our code to read the xlsx file given for the project

mutable struct Data
    travelTime::Matrix{Int}
    lambdas::Vector{Float64}
    routage::Matrix{Float64}
    initialParked::Vector{Int}
    initialTransit::Matrix{Int}

    function Data(travel::Matrix{Int}, lambdas::Vector{Float64}, routage::Matrix{Float64},
                  initialParked::Vector{Int}, initialTransit::Matrix{Int})
        return new(travel, lambdas, routage, initialParked, initialTransit)
    end
end

function readData(path::String)::Data
    f = open(path);
    lines = readlines(f);
    currentIdx = 1
    n = parse(Int, lines[currentIdx][1])
    currentIdx += 2
    data = Data(zeros(Int, (n, n)), zeros(Float64, n), zeros(Float64, (n, n)),
                zeros(Int, n), zeros(Int, (n, n)))
    for i in 1:n
        line = lines[currentIdx]
        splittedLine = split(line, ',')
        data.travelTime[i, :] = [parse(Int, x) for x in splittedLine]
        currentIdx += 1
    end

    currentIdx += 1

    line = lines[currentIdx]
    splittedLine = split(line, ',')
    data.lambdas = [parse(Float64, x) for x in splittedLine]
    currentIdx += 2

    for i in 1:n
        line = lines[currentIdx]
        splittedLine = split(line, ',')
        data.routage[i, :] = [parse(Float64, x) for x in splittedLine]
        currentIdx += 1
    end

    currentIdx += 1

    line = lines[currentIdx]
    splittedLine = split(line, ',')
    data.initialParked = [parse(Int, x) for x in splittedLine]
    currentIdx += 2

    for i in 1:n
        line = lines[currentIdx]
        splittedLine = split(line, ',')
        data.initialTransit[i, :] = [parse(Int, x) for x in splittedLine]
        currentIdx += 1
    end
    return data
end
