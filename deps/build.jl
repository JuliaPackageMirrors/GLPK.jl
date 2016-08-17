using BinDeps

using Compat
using Compat: unsafe_string, is_apple

@BinDeps.setup

include("verreq.jl")

glpkname = "glpk-$glpkdefver"
glpkwinname = "glpk-$glpkwinver"
glpkdllname = "glpk_$(replace(glpkdefver, ".", "_"))"
glpkwindllname = "glpk_$(replace(glpkwinver, ".", "_"))"

const _dlsym = Libdl.dlsym

function string_version(str)
    VersionNumber(str)
end

function glpkvalidate(name, handle)
    ver_str = unsafe_string(ccall(_dlsym(handle, :glp_version), Ptr{UInt8}, ()))
    ver = string_version(ver_str)
    glpkminver <= ver <= glpkmaxver
end
glpkdep = library_dependency("libglpk", aliases = [glpkdllname,glpkwindllname],
                             validate = glpkvalidate)

# Build from sources (used by Linux, BSD)
julia_usrdir = normpath("$JULIA_HOME/../") # This is a stopgap, we need a better builtin solution to get the included libraries
libdirs = AbstractString["$(julia_usrdir)/lib"]
includedirs = AbstractString["$(julia_usrdir)/include"]

@compat provides(Sources, Dict(URI("http://ftp.gnu.org/gnu/glpk/$glpkname.tar.gz") => glpkdep), os = :Unix)
@compat provides(BuildProcess, Dict(
    Autotools(libtarget = joinpath("src", ".libs", "libglpk.la"),
              configure_options = AbstractString["--with-gmp"],
              lib_dirs = libdirs,
              include_dirs = includedirs) => glpkdep
    ), os = :Unix)


# Homebrew (OS X section)
if is_apple()
    using Homebrew
    if Homebrew.installed("glpk") # remove old conflicting version
        Homebrew.rm("glpk")
    end
    provides(Homebrew.HB, "glpk452", glpkdep, os = :Darwin)
end

# Windows
provides(Binaries, URI("https://bintray.com/artifact/download/tkelman/generic/win$glpkwinname.zip"),
         glpkdep, unpacked_dir="$glpkwinname/w$(Sys.WORD_SIZE)", os = :Windows)

@compat @BinDeps.install Dict(:libglpk => :libglpk)
