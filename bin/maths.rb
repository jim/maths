require 'rubygems'
require 'optparse'
require 'ostruct'
require 'pp'

$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'maths'

code = <<-CODE
a = (2 + 5) * 3
Print 2 * a
x = 101 / 3
c = 43
Print x + c
CODE

options = OpenStruct.new
options.run = true

OptionParser.new do |opts|
  opts.banner = "Maths."

  opts.on('-p', '--parse', 'Print results of initial parse') do |p|
    options.parse = p
  end

  opts.on('-g', '--graph', 'Print AST graph') do |g|
    options.graph = g
  end

  opts.on('-s', '--sexp', 'Print s-expression representation of AST') do |s|
    options.sexp = s
  end

  opts.on('-r', '--[no-]run', 'Execute the code') do |r|
    options.run = r
  end
end.parse!

compiled = Maths::Compiler.compile(code) do |compiler|
  compiler.parser.print_tree if options.parse
  compiler.transform.print_ast if options.graph
  compiler.transform.print_sexp if options.sexp
end

Rubinius.run_script(compiled) if options.run
