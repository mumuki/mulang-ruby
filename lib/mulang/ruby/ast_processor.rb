module Mulang::Ruby
  class AstProcessor < AST::Processor
    include AST::Sexp
    include Mulang::Ruby::Sexp

    def initialize
      @contexts = []
    end

    def process(node)
      node.nil? ? none : super
    end

    def on_class(node)
      @contexts.push :class

      name, superclass, body = *node

      _, class_name = *name
      _, superclass_name = *superclass

      ms :Class, class_name, superclass_name, process(body)
    ensure
      @contexts.pop
    end

    def on_sclass(node)
      @contexts.push :sclass

      target, body = *node

      ms :EigenClass, process(target), process(body)
    ensure
      @contexts.pop
    end

    def on_module(node)
      @contexts.push :module

      name, body = *node

      _, module_name = *name

      ms :Object, module_name, process(body)
    ensure
      @contexts.pop
    end

    def on_begin(node)
      if node.children.size == 1 && node.children[0].nil?
        none # ruby < 2.6 only
      else
        sequence(*process_all(node))
      end
    end

    def on_rescue(node)
      try, *catch, _ = *node
      ms :Try, process(try), process_all(catch), none
    end

    def on_resbody(node)
      patterns, variable, block = *node

      [to_mulang_pattern(patterns, variable), process(block) || none]
    end

    def _
      Object.new.tap { |it| it.define_singleton_method(:==) { |_| true } }
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
      ms :Other, node.to_s, nil
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
      target, id, args, body = *node

      result = simple_method id, process_all(args), process(body)

      if target.type == :self
        if @contexts.last == :module
          result
        else
          ms(:Decorator, [ms(:Classy)], result)
        end
      else
        ms(:EigenClass, process(target), result)
      end
    end

    def on_def(node)
      id, args, body = *node

      case id
      when :equal?, :eql?, :==
        primitive_method :Equal, process_all(args), process(body)
      when :hash
        primitive_method :Hash, process_all(args), process(body)
      else
        simple_method id, process_all(args), process(body)
      end
    end

    def on_block(node)
      send, parameters, body = *node
      lambda = ms(:Lambda, process_all(parameters), process(body) || none)
      handle_send_with_args send, [lambda]
    end

    def on_send(node)
      handle_send_with_args(node)
    end

    def on_nil(_)
      mnil
    end

    def on_self(_)
      ms :Self
    end

    def on_arg(node)
      name, _ = *node
      if name.is_a? Parser::AST::Node
        process name
      else
        ms :VariablePattern, name
      end
    end

    def on_for(node)
      variable, list, block = *node

      pattern = ms(:VariablePattern, variable.children.first)
      ms(:For, [ms(:Generator, pattern, process(list))], process(block) || none)
    end

    def on_optarg(node)
      ms :OtherPattern, node.to_s, nil
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

    def on_casgn(node)
      _ns, id, value = *node
      ms :Assignment, id, process(value)
    end

    def on_op_asgn(node)
      assignee, message, value = *node

      if assignee.type == :send
        property_assignment assignee, message, value
      else
        var_assignment assignee, message, value
      end
    end

    def var_assignment(assignee, message, value)
      id = assignee.to_a.first
      ms :Assignment, id, ms(:Send, ms(:Reference, id), message_reference(message), [process(value)])
    end

    def property_assignment(assignee, message, value)
      receiver, accessor, *accessor_args = *assignee

      reasign accessor, process_all(accessor_args), process(receiver), message, process(value)
    end

    def reasign(accessor, args, id, message, value)
      simple_send id,
                  "#{accessor}=".to_sym,
                  args + [ms(:Send,
                            simple_send(id, accessor, args),
                            message_reference(message),
                            [value])]
    end

    def on_or_asgn(node)
      assignee, value = *node
      on_op_asgn s :op_asgn, assignee, '||', value
    end

    def on_and_asgn(node)
      assignee, value = *node
      on_op_asgn s :op_asgn, assignee, '&&', value
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
      ms :Other, args.to_s, nil
    end

    def handle_send_with_args(node, extra_args=[])
      receptor, message, *args = *node
      receptor ||= s(:self)

      ms :Send, process(receptor), message_reference(message), (process_all(args) + extra_args)
    end

    def message_reference(message)
      case message
        when :==     then primitive :Equal
        when :!=     then primitive :NotEqual
        when :!      then primitive :Negation
        when :'&&'   then primitive :And
        when :'||'   then primitive :Or
        when :hash   then primitive :Hash
        when :>=     then primitive :GreatherOrEqualThan
        when :>      then primitive :GreatherThan
        when :<=     then primitive :LessOrEqualThan
        when :<      then primitive :LessThan
        when :+      then primitive :Plus
        when :-      then primitive :Minus
        when :*      then primitive :Multiply
        when :/      then primitive :Divide
        when :length then primitive :Size
        when :size   then primitive :Size
        else ms :Reference, message
      end
    end

  end
end
