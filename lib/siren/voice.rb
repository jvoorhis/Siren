module Siren
  class Voice
    include Siren

    def self.param(name, type, default = nil)
      @params ||= []
      @params.push(Var[name, type, default])
      define_method(name) { get(name) }
      protected(name)
    end

    def self.params
      @params
    end

    def initialize(kernel, initial_values = {})
      @kernel = kernel
      @state = alloc_render_state(initial_values)
      @render_func = make_render_func #(render)
      # @update_func = make_update_func(update(@kernel.ts))
      @voice = C.NewVoice(@kernel, @render_func, @state)
    end
    
    def dispose
      C.RemoveVoice(@kernel, @voice)
    end

    def render
      fail "render is undefined!"
    end                         

    def update(ts)
      fail "update is undefined!"
    end

    def tail
      0.0
    end

    protected

    def param(name)
      self.class.params.detect { |v| v.name == name }
    end

    def get(name)
      Float.new(Get.new(param(name)))
    end

    def set(name, value)
      Float.new(Set.new(param(name), value.node))
    end
    
    private

    def state_type
      @state_type ||= Class.new(FFI::Struct).tap { |state|
        state.layout *self.class.params.map { |v| [v.name, v.type] }.flatten
      }
    end

    def state_target_type
      @state_target_type ||= LLVM::Struct(*self.class.params.map(&:target_type))
    end

    def sample_target_type
      LLVM::Float
    end
    
    def alloc_render_state(initial_values = {})
      data = state_type.new(FFI::MemoryPointer.new(state_type))
      self.class.params.each do |param|
        data[param.name] = initial_values[param.name] || param.default
      end
      data
    end

    def render_func_sym
      :"render_#{self.class.object_id}"
    end

    def render_func_type
      LLVM.Function([LLVM::Float, LLVM::Float, LLVM::Int, LLVM.Pointer(state_target_type)],
                    sample_target_type)
    end
    
    def make_render_func
      Mod.functions.add(render_func_sym, render_func_type) do |func, gt, vt, channel, state|
        builder = LLVM::Builder.create
        entry = func.basic_blocks.append("entry")
        builder.position_at_end(entry)

        bindings = self.class.params.inject({}) do |bindings, param|
          bindings[param] = builder.struct_gep(state, self.class.params.index(param))
          bindings
        end

        gt = Float.new(Data.new(gt))
	vt = Float.new(Data.new(vt))
	c  = Int.new(Data.new(channel))
        expr = render(gt, vt, c)

        codegen = CodeGenerator.new(Mod, func, entry, builder, bindings)
        samp = expr.accept(codegen)
        builder.ret(samp)
      end unless Mod.functions[render_func_sym]
      EE.pointer_to_global(Mod.functions[render_func_sym])
    end

    def update_func_sym
      :"update_#{self.class.object_id}"
    end

    def update_func_type
      LLVM.Function([LLVM.Pointer(state_target_type)], LLVM.Void)
    end

    def make_update_func(expr)
      Mod.functions.add(update_func_sym, update_func_type) do |func, state|
        entry = func.basic_blocks.append("entry")
        builder = LLVM::Builder.create
        builder.position_at_end(entry)
        bindings = self.class.params.inject({}) do |bindings, param|
          bindings[param] = builder.struct_gep(state, self.class.params.index(param))
          bindings
        end 
        codegen = CodeGenerator.new(Mod, func, entry, builder, bindings)
        expr.accept(codegen)
        builder.ret_void
      end unless Mod.functions[update_func_sym]         
      EE.pointer_to_global(Mod.functions[update_func_sym])
    end
  end
end
