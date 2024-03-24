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

#Checks properties of graph v1
function check(graph, vertices)
    for i in range(1,vertices)
        for j in range(i+1,vertices)
            if i == j
                continue
            end
            neighbors = common_neighbors(graph, i, j)
            edge = has_edge(graph, i, j)
            numNeighbors = length(neighbors)

            if numNeighbors == 1 && edge || numNeighbors == 2 && !edge   
                continue
            else
                return false
            end
        end
    end
    return true
end

#Checks properties of graph v2
function check2(graph)
    adj_mat = adjacency_matrix(graph)
    num_neigh_mat = transpose(adj_mat) * adj_mat
    for i in range(1, length(adj_mat))
        if num_neigh_mat[i] == 4
            continue
        elseif adj_mat[i] == 1 && num_neigh_mat[i] == 1
            continue
        elseif adj_mat[i] == 0 && num_neigh_mat[i] == 2
            continue
        else
            return false
        end
    end
    return true   
end

function generateGraph(vertices, degree)
    adj_mat = BitMatrix(undef, vertices, vertices)
    #display(adj_mat)

    #TODO Iterate over matrix, add (degree) number of edges to each row
    # https://docs.julialang.org/en/v1/base/arrays/#Broadcast-and-vectorization
end
function bruteForce(vertices, degree, start, finish)
    #Multithreading
    Threads.@threads for i in range(start, finish)
        g = random_regular_graph(vertices, degree, seed=i) #TODO Bottleneck
        if check(g, vertices) == true
            fName = "Winner! Seed - " * string(i) * (".lgz")
            savegraph(fName, g)
            return true
        end 
    end
    return false 
end

function bruteForce2(vertices, degree, start, finish)
    #Multithreading
    Threads.@threads for i in range(start, finish)
        g = random_regular_graph(vertices, degree, seed=i) #TODO Bottleneck
        if check2(g) == true
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
    #TODO https://jenni-westoby.github.io/Julia_GPU_examples/dev/Vector_addition/
    #TODO Create custom graph generator
    #TODO Pass adjacency_matrix directly to check2()
    paley = paley9()
    V = 99
    D = 14
    start  = 0
    finish = 1000
    
    #Graph to pass to GPU (use CuArray in main)
    #graph = CuArray{Int}(undef, (degree + 2) * vertices)
    
    bruteForce(V, D, 1, 2)
    @time bruteForce(V, D, start, finish)

    bruteForce2(V, D, 1, 2)
    @time bruteForce2(V, D, start, finish)

    generateGraph(V, D)
    #if isfile("Winner! Seed - 19.lgz")
        #g = loadgraph("Winner! Seed - 19.lgz")
        #graphplot(paley, method=:shell, nodesize=0.3, names=1:9, curves=false)
    #end
end
main()