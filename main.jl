using Graphs, GraphRecipes, Plots
using JET, BenchmarkTools, Profile
using CUDA

#Returns Adjacency matrix of {9,4,1,2} (Paley 9)
function paley9()
    
    adj_mat = BitArray([
    0 1 1 1 0 0 1 0 0;
    1 0 0 0 1 0 1 1 0;
    1 0 0 1 0 0 0 1 1;
    1 0 1 0 1 1 0 0 0;
    0 1 0 1 0 1 0 1 0;
    0 0 0 1 1 0 1 0 1;
    1 1 0 0 0 1 0 0 1;
    0 1 1 0 1 0 0 0 1;
    0 0 1 0 0 1 1 1 0
    ])
    return adj_mat
end

#Find common neighbors of all vertices
function commonNeighborsCPU(graph, vertices, degree)
    common = []
    for i in range(1,vertices)
        for j in range(i+1,vertices)
            if i == j
                continue
            end

            neighbors = common_neighbors(graph, i, j)
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
        if commonNeighborsCPU(g, vertices, degree) == true
            fName = "Winner! Seed - " * string(i) * (".lgz")
            savegraph(fName, g)
            return true
        end 
    end
    return false 
end

#Find common neighbors of all vertices (runs on GPU)
#TODO Create custom graph generator
function commonNeighborsGPU(graph, vertices, degree)

    adj_mat = BitArray(undef, vertices, vertices)

    neigh_mat = transpose(graph) * graph
    
    
    #For each vertex pair, skipping loops
    #Get whether an edge exists
    #Get their common neighbors DONE
    #Get the number of neighbors
    
end

#The graph should have 99 vertices
#the graph is a regular graph with 14 edges per vertex.
#every pair of adjacent vertices should have 1 common neighbor, 
#and every pair of non-adjacent vertices should have 2 common neighbors. 
function main()
    #TODO https://codingnest.com/modern-sat-solvers-fast-neat-and-underused-part-3-of-n/
    #TODO https://jenni-westoby.github.io/Julia_GPU_examples/dev/Vector_addition/
    paley = paley9()
    V = 9
    D = 4
    start  = 0
    finish = 10000
    
    #Graph to pass to GPU (use CuArray in main)
    #graph = CuArray{Int}(undef, (degree + 2) * vertices)
    commonNeighborsGPU(paley, V, D)
    @time commonNeighborsGPU(paley, V, D)
    #print(adjacency_matrix(paley))
    
    #bruteForceCPU(V, D, 1, 2)
    #@time bruteForceCPU(V, D, start, finish) #Searched up to 20,000,000
    #@profview bruteForce(V, E, I)  

    if isfile("Winner! Seed - 19.lgz")
        g = loadgraph("Winner! Seed - 19.lgz")
        graphplot(g, method=:shell, nodesize=0.3, curves=false)
    end
end
main()