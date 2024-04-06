using Random
using Graphs, GraphRecipes, Plots
using BenchmarkTools, Profile
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
function check2(adj_mat)
    num_neigh_mat = transpose(adj_mat) * adj_mat
    for i in range(1, length(adj_mat))
        if num_neigh_mat[i] == 4
            continue
        elseif adj_mat[i] == 1 && num_neigh_mat[i] == 1 || adj_mat[i] == 0 && num_neigh_mat[i] == 2
            continue
        else
            return false
        end
    end
    return true   
end

#Generates all combinations of bitstrings of length n with k bits flipped in order
function gospersHack(n, k)
    # https://programmingforinsomniacs.blogspot.com/2018/03/gospers-hack-explained.html
    adj_mat = Array{Int128}(undef, binomial(n, k)) #TODO taking a lot of memory
    set::Int128 = 2^k - 1
    limit::Int128 = 2^n
    i::Int128 = 1
    while (set < limit)
        #TODO Have only degree ones, no loops 
        adj_mat[i] = set #digits(set, base=2, pad = n)
        #Gosper's hack:
        c = set & - set
        r = set + c
        set = (((r ⊻ set) >> 2) ÷ c) | r #wat
        i+=1
    end
    return adj_mat
end
#Makes random bitstring of length vertices based on seed
function makeRow(vertices, seed)
    Random.seed!(seed)
    min_val = BigInt(1)
    max_val = BigInt(2)^vertices
    
    return [last(digits(base=2, rand(min_val:max_val), pad = vertices), vertices)] 
end
#Generates a (99, 14) graph 
function generateGraph(vertices, degree, seed)
    adj_mat = [makeRow(vertices, seed) for i in 1:vertices]
    return adj_mat

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
        g = generateGraph(vertices, degree, i)
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
    paley = paley9()
    V = 25
    D = 14
    start  = 0
    finish = 1000
    seed = 10
    #Graph to pass to GPU (use CuArray in main)
    #graph = CuArray{Int}(undef, (degree + 2) * vertices)
    
    #Compare brute force methods
    #@btime bruteForce($V, $D, $start, $finish)
    #@btime bruteForce2($V, $D, $start, $finish)

    #Compare graph generation 
    #@btime random_regular_graph($V, $D)
    #@btime generateGraph($V, $D, $seed)
    #@btime makeRow($V, $seed)

    @time gospersHack(V,D) #TODO Turn into graph generator, simply generates all possiblities right now
    #@btime gospersHack($V, $D)
    #if isfile("Winner! Seed - 19.lgz")
        #g = loadgraph("Winner! Seed - 19.lgz")
        #graphplot(paley, method=:shell, nodesize=0.3, names=1:9, curves=false)
    #end
end
main()