require 'ast'
require 'parser/ruby26'
require 'mumukit/core'

require_relative "./ruby/version"

module Mulang
  module Ruby
    def self.parse(ruby_code)
      Mulang::Ruby::AstProcessor.new.process Mulang::Ruby::SexpParser.parser(ruby_code)
    end

    def self.language
      Mulang::Language::External.new("Ruby") { |it| parse(it) }
    end
  end
end

require_relative "./ruby/sexp"
require_relative './ruby/sexp_parser'
require_relative './ruby/ast_processor'
