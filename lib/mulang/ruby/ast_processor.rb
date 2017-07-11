module Mulang::Ruby
  class AstProcessor < AST::Processor
    include AST::Sexp
    include Mulang::Ruby::Sexp

    def on_class(node)
      name, superclass, body = *node
      body ||= s(:nil)

      _, class_name = *name
      _, superclass_name = *superclass

      ms :Class, class_name, (superclass_name || :Object), process(body)
    end

    def on_module(node)
      name, body = *node
      body ||= s(:nil)

      _, module_name = *name

      ms :Object, module_name, process(body)
    end

    def on_begin(node)
      ms :Sequence, *process_all(node)
    end

    def on_defs(node)
      _target, id, args, body = *node
      body ||= s(:nil)

      simple_method id, process_all(args), process(body)
    end

    def on_def(node)
      id, args, body = *node
      body ||= s(:nil)

      simple_method id, process_all(args), process(body)
    end

    def on_block(node)
      send, parameters, body = *node
      lambda = ms(:Lambda, process_all(parameters), process(body))
      handle_send_with_args send, [lambda]
    end

    def on_send(node)
      handle_send_with_args(node)
    end

    def on_nil(_)
      ms :MuNull
    end

    def on_self(_)
      ms :Self
    end

    def on_arg(node)
      name, _ = *node
      ms :VariablePattern, name
    end

    alias on_restarg on_arg
    alias on_procarg0 on_arg

    def on_str(node)
      value, _ = *node
      ms :MuString, value
    end

    def on_float(node)
      value, _ = *node
      ms :MuNumber, value
    end

    alias on_int on_float

    def on_if(node)
      condition, if_true, if_false = *node
      if_true  ||= s(:nil)
      if_false ||= s(:nil)

      ms :If, process(condition), process(if_true), process(if_false)
    end

    def on_lvar(node)
      value = *node
      ms :Reference, value.first
    end

    def on_lvasgn(node)
      id, value = *node
      ms :Assignment, id, process(value)
    end

    def on_const(node)
      _ns, value = *node
      ms :Reference, value
    end

    def on_true(_)
      ms :MuBool, true
    end

    def on_false(_)
      ms :MuBool, false
    end

    def on_array(node)
      elements = *node
      {tag: :MuList, contents: process_all(elements)}
    end

    def handler_missing(*args)
      puts args
      ms :Other
    end

    def handle_send_with_args(node, extra_args=[])
      receptor, message, *args = *node
      receptor ||= s(:self)

      if message == :==
        message = {tag: :Equal}
      elsif message == :!=
        message = {tag: :NotEqual}
      else
        message = {tag: :Reference, contents: message}
      end

      ms :Send, process(receptor), message, (process_all(args) + extra_args)
    end
  end
end
