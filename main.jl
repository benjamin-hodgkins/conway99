
using Graphs, GraphRecipes, Plots
using JET, BenchmarkTools, Profile
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
function commonNeighbors(graph, vertices, degree)
    #TODO Make this explicitly typed, preallocate array
    common = []#Vector{Any}(undef, vertices * 2)
    #println("Common neighbors:")
    for i in range(1,vertices)
        #println(all_neighbors(paley, i))
        for j in range(i+1,vertices)
            if i == j
                continue
            end

            neighbors = common_neighbors(graph, i, j) #TODO Rewrite?  
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

function bruteForce(vertices, degree, iterations)
    #Experimental multithreading
    Theads.@threads for i in range(1, iterations)
        g = random_regular_graph(vertices, degree, seed=i)
        #println("Random graph: ")
        if commonNeighbors(g, vertices, degree) == true
            fName = "Winner! Seed - " * string(seed) * (".lgz")
            savegraph(fName, g)
            graphplot(g, method=:shell, nodesize=0.3, curves=false)
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
    E = 14

    bruteForce(V, E, 10)
    @time bruteForce(V, E, 75000)

end
#activate conway99
main()