# Copy paste utils into file 
include("utils.jl")


function can_build_in(robots, inv, cost)
    robots = robots[1:3]
    if all(inv .>= cost)
        1
    else
        nonzero = findall(.!=(0), cost)
        time = (cost - inv)./robots
        time = maximum(time[nonzero])
        if time == Inf
            false
        else
            1 + ceil(Int, time)
        end
    end    
end

function bfs2(total_time, costs, init_robots)
    # Reachable are the bfs frontiers. So reachable[i] are all the possilbe
    # states we can reach at time i.
    reachable = [[] for _ in 1:total_time]
    for build in 1:3
        can_build = can_build_in(init_robots, [0,0,0], costs[build, :])
        if can_build != false
            # How much we have after completng the robot
            new_inv = can_build.*init_robots[1:3] - costs[build, :]
            robots = copy(init_robots)
            robots[build] += 1
            push!(reachable[can_build], (robots, new_inv, 0))
        end
    end

    # Set of all (robots, inventory, geo) which have already been reached.
    # Not really normal dynamic programming, but if a state has already been
    # found we con't have to do it again. But we don't save a value for it.
    cache = Set()

    max_costs = [maximum(costs[1:end, type]) for type in 1:3]

    best = 0
    for time in 1:(total_time - 1)
        for (robots, inv, geo) in reachable[time]

            # The robots we will try to build.
            # Don't build a robot if we have already maxed out that production.
            # In that case also remove excess from inv to shrink state space.
            try_build = [4]
            for type in 1:3
                if robots[type] == max_costs[type]
                    inv[type] = min(max_costs[type], inv[type])
                else
                    push!(try_build, type)
                end
            end
        
            # If we have already cache the state, just continue
            hash = tuple(robots..., inv..., geo)
            if hash in cache
                continue
            else
                push!(cache, hash)
            end
            
            # Try and build the different robots, spawn a new state for each
            for build in try_build
                can_build = can_build_in(robots, inv, costs[build, :])
                if can_build != false && can_build + time < total_time
                    # Can build is the time until the robot is finished
                    new_time = time + can_build
                    new_inv = inv + can_build.*robots[1:3] - costs[build, :]
                    new_robots = copy(robots)
                    new_robots[build] += 1

                    if build == 4
                        new_geo = geo + total_time - new_time
                        best = max(best, new_geo)
                        push!(reachable[new_time], (new_robots, new_inv, new_geo))
                        if can_build == 1
                            # If we can build geo, we always do. Only uncertain heuristic
                            break
                        end
                    else
                        push!(reachable[new_time], (new_robots, new_inv, geo))
                    end
                end
            end
        end
    end

    best
    
end

function parse_blueprints(input)
    rstr = r".*ore robot costs (?:(\d+) ore)?(?:(?: and)? (\d+) clay)?(?:(?: and)? (\d+) obsidian)?.*clay robot costs (?:(\d+) ore)?(?:(?: and)? (\d+) clay)?(?:(?: and)? (\d+) obsidian)?.*obsidian robot costs (?:(\d+) ore)?(?:(?: and)? (\d+) clay)?(?:(?: and)? (\d+) obsidian)?.*geode robot costs (?:(\d+) ore)?(?:(?: and)? (\d+) clay)?(?:(?: and)? (\d+) obsidian)?\..*"
    map(parse_re_lines(input, rstr)) do caps
        reshape(parse.(Int, replace(caps, nothing => "0")), (3, 4))'
    end
end

function main(input="input.txt")
    blueprints = parse_blueprints(input)

    # Part 1
    map(enumerate(blueprints)) do (ind, costs)
        bfs2(24, costs, [1, 0, 0, 0]) * ind
    end |> sum |> println

    # Part 2
    map(blueprints[1:3]) do costs
        bfs2(32, costs, [1, 0, 0, 0])
    end |> prod |> println
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end