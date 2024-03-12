
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

#Print common neighbors 
function commonNeighbors(graph, vertices)
    common = []
    println("Common neighbors:")
    for i in range(1,vertices)
        #println(all_neighbors(paley, i))
        for j in range(i+1,vertices)
            if i == j
                continue
            end
            neighbors = common_neighbors(graph, i, j)
            #TODO Make it work for vertices with 2 common neighbors
            if
            push!(common, [i, j, ])
        end
    end
    return common
end
#The graph should have 99 vertices
#the graph is a regular graph with 14 edges per vertex.
#every pair of adjacent vertices should have 1 common neighbor, 
#and every pair of non-adjacent vertices should have 2 common neighbors. 
function main()
    paley = SimpleGraph(paley9()) 
    common = commonNeighbors(paley, 9)

    #TODO adjacent vertices have 1 neighbor, non-adjacent have 2
    #https://juliagraphs.org/Graphs.jl/dev/first_steps/access/
    for entry in common
        if has_edge(paley, entry[1], entry[2])
            #TODO 
            println(entry)
            
        end 
        
    end

    # Plot paley graph
    #graphplot(paley, method=:shell, names=1:9, nodesize=0.3, curves=false)
end
#activate conway99
main()