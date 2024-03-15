
using Graphs, GraphRecipes, Plots

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

#Find common neighbors 
function commonNeighbors(graph, vertices)
    common = []
    #println("Common neighbors:")
    for i in range(1,vertices)
        #println(all_neighbors(paley, i))
        for j in range(i+1,vertices)
            if i == j
                continue
            end
            neighbors = common_neighbors(graph, i, j)
            push!(common, [i, j, neighbors])
        end
    end
    return common
end

#Verify common neighbor properties
function verifyProperties(graph, vertices)
    common = commonNeighbors(graph, vertices)
    
    for entry in common
        edge = has_edge(graph, entry[1], entry[2])
        numNeighbors = length(common[entry][3])
        if edge && numNeighbors == 1
            continue
        elseif !edge && numNeighbors == 2    
            continue
        else
            print(entry)
            println(" Graph failed checks")S
            return false
         end
         
    end
    println("Graph passed checks!")
    return true
end
#The graph should have 99 vertices
#the graph is a regular graph with 14 edges per vertex.
#every pair of adjacent vertices should have 1 common neighbor, 
#and every pair of non-adjacent vertices should have 2 common neighbors. 
function main()
    paley = SimpleGraph(paley9()) 
    V = 99
    E = 14
    g = random_regular_graph(V, E)

    println("Paley: ")
    verifyProperties(paley, 9)
    println("Random 14-degree graph: ")
    @assert verifyProperties(g, V) == false

    # Plot paley graph
    #graphplot(paley, method=:shell, names=1:9, nodesize=0.3, curves=false)
end
#activate conway99
main()