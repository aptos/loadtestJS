$:.unshift File.expand_path(File.dirname(__FILE__) + '/helper')

require 'rake'
require 'rake/clean'
require 'fileutils'

# Defines
Home = Rake.original_dir
App = "blitz-engine"

ClobberList = [
  "#{Home}/lib/*.js"
]

@tasks_help = []
def hdoc command, desc
  @tasks_help << [command, desc]
end

CLOBBER.include(ClobberList)

CoffeeBin = "/usr/local/bin/coffee"
# CoffeeBin = "node_modules/.bin/coffee"
# JasminBin = "node_modules/.bin/jasmine-node"
# Compressor= "node_modules/.bin/uglifyjs"

task :default => [:help]

task :help do
  @tasks_help.each do |task|
    if task[1].size > 0
      output = "  rake %-20s: %s" % [task[0], task[1]]
    else
      output = "\n+ %-30s %s\n\n" % [task[0], '*'*60 ]
    end
    puts output
  end
end

hdoc 'init', 'npm install: download all dependencies.'
task :init do
  sh "npm install"
end

hdoc'compile', 'compile coffee-script codes to javascript.'
task :compile => [:init, :clobber] do
  sh "#{CoffeeBin} -o lib/ -cb src/"
end

hdoc 'compile_run', 'compile and run the node app'
task :compile_run => [:compile, :run]

hdoc 'run', 'run the node app'
task :run do
  options = "-nouse-idle-notification"
  sh "node #{Home}/lib/#{App}.js #{options}"
end

hdoc 'dev', 'run the coffee-script app with source'
task :dev do
  sh "#{CoffeeBin} #{Home}/src/#{App}.coffee"
end

# hdoc 'spec', 'run jasmin spec unit tests'
# task :spec => [:compile] do
#   options = "" # --junitreport 
#   sh "#{JasminBin} --verbose --forceexit #{options} spec/"
# end

# hdoc 'spec_each', 'run jasmin a spec unit test one by one'
# task :spec_each => [:compile] do
#   line = "*"*80
#   spec_files = Dir.glob("{spec}/*")
#   spec_files.each do |f|
#     puts "\n#{line}\n>> run #{f}\n#{line}\n"
#     sh "#{JasminBin} --noColor --forceexit --verbose #{f}"
#   end
# end

# hdoc 'compress', 'compress javascript files'
# task :compress => [:compile] do
#   Dir.glob("{lib}/**/*").each { |filename|
#     next if File.directory? (filename)
#     sh "#{Compressor} --overwrite #{filename}"
#   }
# end





