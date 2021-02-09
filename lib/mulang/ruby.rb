require 'ast'
require 'mumukit/core'
require 'parser/ruby26'
require_relative "./ruby/version"

module Mulang
  module Ruby
    def self.parse(ruby_code, parser_class: nil)
      parser_class ||= default_ruby_parser_class
      Mulang::Ruby::AstProcessor.new.process Mulang::Ruby::SexpParser.parser(ruby_code, parser_class)
    end

    def self.language(parser_class: nil)
      Mulang::Language::External.new("Ruby") { |it| parse(it, parser_class) }
    end

    private

    def self.default_ruby_parser_class
      Parser::Ruby26
    end
  end
end

require_relative "./ruby/sexp"
require_relative './ruby/sexp_parser'
require_relative './ruby/ast_processor'
