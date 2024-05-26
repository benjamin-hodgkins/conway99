#Current intent - allPermutations() checks each permutation of the first row with valid following rows with checkPermutation() 
# This then goes into check2() to check the full adjacency matrix
#Eventually this is too brute force search graphs of 99,14,1,2 preferably on GPU

using Random, Combinatorics
using Graphs, GraphRecipes, Plots
using BenchmarkTools, Profile
#using CUDA
using Test

#Returns Adjacency matrix of {9,4,1,2} (Paley 9)
function paley9()
    adj_mat = Array{Int8}([
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
    for i in range(1, vertices)
        for j in range(i + 1, vertices)
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

#Generates all permutations of bitstrings of length n with k bits flipped in order
#You are not expected to understand this
function allPermutations(n, k)
    # https://programmingforinsomniacs.blogspot.com/2018/03/gospers-hack-explained.html
    # https://iamkate.com/code/hakmem-item-175/
    combs = []
    set::Int128 = 2^k - 1
    limit::Int128 = 2^n
    i::Int128 = 1
    while (set < limit)
        valid = checkPermutation(set, n)
        if valid
            return set
        end
        #Gosper's hack:
        c = set & -set # c is equal to the rightmost 1-bit in set.
        r = set + c # Find the rightmost 1-bit that can be moved left into a 0-bit. Move it left one
        set = (((r ⊻ set) >> 2) ÷ c) | r # take the other bits of the rightmost cluster of 1 bits and place them as far to the right as possible 
        i += 1
    end
    return combs
end

function checkPermutation(set, n)
    #If there is a loop in postion one, return (invalid permutation to check)
    bits = digits(Int, set, base=2, pad=n)
    if bits[1] == 1
        #return false
    end

    #Initialize first and last rows and start counting degrees of vertices
    firstRow = reverse(bits)
    adj_mat = zeros(Int, n, n)
    adj_mat[1, :] = firstRow
    adj_mat[end, :] = bits
    previousRow = firstRow
    degreeDict = Dict{Int, Int}()

    
    for i::Int in 1:length(firstRow)
        if firstRow[i] == 1
            degreeDict[i] = 1
        else
            degreeDict[i] = 0
        end
    end

    #TODO Algorithm from notebook
    for i::Int in 2:n
        for j::Int in 1:n
            
        end
        #previousRow = currentRow
    end
    display(adj_mat)
    #return true
end

function bruteForce(vertices, degree, start, finish)
    #Multithreading
    Threads.@threads for i in range(start, finish)
        g = random_regular_graph(vertices, degree, seed=i)
        if check(g, vertices) == true
            fName = "Winner(1)! Seed - " * string(i) * (".lgz")
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
            fName = "Winner(2)! Seed - " * string(i) * (".lgz")
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
    n = 7
    k = 4
    start = 1#50000000
    finish = 100
    #Graph to pass to GPU (use CuArray in main)
    #graph = CuArray{Int}(undef, (degree + 2) * vertices)

    #Compare brute force methods
    #@btime bruteForce($V, $D, $start, $finish)
    #@btime bruteForce2($V, $D, $start, $finish)
    #@time bruteForce(n, k, start, finish)
    #@printf("Checked: %i : %i, Total: %i\n", start, finish, finish-start)

    #Compare graph generation 
    #@btime random_regular_graph($V, $D)

    #@btime allPermutations($n,$k)


    #perms = allPermutations(n, k)
    checkPermutation(15, n)
    if isfile("Winner(1)! Seed - 19.lgz")
        #g = loadgraph("Winner(1)! Seed - 19.lgz")
        #graphplot(paley, method=:shell, nodesize=0.3, names=1:9, curves=false)
    end
end
main()