module Mulang::Ruby
  def self.param(name)
    { tag: :VariablePattern, contents: name }
  end

  def self.simple_method(name, args, body)
    { tag: :Method,
      contents: [
        name,
        [
          [ args, {:tag=>:UnguardedBody, :contents => body }]]
        ]
    }
  end

  class AstProcessor < AST::Processor
    include AST::Sexp

    def on_module(node)
      name, body = *node
      body ||= s(:nil)

      _, object_id = *name

      {tag: :Object, contents: [ object_id, process(body) ]}
    end

    def on_begin(node)
      { tag: :Sequence, contents: process_all(node) }
    end

    def on_defs(node)
      target, id, args, body = *node
      body ||= s(:nil)

      Mulang::Ruby.simple_method id, process_all(args), process(body)
    end

    def on_send(node)
      receptor, message, *args = *node
      receptor ||= s(:self)

      { tag: :Send,
        contents: [
          process(receptor),
          {tag: :Reference, contents: message},
          process_all(args)
        ]}
    end

    def on_nil(_)
      {tag: :MuNull}
    end

    def on_self(_)
      {tag: :Self}
    end

    def on_arg(node)
      name, _ = *node
      Mulang::Ruby.param name
    end

    def on_restarg(node)
      name, _ = *node
      Mulang::Ruby.param name
    end

    def on_str(node)
      value, _ = *node
      { tag: :MuString,
        contents: value }
    end
  end
end