require 'llvm/core'
require 'llvm/execution_engine'

module Siren
  LLVM.init_x86
  Mod = LLVM::Module.create("Siren")
  Mod.functions.add(:powf, [LLVM::Float, LLVM::Float], LLVM::Float)
  Mod.functions.add(:sinf, [LLVM::Float], LLVM::Float)
  Mod.functions.add(:cosf, [LLVM::Float], LLVM::Float)
  Mod.functions.add(:tanf, [LLVM::Float], LLVM::Float)

  EE = LLVM::ExecutionEngine.create_jit_compiler(
    LLVM::ModuleProvider.for_existing_module(Mod)
  )

  class CodeGenerator
    def initialize(mod, function, basic_block, builder, bindings)
      @module = mod
      @function = function
      @basic_block = basic_block
      @bindings = bindings
      @builder = builder

      @builder.position_at_end(@basic_block)
    end

    def visit_literal_float(float)
      LLVM::Float(float)
    end

    def visit_data(data)
      data
    end

    def visit_fmul(lhs, rhs)
      @builder.fmul(lhs, rhs)
    end

    def visit_fdiv(lhs, rhs)
      @builder.fdiv(lhs, rhs)
    end

    def visit_fadd(lhs, rhs)
      @builder.fadd(lhs, rhs)
    end
    
    def visit_fsub(lhs, rhs)
      @builder.fsub(lhs, rhs)
    end

    def visit_fcmp(pred, lhs, rhs)
      @builder.fcmp(pred, lhs, rhs)
    end

    def visit_pow(lhs, rhs)
      pow = @module.functions[:powf]
      @builder.call(pow, lhs, rhs)
    end

    def visit_sin(arg)
      sin = @module.functions[:sinf]
      @builder.call(sin, arg)
    end

    def visit_cos(arg)
      cos = @module.functions[:cosf]
      @builder.call(cos, arg)
    end
    
    def visit_tan(arg)
      tan = @module.functions[:tanf]
      @builder.call(tan, arg)
    end

    def visit_literal_bool(val)
      LLVM::Int1.from_i(val)
    end

    def visit_get(var)
      if pointer = @bindings[var]
        @builder.load(pointer)
      else
        fail "Unbound variable #{var}!"
      end
    end

    def visit_put(var, value)
      if pointer = @bindings[var]
        @builder.store(value, pointer)
      else
        fail "Undeclared variable #{var}!"
      end
      nil
    end

    def visit_select(condition, consequent, alternative)
      @builder.select(condition, consequent, alternative)
    end
  end
end
