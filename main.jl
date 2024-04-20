#Current intent - make method that directly generates (generateGraph() calls makeRow()) Adjacency Matrix to manipulate more efficiently in check2()
#Eventually this is too brute force search graphs of 99,14,1,2 preferably on GPU

using Random
using Graphs, GraphRecipes, Plots
using BenchmarkTools, Profile
using CUDA
using Test

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
#You are not expected to understand this
function allPermutations(n, k)
    # https://programmingforinsomniacs.blogspot.com/2018/03/gospers-hack-explained.html
    # https://iamkate.com/code/hakmem-item-175/
    adj_mat = Array{Int128}(undef, binomial(n, k))
    set::Int128 = 2^k - 1 
    limit::Int128 = 2^n 
    i::Int128 = 1
    while (set < limit)
        adj_mat[i] = set
        #Gosper's hack:
        c = set & - set # c is equal to the rightmost 1-bit in set.
        r = set + c # Find the rightmost 1-bit that can be moved left into a 0-bit. Move it left one
        set = (((r ⊻ set) >> 2) ÷ c) | r # take the other bits of the rightmost cluster of 1 bits and place them as far to the right as possible 
        i+=1
    end
    return adj_mat
end

#TODO https://www.redperegrine.net/2021/04/10/software-algorithms-for-k-combinations/#Another-Numbers-Game
#TODO Get this to map to k-combination
#TODO Divide desired rank by 2^rank to determine if it will have a 1 in (n,n) (loop)?
#Returns the k-combination of (n choose k) with the provided rank
function makeRow(n, k, rank)
    
    dualOfZero = n - 1
    #Calculate the dual (base zero)
    
    dual = binomial(n, k) - rank
    
    #Gets combinadic of dual
    combination = combinadic(n, k, dual)

    i = 1
    while i <= k
        #Map to zero-based combination
        combination[i] = dualOfZero - combination[i]

        #Add 2 (for base 2)
        combination[i] += 1
        i += 1
    end

    return combination
end

#Calculates zero-based array of c such that maxRank = (c1 choose k-1) + (c2 choose k-2) + ... (c[of k-1] choose 1)
function combinadic(n, k, maxRank)
    result = Array{Int}(undef, k)
    diminishingRank = maxRank
    reducingK = k

    i = 1
    while i <= k
        result[i] = largestValue(n, reducingK, diminishingRank)   
        diminishingRank -= binomial(result[i], reducingK)
        reducingK -= 1
        i += 1
    end
    return result
end

function binomialCheck(row)
    result = 0
    counter = 0
    len = length(row)
    for i in range(1, len)
        result += binomial(row[i], len - counter)
        counter += 1
    end
    return result
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
    n = 5
    k = 3
    start  = 1#14000000
    finish = 1000#20000000
    rank = 1
    #Graph to pass to GPU (use CuArray in main)
    #graph = CuArray{Int}(undef, (degree + 2) * vertices)
    
    #Compare brute force methods
    #@btime bruteForce($V, $D, $start, $finish)
    #@btime bruteForce2($V, $D, $start, $finish)
    #@time bruteForce(99, 14, start, finish)

    #Compare graph generation 
    #@btime random_regular_graph($V, $D)
    
    row = makeRow(n, k, rank)
    target = allPermutations(n, k)
    actual = binomialCheck(row)
    println("Row: " * string(row))
    println("Target: " * string(target))
    @test target[rank] == actual
    #if isfile("Winner! Seed - 19.lgz")
        #g = loadgraph("Winner! Seed - 19.lgz")
        #graphplot(paley, method=:shell, nodesize=0.3, names=1:9, curves=false)
    #end
end
main()