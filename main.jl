
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
            #print("Graph failed checks: ")
            #println(entry)
            return false
         end
         
    end
    println("Graph passed checks!")
    return true
end

function bruteForce(vertices, degree, iterations)
    #Experimental multithreading
    Threads.@threads for i in range(1, iterations)
        g = random_regular_graph(vertices, degree, seed=i)
        #println("Random graph: ")
        if verifyProperties(g, vertices) == true
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
    #Force precompilation
    @time bruteForce(99, 14, 1)
    #TODO Set threads for Julia
    @time bruteForce(99, 14, 1000)
    
end
#activate conway99
main()