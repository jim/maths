module Maths
  class Environment

    def initialize(binding = nil)
      @binding = binding || Binding.setup(Rubinius::VariableScope.of_sender,
                                          Rubinius::CompiledMethod.of_sender,
                                          Rubinius::ConstantScope.of_sender,
                                          self)
    end

    def eval(string)
      cm = Maths::Compiler::compile(string) do |c|
        c.generator.variable_scope = @binding.variables
      end

      cm.scope = Rubinius::StaticScope.new(Maths::Runtime)

      script = Rubinius::CompiledMethod::Script.new(cm, '(maths)', true)
      script.eval_source = string
      cm.scope.script = script

      be = Rubinius::BlockEnvironment.new
      be.under_context @binding.variables, cm
      be.from_eval!
      be.set_eval_binding @binding
      be.call_on_instance(self)
    end

  end

end
