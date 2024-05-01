#Current intent - correct generateGraph() to make regular graphs to feed into check2()
#Eventually this is too brute force search graphs of 99,14,1,2 preferably on GPU

using Random, Combinatorics
using Graphs, GraphRecipes, Plots
using BenchmarkTools, Profile
using CUDA

#Returns Adjacency matrix of {9,4,1,2} (Paley 9)
function paley9()
    
    adj_mat = Array([
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

#Checks properties of graph v1 (work with Julia graph type)
function check(graph, vertices)
    for i in range(1,vertices)
        for j in range(i+1,vertices)
            if i == j
                continue
            end
            neighbors = common_neighbors(graph, i, j)
            edge = has_edge(graph, i, j)
            numNeighbors = length(neighbors)

            if numNeighbors == 1 && edge || numNeighbors == 2 && !edge  #If adjacent, check for 1 common neighbor, if not, check for 2
                continue
            else
                return false
            end
        end
    end
    return true
end

#Checks properties of graph v2 (works with adjacency matrix)
function check2(adj_mat)
    num_neigh_mat = transpose(adj_mat) * adj_mat
    for i in range(1, length(adj_mat))
        if num_neigh_mat[i] == 4
            continue
        elseif adj_mat[i] == 1 && num_neigh_mat[i] == 1 || adj_mat[i] == 0 && num_neigh_mat[i] == 2 #If adjacent, check for 1 common neighbor, if not, check for 2
            continue
        else
            return false
        end
    end
    return true   
end

function bruteForce(vertices, degree, start, finish)
    #Multithreading
    Threads.@threads for i in range(start, finish)
        g = random_regular_graph(vertices, degree, seed=i)
        if check(g, vertices) == true
            fName = "Winner (1)! Seed - " * string(i) * (".lgz")
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
    paley = paley9()
    n = 9
    k = 4
    start = 1
    finish = factorial(n)
    adj_mat = Array([
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

    #Compare brute force methods
    @time bruteForce(n, k, start, finish)

    println(check2(paley))
    println(check2(adj_mat))

    middleRow = [0]
    show(append!(middleRow, repeat([1,0], Int((n-1)/2))))

    #Compare graph generation methods
    @time random_regular_graph(n, k)
    @time generateGraph(row, n, k, 1)
    #todo 

    #@time bruteForce(99, 14, start, finish)
    #@printf("Checked: %i : %i, Total: %i\n", start, finish, finish-start)
end
main()