const RequireFile = ARGS[1]

required_packages = split(read(RequireFile, String), r"\n")

using Pkg

for rp in required_packages
  rp = String(rp)
  if length(rp) >= 18 && rp[1:18] == "https://github.com"
    println("Cloning package: ", rp)
    try
      Pkg.clone(rp)
    catch err
      println("Error when cloning $rp: ", err)
    end
  else    
    println("Adding package: ", rp)
    Pkg.add(rp)
  end
end

println("Running Pkg.update()")
Pkg.update()