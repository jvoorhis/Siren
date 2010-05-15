module Siren
  class Voice
    def self.var(name, type, default = nil)
      @vars ||= []
      @vars.push(Var[name, type, default])
      define_method(name) do |val = nil|
        if val.nil?
          Float.new(get(name))
        else
          Float.new(put(name, val))
        end
      end
      protected(name)
    end

    def self.vars
      @vars
    end

    def initialize(kernel, initial_values = {})
      @kernel = kernel
      @state = alloc_render_state(initial_values)
      @voice = C.NewVoice(@kernel, make_render_func(render), make_transition_func(transition), @state)
    end
    
    def dispose
      C.RemoveVoice(@kernel, @voice)
      @state.pointer.free
    end

    def transition
      fail "transition is undefined!"
    end

    def render
      fail "transition is undefined!"
    end                         

    protected

    def var(name)
      self.class.vars.detect { |v| v.name == name }
    end

    def get(name)
      Float.new(Get.new(var(name)))
    end

    def put(name, value)
      Float.new(Put.new(var(name), value.node))
    end
    
    private

    def state_type
      @state_type ||= Class.new(FFI::Struct).tap { |state|
        state.layout *self.class.vars.map { |v| [v.name, v.type] }.flatten
      }
    end

    def state_target_type
      @state_target_type ||= LLVM::Struct(*self.class.vars.map(&:target_type))
    end

    def sample_target_type
      LLVM::Float
    end
    
    def alloc_render_state(initial_values = {})
      data = state_type.new(FFI::MemoryPointer.new(state_type))
      self.class.vars.each do |var|
        data[var.name] = initial_values[var.name] || var.default
      end
      data
    end

    def render_func_sym
      :"render_#{self.class.object_id}"
    end

    def render_func_type
      LLVM.Function([LLVM.Pointer(state_target_type)], sample_target_type)
    end
    
    def make_render_func(expr)
      Mod.functions.add(render_func_sym, render_func_type) do |func, state|
        entry    = func.basic_blocks.append("entry")
        builder  = LLVM::Builder.create
        builder.position_at_end(entry)
        bindings = self.class.vars.inject({}) do |bindings, var|
          bindings[var] = builder.struct_gep(state, self.class.vars.index(var))
          bindings
        end
        codegen = CodeGenerator.new(Mod, func, entry, builder, bindings)
        samp = expr.accept(codegen)
        builder.ret(samp)
      end unless Mod.functions[render_func_sym]
      EE.pointer_to_global(Mod.functions[render_func_sym])
    end

    def transition_func_sym
      :"transition_#{self.class.object_id}"
    end

    def transition_func_type
      LLVM.Function([LLVM.Pointer(state_target_type)], LLVM.Void)
    end

    def make_transition_func(expr)
      Mod.functions.add(transition_func_sym, transition_func_type) do |func, state|
        entry = func.basic_blocks.append("entry")
        builder = LLVM::Builder.create
        builder.position_at_end(entry)
        bindings = self.class.vars.inject({}) do |bindings, var|
          bindings[var] = builder.struct_gep(state, self.class.vars.index(var))
          bindings
        end 
        codegen = CodeGenerator.new(Mod, func, entry, builder, bindings)
        expr.accept(codegen)
        builder.ret_void
      end unless Mod.functions[transition_func_sym]         
      EE.pointer_to_global(Mod.functions[transition_func_sym])
    end
  end
end
