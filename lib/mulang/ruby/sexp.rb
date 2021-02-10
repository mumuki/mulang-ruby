require "mulang"

module Mulang::Ruby
  module Sexp
    include Mulang::Sexp

    def mnil
      ms(:MuNil)
    end
  end

end
