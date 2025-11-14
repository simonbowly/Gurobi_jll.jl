# Copyright (c) 2024 Oscar Dowson, and contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

using Tar, Inflate, SHA, TOML

function get_artifact(data; version::String, shortversion::String)
    filename = "gurobi$(version)_$(data.platform).tar.gz"
    url = "https://packages.gurobi.com/$shortversion/gurobi$(version)_$(data.platform).tar.gz"
    run(`wget $url`)
    ret = Dict(
        "git-tree-sha1" => Tar.tree_hash(`gzcat $filename`),
        "arch" => data.arch,
        "os" => data.os,
        "download" => Any[
            Dict("sha256" => bytes2hex(open(sha256, filename)), "url" => url),
        ]
    )
    rm(filename)
    return ret
end

function main(; shortversion, version)
    platforms = [
        (os = "linux", arch = "x86_64", platform = "linux64"),
        (os = "linux", arch = "aarch64", platform = "armlinux64"),
        (os = "windows", arch = "x86_64", platform = "win64"),
    ]
    output = Dict("Gurobi" => get_artifact.(platforms; version, shortversion))
    open(joinpath(dirname(@__DIR__), "Artifacts.toml"), "w") do io
        return TOML.print(io, output)
    end
    return
end

#   julia --project=scripts scripts/update_artifacts.jl shortversion version`
#
# Update the Artifacts.toml file.
if !isempty(ARGS)
    main(; shortversion = ARGS[1], version = ARGS[2])
end
