require "mulang"

module Mulang::Ruby
  module Sexp
    include Mulang::Sexp

    def none
      ms(:MuNil)
    end
  end
end
