module Mulang::Ruby
  module Sexp
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
    { tag: :Method,
      contents: [
        name, [
          [ args, {tag: :UnguardedBody, contents: body }]]
        ]}
    end

    def simple_send(sender, message, args)
      ms(:Send, sender, {tag: :Reference, contents: message}, args)
    end
  end
end
