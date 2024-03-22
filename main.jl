
using Graphs, GraphRecipes, Plots
using JET, BenchmarkTools, Profile
using CUDA
#Returns Adjacency matrix of {9,4,1,2} (Paley 9)
function paley9()
    
    adj_mat = [
    0 1 1 1 0 0 1 0 0;
    1 0 0 0 1 0 1 1 0;
    1 0 0 1 0 0 0 1 1;
    1 0 1 0 1 1 0 0 0;
    0 1 0 1 0 1 0 1 0;
    0 0 0 1 1 0 1 0 1;
    1 1 0 0 0 1 0 0 1;
    0 1 1 0 1 0 0 0 1;
    0 0 1 0 0 1 1 1 0
    ]
    return adj_mat
end

#Find common neighbors of all vertices
function commonNeighborsCPU(graph, vertices, degree)
    common = Vector{Any}(undef, (degree + 2) * vertices) 
    for i in range(1,vertices)
        for j in range(i+1,vertices)
            if i == j
                continue
            end

            neighbors = common_neighbors(graph, i, j)
            print(typeof(neighbors))
            edge = has_edge(graph, i, j)
            numNeighbors = length(neighbors)

            if numNeighbors == 1 && edge || numNeighbors == 2 && !edge   
                push!(common, [i, j, neighbors])
            else
                return false
            end
        end
    end
    return true
end

#Find common neighbors of all vertices (runs on GPU)
function commonNeighborsGPU(graph, vertices, degree)
    common = CuArray{Int}(undef, (degree + 2) * vertices) #TODO Work on GPU?
    #Iterate over each vertex pair, skipping loops
    #Get whether an edge exists
    #Get their common neighbors
    #Get the number of neighbors
    for i in range(1,vertices)
        for j in range(i+1,vertices)
            if i == j
                continue
            end

            neighbors = common_neighbors(graph, i, j)
            print(typeof(neighbors))
            edge = has_edge(graph, i, j)
            numNeighbors = length(neighbors)

            if numNeighbors == 1 && edge || numNeighbors == 2 && !edge   
                push!(common, [i, j, neighbors])
            else
                return false
            end
        end
    end
    return true
end

function bruteForceCPU(vertices, degree, start, finish)
    #Multithreading
    Threads.@threads for i in range(start, finish)
        g = random_regular_graph(vertices, degree, seed=i) #TODO Bottleneck
        if commonNeighbors(g, vertices, degree) == true
            fName = "Winner! Seed - " * string(i) * (".lgz")
            savegraph(fName, g)
            return true
        end 
    end
    return false 
end

#The graph should have 99 vertices
#the graph is a regular graph with 14 edges per vertex.
#every pair of adjacent vertices should have 1 common neighbor, 
#and every pair of non-adjacent vertices should have 2 common neighbors. 

function main()
    #TODO https://codingnest.com/modern-sat-solvers-fast-neat-and-underused-part-3-of-n/
    #TODO https://cuda.juliagpu.org/stable/tutorials/introduction/
    paley = SimpleGraph(paley9()) 
    V = 99
    D = 14
    start  = 0
    finish = 10000
    bruteForceCPU(V, D, 1, 2)
    #if CUDA.functional()
    

    @time bruteForceCPU(V, D, start, finish) #Searched up to 20,000,000
    #@profview bruteForce(V, E, I)  

    if isfile("Winner! Seed - 19.lgz")
        g = loadgraph("Winner! Seed - 19.lgz")
        graphplot(g, method=:shell, nodesize=0.3, curves=false)
    end
end
main()