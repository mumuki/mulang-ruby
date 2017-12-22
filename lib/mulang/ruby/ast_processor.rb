module Mulang::Ruby
  class AstProcessor < AST::Processor
    include AST::Sexp
    include Mulang::Ruby::Sexp

    def on_class(node)
      name, superclass, body = *node
      body ||= s(:nil)

      _, class_name = *name
      _, superclass_name = *superclass

      ms :Class, class_name, superclass_name, process(body)
    end

    def on_module(node)
      name, body = *node
      body ||= s(:nil)

      _, module_name = *name

      ms :Object, module_name, process(body)
    end

    def on_begin(node)
      sequence(*process_all(node))
    end

    def on_rescue(node)
      try, *catch, _ = *node
      ms :Try, process(try), process_all(catch), ms(:MuNull)
    end

    def on_resbody(node)
      patterns, variable, block = *node

      [to_mulang_pattern(patterns, variable), process(block) || ms(:MuNull)]
    end

    def _
      Object.new.tap { |it| it.define_singleton_method(:==) { |_| true} }
    end

    def to_mulang_pattern(patterns, variable)
      case [patterns, variable]
        when [nil, nil]
          ms :WildcardPattern
        when [nil, _]
          ms :VariablePattern, variable.to_a.first
        when [_, nil]
          to_single_pattern patterns
        else
          ms(:AsPattern, variable.to_a.first, to_single_pattern(patterns))
      end
    end

    def to_single_pattern(patterns)
      mu_patterns = patterns.to_a.map { |it| to_type_pattern it }
      mu_patterns.size == 1 ? mu_patterns.first : ms(:UnionPattern, mu_patterns)
    end

    def to_type_pattern(node)
      _, type = *node
      ms :TypePattern, type
    end

    def on_kwbegin(node)
      process node.to_a.first
    end

    def on_ensure(node)
      catch, finally = *node
      try, catches = on_rescue(catch)[:contents]
      ms :Try, try, catches, process(finally)
    end

    def on_irange(node)
      ms :Other
    end

    def on_regexp(node)
      value, _ops = *node

      simple_send ms(:Reference, :Regexp), :new, [process(value)]
    end

    def on_dstr(node)
      parts = *node

      simple_send ms(:MuList, process_all(parts)), :join, []
    end

    def on_or(node)
      value, other = *node
      simple_send process(value), '||', [process(other)]
    end

    def on_and(node)
      value, other = *node

      simple_send process(value), '&&', [process(other)]
    end

    def on_return(node)
      value = *node

      ms(:Return, process(value.first))
    end

    def on_defs(node)
      _target, id, args, body = *node
      body ||= s(:nil)

      simple_method id, process_all(args), process(body)
    end

    def on_def(node)
      id, args, body = *node
      body ||= s(:nil)

      case id
      when :equal?, :eql?, :==
        mu_method :EqualMethod, process_all(args), process(body)
      when :hash
        mu_method :HashMethod, process_all(args), process(body)
      else
        simple_method id, process_all(args), process(body)
      end
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

    def on_sym(node)
      value, _ = *node
      ms :MuSymbol, value.to_s
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

    alias on_ivar on_lvar
    alias on_ivasgn on_lvasgn

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
