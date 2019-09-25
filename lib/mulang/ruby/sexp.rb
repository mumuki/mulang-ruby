module Mulang::Ruby
  module Sexp
    def sequence(*contents)
      if contents.empty?
        ms(:MuNil)
      elsif contents.size == 1
        contents[0]
      else
        ms(:Sequence, *contents)
      end
    end

    def ms(tag, *contents)
      if contents.empty?
        {tag: tag}
      elsif contents.size == 1
        {tag: tag, contents: contents.first}
      else
        {tag: tag, contents: contents}
      end
    end

    def simple_method(name, args, body)
      {
        tag: :Method,
        contents: [
          name,
          [
            [ args, {tag: :UnguardedBody, contents: body }]
          ]
        ]
      }
    end

    def mu_primitive_method(type, args, body)
      {
        tag: :PrimitiveMethod,
        contents: [
          type,
          [ args, {tag: :UnguardedBody, contents: body }]
        ]
      }
    end

    def simple_send(sender, message, args)
      ms(:Send, sender, ms(:Reference, message), args)
    end

    def primitive_send(sender, op, args)
      ms(:Send, sender, ms(:Primitive, op), args)
    end
  end
end
