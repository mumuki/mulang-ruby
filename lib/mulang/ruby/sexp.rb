module Mulang::Ruby
  module Sexp
    def sequence(*contents)
      if contents.empty?
        ms(:MuNull)
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

    def mu_method(tag, args, body)
      {
        tag: tag,
        contents: [
          [ args, {tag: :UnguardedBody, contents: body }]
        ]
      }
    end

    def simple_send(sender, message, args)
      ms(:Send, sender, {tag: :Reference, contents: message}, args)
    end
  end
end
