require 'readline'

module Maths
  class REPL
    def initialize(env=Environment.new)
      @environment = env
      @line = 0
    end

    def start
      puts "Welcome to maths. Type 'exit' to quit."
      loop do
        @line += 1
        process_input
      end
    end

    private

    def process_input
      code = Readline.readline "maths:#{@line}> "
      exit 0 unless code and code != "exit"
      puts @environment.eval(code, '(repl)', @line) unless code =~ /^\s*$/
    rescue Maths::Runtime::Error => e
      puts colorize(e.message, :red)
      puts colorize(code, :yellow)
      puts ' ' * (e.column - 1) + '^'
    rescue Interrupt
      puts "\nBye!"
      exit
    end

    def colorize(text, color=:red)
      codes = { red: 31, yellow: 33 }
      "\033[0;#{codes[color]}m#{text}\033[0m"
    end
  end
end
