#Current intent - allPermutations() checks each permutation of the first row with valid following rows with checkPermutation() 
# This then goes into check2() to check the full adjacency matrix
#Eventually this is too brute force search graphs of 99,14,1,2 preferably on GPU

using Random, Combinatorics
using Graphs, GraphRecipes, Plots
using BenchmarkTools, Profile
using CUDA
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
end

#Gets locations of flipped bits in b
function bitLocations(b::Integer)
    flippedBits = ones(Int, count_ones(b))
    j = 1
    bStr = digits(b, base=2)
    for i in range(1, length(bStr))
        if bStr[i] == 1
            flippedBits[j] = i
            j += 1
        end
    end
    return flippedBits
end

function checkPermutation(set, n)
    #TODO Check each permutation of first row and following rows
    bits = bitLocations(set)
    firstRow = reverse(digits(Int8, set, base=2, pad=n))

    #If there is a loop, return 
    if n in bits
        return false
    end

    #Set length to the first half of the 2d array, minus the middle row if applicable
    length::Int = 0
    if n % 2 == 0 
        length = n / 2
    else
        length = (n - 1) / 2
    end

    adj_mat = zeros(Int8, length, n)
    adj_mat[1, :] = firstRow
    
    for i::Int in length #TODO Skip first row
        #TODO pick next row based on bitmasks
        nextRow = digits(Int8, set, base=2, pad=n)
        adj_mat[i,:] = nextRow
    end
    display(adj_mat)
    return true
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
    n = 5
    k = 2
    start = 1#50000000
    finish = 200
    #Graph to pass to GPU (use CuArray in main)
    #graph = CuArray{Int}(undef, (degree + 2) * vertices)

    #Compare brute force methods
    #@btime bruteForce($V, $D, $start, $finish)
    #@btime bruteForce2($V, $D, $start, $finish)
    #@time bruteForce(99, 14, start, finish)
    #@printf("Checked: %i : %i, Total: %i\n", start, finish, finish-start)

    #Compare graph generation 
    #@btime random_regular_graph($V, $D)

    #TODO Make first half of graph, insert middleRow, copy first half and reverse for last half
    middleRow = [Int8(0)]
    append!(middleRow, repeat([1, 0], Int((n - 1) / 2))) #TODO Wrong

    #@btime allPermutations($n,$k)
    allPermutations(n, k)

end
main()