desc "Run test suite"
task :test do
    sh "julia --color=yes -e 'using Pkg; Pkg.test(\"MultiDistances\")'"
end

task :default => :test

def loc_of_files(files)
  lines = files.map {|fn| File.readlines(fn)}
  nonblanklines = lines.map {|ls| ls.select {|line| line.strip.length > 0}}
  loc = lines.map {|ls| ls.length}.inject(0) {|s,e| s+e}
  nbloc = nonblanklines.map {|ls| ls.length}.inject(0) {|s,e| s+e}
  return loc, nbloc, files.length
end

desc "Count LOC"
task :loc do
  srcloc, srcnbloc, numsrcfiles = loc_of_files(Dir["src/**/*.jl"])
  testloc, testnbloc, numtestfiles = loc_of_files(Dir["test/**/*.jl"])
  puts "Source files: #{numsrcfiles} files\t\t#{srcloc} LOC\t\t(#{srcnbloc} non-blank LOC)"
  puts "Test   files: #{numtestfiles} files\t\t#{testloc} LOC\t\t(#{testnbloc} non-blank LOC)"
  if testloc > 0 && srcloc > 0
    puts("Test to code ratio:\t\t%.3f   \t\t(%.3f)" % [(testloc.to_f/srcloc), (testnbloc.to_f/srcnbloc)])
  end
end

task :clobber do
  sh "rm -rf *.csv *.json test/data/*.csv test/data/*.json"
end

DockerUser = "robertfeldt"
DockerImageName = "mdist"
Tag = File.open("VERSION", "r") {|fh| fh.read().strip()}

StartTime = Time.now
Timestamp = StartTime.strftime("%Y%m%d_%H%M%S")
TimestampDate = StartTime.strftime("%Y-%m-%d")
TimestampTime = StartTime.strftime("%H:%M.%S")

def save_timestamp()
  File.open("TIMESTAMP", "w") {|fh| fh.puts("#{Timestamp}")}
  File.open("LATESTGITID", "w") {|fh| fh.puts(`git log --format="%H" -n 1`)}
end

def docker_build_image(dockerfile, dockeruser, imagename, tag)
  # Delete any previous soft links
  sh "rm -f Dockerfile"

  # Soft link the dockerfile since Docker requires the Dockerfile to be in root...
  sh "ln -s #{dockerfile} Dockerfile"

  time = Time.now

  # Build the docker image and also tag as latest
  sh "docker build -t=\"#{dockeruser}/#{imagename}:#{tag}\" . | tee .build.log || exit 1"
  id = `tail -1 .build.log | awk '{print $3;}'`
  id = id.strip
  sh "docker tag #{id} #{dockeruser}/#{imagename}:latest"
  sh "rm .build.log"

  elapsed = Time.now - time
  puts "Time taken for build: #{elapsed} seconds"

  # Now clean up the soft link we created as well as temp files
  sh "rm Dockerfile"
  sh "rm -rf TIMESTAMP LATESTGITID"
end

desc "Build docker image"
task :build_docker_image do
  save_timestamp()

  docker_build_image("docker/mdist.Dockerfile",
    DockerUser, DockerImageName, Tag
  )
end
task :build => :build_docker_image
task :bdi => :build_docker_image

desc "Create precompile.jl file to precompile all libs"
task :precompilefile => ['bin/make_precompile_file.jl'] do
  sh "julia bin/make_precompile_file.jl"
end

desc "Push latest docker image to Docker hub"
task :upload do
  sh "docker push robertfeldt/#{DockerImageName}:#{Tag}"
  sh "docker push robertfeldt/#{DockerImageName}:latest"
end

desc "Remove all <none> docker images"
task :rmallnone do
  images = `docker images`
  images.split(/\n/).each do |line|
    regexp = Regexp.new("^<none>\\s+<none>\\s+([a-z0-9]+)\\s+")
    m = regexp.match(line)
    if m != nil
      puts "Found <none> image: #{m[1]}"
      sh "docker rmi -f #{m[1]}"
    end
  end
end

desc "Run mdist in the built docker image"
task :rundbr do
  sh "docker run -it -v \"$PWD\":/data #{DockerUser}/#{DockerImageName}:#{Tag} julia /usr/src/MultiDistances/bin/mdist"
end

desc "Test docker image"
task :dockertest do
  sh "docker run -it -v \"$PWD\":/data #{DockerUser}/#{DockerImageName}:#{Tag} mdist --distance ncd-bzip2 --verbose distances test/data"
  sh "docker run -it -v \"$PWD\":/data #{DockerUser}/#{DockerImageName}:#{Tag} mdist --distance jaccard --verbose dist test/data/martha.txt test/data/marhta.txt"
  sh "docker run -it -v \"$PWD\":/data #{DockerUser}/#{DockerImageName}:#{Tag} mdist --distance levenshtein --verbose query test/data/martha.txt test/data"
end

desc "Clean docker build"
task :cleandocker do
  sh "rm -rf Dockerfile .build.log LATESTGITID TIMESTAMP"
end
