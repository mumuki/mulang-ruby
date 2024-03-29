require "spec_helper"
require 'parser/ruby24'

def try(catches, finally)
  simple_method(:foo, [],
    ms(:Try,
      simple_send(
        ms(:Self),
        :bar,
        []), catches, finally))
end

describe Mulang::Ruby do
  include Mulang::Ruby::Sexp

  it "has a version number" do
    expect(Mulang::Ruby::VERSION).not_to be nil
  end

  describe '#language' do
    it { expect(Mulang::Ruby.language.ast "4").to eq ms(:MuNumber, 4) }
    it { expect(Mulang::Ruby.language.name).to eq 'Ruby' }
    it { expect(Mulang::Ruby.language.core_name).to eq 'Ruby' }
  end

  describe '#parse' do
    let(:result) { Mulang::Ruby.language.ast code }

    context 'syntax errors' do
      let(:code) { %q{@!syntax error} }
      it { check_invalid result }
    end

    context 'simple module' do
      let(:code) { %q{
        module Pepita
        end
      } }
      it { expect(result).to eq ms :Object, :Pepita, none }
      it { check_valid result }
    end

    context 'modules and variables' do
      let(:code) { %q{
        module Pepita
        end
        module Pepona
        end
        otra_pepita = Pepita
        otra_pepona = Pepona
      } }
      it { expect(result[:tag]).to eq :Sequence }
      it { expect(result[:contents].length).to eq 4 }
    end

    context 'variables' do
      let(:code) { %q{
        otra_pepita = Pepita
      } }
      it { expect(result).to eq ms :Assignment, :otra_pepita, ms(:Reference, :Pepita )}
      it { check_valid result }
    end

    context 'instance variables references' do
      let(:code) { %q{@nigiri} }
      it { expect(result).to eq ms :Reference, :@nigiri }
      it { check_valid result }
    end

    context 'instance variables assignment' do
      let(:code) { %q{@wasabi = true} }
      it { expect(result).to eq ms :Assignment, :@wasabi, ms(:MuBool, true) }
      it { check_valid result }
    end

    context 'returns' do
      let(:code) { %q{return 9} }
      it { expect(result).to eq ms(:Return, ms(:MuNumber, 9)) }
      it { check_valid result }
    end

    context 'or boolean expressions' do
      let(:code) { %q{true || true} }
      it { expect(result).to eq simple_send(ms(:MuBool, true), '||', [ms(:MuBool, true)]) }
      it { check_valid result }
    end

    context '&& boolean expressions' do
      let(:code) { %q{true && true} }
      it { expect(result).to eq simple_send(ms(:MuBool, true), '&&', [ms(:MuBool, true)]) }
    end

    context '|| boolean expressions' do
      let(:code) { %q{true or true} }
      it { expect(result).to eq simple_send(ms(:MuBool, true), '||', [ms(:MuBool, true)]) }
    end

    context 'ints' do
      let(:code) { %q{60} }
      it { expect(result).to eq ms(:MuNumber, 60) }
    end

    context 'symbols' do
      let(:code) { %q{:foo} }
      it { expect(result).to eq ms(:MuSymbol, 'foo') }
      it { check_valid result }
    end

   context 'interpolations' do
      let(:code) { %q{"foo #{@bar} - #{@baz}"} }
      it { expect(result).to eq simple_send(ms(:MuList,
                                    ms(:MuString, "foo "),
                                    ms(:Reference, :@bar),
                                    ms(:MuString, " - "),
                                    ms(:Reference, :@baz)), :join, []) }
      it { check_valid result }
    end

    context 'regexps' do
      let(:code) { %q{/foo.*/} }
      it { expect(result).to eq simple_send(ms(:Reference, :Regexp), :new, [ms(:MuString, 'foo.*')]) }
      it { check_valid result }
    end

    context 'doubles' do
      let(:code) { %q{60.4} }
      it { expect(result).to eq ms(:MuNumber, 60.4) }
      it { check_valid result }
    end

    context '> comparison operator' do
      let(:code) { %q{4 > 5} }
      it { expect(result).to eq ms :Send, ms(:MuNumber, 4), ms(:Primitive, :GreaterThan), [ms(:MuNumber, 5)] }
      it { check_valid result }
    end

    context '>= comparison operator' do
      let(:code) { %q{4 >= 5} }
      it { expect(result).to eq ms :Send, ms(:MuNumber, 4), ms(:Primitive, :GreaterOrEqualThan), [ms(:MuNumber, 5)] }
      it { check_valid result }
    end

    context 'implicit sends' do
      let(:code) { %q{m 5} }
      it { expect(result).to eq ms :Send, ms(:Self), ms(:Reference, :m), [ms(:MuNumber, 5)] }
      it { check_valid result }
    end

    context 'math expressions' do
      let(:code) { %q{4 + 5} }
      it { expect(result).to eq ms :Send, ms(:MuNumber, 4), ms(:Primitive, :Plus), [ms(:MuNumber, 5)] }
      it { check_valid result }
    end

    context 'equal comparisons' do
      let(:code) { %q{ 4 == 3 } }
      it { expect(result).to eq ms :Send, ms(:MuNumber, 4), ms(:Primitive, :Equal), [ms(:MuNumber, 3)] }
      it { check_valid result }
    end

    context 'not equal comparisons' do
      let(:code) { %q{ 4 != 3 } }
      it { expect(result).to eq ms :Send, ms(:MuNumber, 4), ms(:Primitive, :NotEqual), [ms(:MuNumber, 3)] }
      it { check_valid result }
    end

    context 'true' do
      let(:code) { %q{true} }
      it { expect(result).to eq ms :MuBool, true }
      it { check_valid result }
    end

    context 'false' do
      let(:code) { %q{false} }
      it { expect(result).to eq ms :MuBool, false }
      it { check_valid result }
    end

     context 'nil' do
      let(:code) { %q{nil} }
      it { expect(result).to eq mnil }
      it { check_valid result }
    end

    context 'lists' do
      let(:code) { %q{[4, 5]} }
      it { expect(result).to eq ms :MuList,  ms(:MuNumber, 4), ms(:MuNumber, 5) }
      it { check_valid result }
    end

    context 'empty lists' do
      let(:code) { %q{[]} }
      it { expect(result).to eq tag: :MuList, contents: [] }
      it { check_valid result }
    end

    describe 'lambdas' do
      let(:list) { ms :MuList,  ms(:MuNumber, 4), ms(:MuNumber, 5) }
      context 'map' do
        let(:code) { %q{[4, 5].map { |x| x + 1 }} }
        it { expect(result).to eq simple_send list, :map, [
                                    ms(:Lambda,
                                      [ms(:VariablePattern, :x)],
                                      primitive_send(ms(:Reference, :x), :Plus, [ms(:MuNumber, 1)]))] }
        it { check_valid result }
      end

      context 'inject' do
        let(:code) { %q{[4, 5].inject(0) { |x, y| x + y }} }
        it { expect(result).to eq simple_send list, :inject, [
                                    ms(:MuNumber, 0),
                                    ms(:Lambda,
                                      [ms(:VariablePattern, :x), ms(:VariablePattern, :y)],
                                      primitive_send(ms(:Reference, :x), :Plus, [ms(:Reference, :y)]))] }
        it { check_valid result }
      end
    end

    context 'message sends' do
      let(:code) { %q{
        a = 2
        a + 6
      } }
      it { expect(result[:contents][1]).to eq primitive_send(ms(:Reference, :a), :Plus, [ms(:MuNumber, 6)]) }
      it { check_valid result }
    end

    context 'modules and variables' do
      let(:code) { %q{
        module Pepita
        end
        module Pepona
        end
        otra_pepita = Pepita
        otra_pepona = Pepona
      } }
      it { expect(result[:tag]).to eq :Sequence }
      it { check_valid result }
    end

    context 'module with empty method' do
      let(:code) { %q{
        module Pepita
          def self.canta
          end
        end
      } }
      it { expect(result).to eq ms(:Object, :Pepita, simple_method(:canta, [], none)) }
      it { check_valid result }
    end

    context 'module with self methods' do
      let(:code) { %q{
        module Pepita
          def self.canta!
            puts 'pri', 'pri'
          end
        end
      } }
      it { expect(result).to eq ms :Object, :Pepita, simple_method(:canta!, [],
                                                    simple_send(ms(:Self), :puts, [ms(:MuString, 'pri'), ms(:MuString, 'pri')])) }

      it { check_valid result }
    end

    context 'module with multiline self methods' do
      let(:code) { %q{
        module Pepita
          def self.vola!
            puts 'vuelo'
            puts 'luego existo'
          end
        end
      } }
      it { expect(result).to eq tag: :Object,
                                contents: [
                                  :Pepita,
                                  simple_method(:vola!, [], sequence(
                                      simple_send(ms(:Self), :puts, [{tag: :MuString, contents: 'vuelo'}]),
                                      simple_send(ms(:Self), :puts, [{tag: :MuString, contents: 'luego existo'}]))) ] }
      it { check_valid result }
    end

    context 'module with methods with many arguments' do
      let(:code) { %q{
        module Pepita
          def self.come!(cantidad, *unidad)
          end
        end
      } }
      it { expect(result)
            .to eq ms(:Object,
                        :Pepita,
                        simple_method(
                          :come!,
                          [ms(:VariablePattern, :cantidad), ms(:VariablePattern, :unidad)],
                          none)) }
      it { check_valid result }
    end

    context 'constant assignment' do
      let(:code) { %q{Pepita = Object.new} }
      it { expect(result).to eq ms(:Assignment, :Pepita, simple_send(ms(:Reference, :Object), :new, [])) }
      it { check_valid result }
    end



    context 'module with if-else' do
      let(:code) { %q{
        module Pepita
          def self.decidi!
            if esta_bien?
              hacelo!
            else
              no_lo_hagas!
            end
          end
        end
      } }
      it { expect(result).to eq tag: :Object,
                                contents: [
                                  :Pepita,
                                  simple_method(
                                    :decidi!,
                                    [],
                                    { tag: :If,
                                      contents: [
                                        simple_send(
                                          ms(:Self),
                                          :esta_bien?,
                                          []),
                                        simple_send(
                                          ms(:Self),
                                          :hacelo!,
                                          []),
                                        simple_send(
                                          ms(:Self),
                                          :no_lo_hagas!,
                                          [])
                                      ]})
                                ]}
      it { check_valid result }
    end

    context 'module with if' do
      let(:code) { %q{
        module Pepita
          def self.decidi!
            if esta_bien?
              hacelo!
            end
          end
        end
      } }
      it { expect(result).to eq ms(:Object,
                                  :Pepita,
                                  simple_method(:decidi!, [],
                                    ms(:If,
                                      simple_send(ms(:Self), :esta_bien?, []),
                                      simple_send(ms(:Self), :hacelo!, []),
                                      none))) }
      it { check_valid result }
    end

    context 'module with unless' do
      let(:code) { %q{
        module Pepita
          def self.decidi!
            unless esta_bien?
              hacelo!
            end
          end
        end
      } }
      it { expect(result).to eq ms(:Object,
                                  :Pepita,
                                  simple_method(:decidi!, [],
                                    ms(:If,
                                      simple_send(ms(:Self), :esta_bien?, []),
                                      none,
                                      simple_send(ms(:Self),:hacelo!, [])))) }
      it { check_valid result }
    end

    context 'module with suffix unless' do
      let(:code) { %q{
        module Pepita
          def self.decidi!
            hacelo! unless esta_bien?
          end
        end
      } }
      it { expect(result).to eq ms(:Object,
                                  :Pepita,
                                  simple_method(:decidi!, [],
                                    ms(:If,
                                      simple_send(ms(:Self), :esta_bien?, []),
                                      none,
                                      simple_send(ms(:Self), :hacelo!, [])))) }
    end

    context 'simple class declararions' do
      let(:code) { %q{
        class Foo
        end
      } }
      it { expect(result).to eq ms(:Class, :Foo, nil, none) }
      it { check_valid result }
    end

    context 'simple class declaration with inheritance' do
      let(:code) { %q{
        class Foo < Bar
        end
      } }
      it { expect(result).to eq ms(:Class, :Foo, :Bar, none) }
      it { check_valid result }
    end

    context 'simple inline class with method' do
      let(:code) { %q{
        class Pepita; def canta; end; end
      } }
      it { expect(result).to eq ms(:Class, :Pepita, nil, simple_method(:canta, [], none)) }
      it { check_valid result }
    end

    context 'simple inline class with self method' do
      let(:code) { %q{
        class Pepita; def self.canta; end; end
      } }
      it { expect(result).to eq ms(:Class, :Pepita, nil, ms(:Decorator, [ms(:Classy)], simple_method(:canta, [], none))) }
      it { check_valid result }
    end

    context 'simple eigen method' do
      let(:code) { %q{
        def Pepita.canta; end
      } }
      it { expect(result).to eq ms(:EigenClass, ms(:Reference, :Pepita), simple_method(:canta, [], none)) }
      it { check_valid result }
    end

    context 'simple eigen class' do
      let(:code) { %q{
        class << Pepita
          def canta; end
        end
      } }
      it { expect(result).to eq ms(:EigenClass, ms(:Reference, :Pepita), simple_method(:canta, [], none)) }
      it { check_valid result }
    end

    context 'simple class with methods and parameters' do
      let(:code) { %q{
        class Pepita
          def canta!(cancion)
            puts cancion
          end
          def vola!(distancia)
          end
        end
      } }
      it { expect(result).to eq ms(:Class, :Pepita, nil,
                                  sequence(
                                    simple_method(:canta!, [ms(:VariablePattern, :cancion)], simple_send(ms(:Self), :puts, [ms(:Reference, :cancion)])),
                                    simple_method(:vola!, [ms(:VariablePattern, :distancia)], none))) }
      it { check_valid result }
    end

    context 'simple class with mixed instance and class methods' do
      let(:code) { %q{
        class Pepita
          def self.nueva
          end
          def vola!
          end
        end
      } }
      it { expect(result).to eq ms(:Class, :Pepita, nil,
                                  sequence(
                                    ms(:Decorator, [ms(:Classy)], simple_method(:nueva, [], none)),
                                    simple_method(:vola!, [], none))) }
      it { check_valid result }
    end

    context 'nested modules and classes' do
      let(:code) { %q{
        module Birds
          class Pepita
            def self.nueva
            end
            def vola!
            end
          end

          def self.nuevo; end
        end
      } }
      it { expect(result).to eq ms(:Object, :Birds,
                                    sequence(
                                      ms(:Class, :Pepita, nil,
                                        sequence(
                                          ms(:Decorator, [ms(:Classy)], simple_method(:nueva, [], none)),
                                          simple_method(:vola!, [], none))),
                                      simple_method(:nuevo, [], none))) }
      it { check_valid result }
    end

    context 'mixins' do
      let(:code) { %q{
        class Foo
          include Bar
        end
      } }
      it { expect(result).to eq ms :Class, :Foo, nil, simple_send(ms(:Self), :include, [ms(:Reference, :Bar)]) }
      it { check_valid result }
    end

    context 'hashes' do
      let(:code) { %q{{foo:3}} }
      it { expect(result).to eq ms :Other, "[s(:hash,\n  s(:pair,\n    s(:sym, :foo),\n    s(:int, 3)))]", nil }
      it { check_valid result }
    end

    context 'creation' do
      let(:code) { %q{Object.new} }
      it { expect(result).to eq simple_send(ms(:Reference, :Object), :new, []) }
      it { check_valid result }
    end

    context 'ranges' do
      let(:code) { %q{1..1024} }
      it { expect(result).to eq ms :Other, "(irange\n  (int 1)\n  (int 1024))", nil }
      it { check_valid result }
    end

    context 'ranges with parenthesis and blocks' do
      let(:code) { %q{l = (1..1024*1024*10).map { Object.new }} }
      it { check_valid result }
    end

    context 'hash def' do
      let(:code) { %q{def hash;end} }
      it { expect(result).to eq primitive_method :Hash, [], none }
    end

    context 'equal? def' do
      let(:code) { %q{def equal?;end} }
      it { expect(result).to eq primitive_method :Equal, [], none }
    end

    context 'eql? def' do
      let(:code) { %q{def equal?;end} }
      it { expect(result).to eq primitive_method :Equal, [], none }
    end

    context '== def' do
      let(:code) { %q{def equal?;end} }
      it { expect(result).to eq primitive_method :Equal, [], none }
    end

    context 'rescue with no action' do
      let(:code) { %q{
        def foo
          bar
        rescue
        end
      } }
      it { check_valid result }
      it { expect(result).to eq try([ [ ms(:WildcardPattern),
                                        none] ],
                                    none) }
    end

    context 'rescue with action' do
      let(:code) { %q{
        def foo
          bar
        rescue
          baz
        end
      } }
      it { check_valid result }
      it { expect(result).to eq try([ [ ms(:WildcardPattern),
                                        simple_send(ms(:Self), :baz, []) ] ],
                                    none) }
    end

    context 'rescue with exception type' do
      let(:code) { %q{
        def foo
          bar
        rescue RuntimeError
          baz
        end
      } }

      it { check_valid result }
      it { expect(result).to eq try([ [ ms(:TypePattern, :RuntimeError),
                                        simple_send(ms(:Self), :baz, []) ] ],
                                    none ) }
    end

    context 'rescue with multiple exception types' do
      let(:code) { %q{
        def foo
          bar
        rescue RuntimeError, TypeError
          baz
        end
      } }

      it { check_valid result }
      it { expect(result).to eq try([ [ ms(:UnionPattern, [
                                          ms(:TypePattern, :RuntimeError),
                                          ms(:TypePattern, :TypeError) ]),
                                        simple_send(ms(:Self), :baz, []) ] ],
                                    none) }
    end

    context 'rescue with exception variable' do
      let(:code) { %q{
        def foo
          bar
        rescue => e
          baz
        end
      } }

      it { check_valid result }
      it { expect(result).to eq try([ [ ms(:VariablePattern, :e),
                                        simple_send(ms(:Self), :baz, []) ] ],
                                    none) }
    end

    context 'rescue exception with both type and variable' do
      let(:code) { %q{
        def foo
          bar
        rescue RuntimeError => e
          baz
        end
      } }

      it { check_valid result }
      it { expect(result).to eq try([ [ ms(:AsPattern, :e, ms(:TypePattern, :RuntimeError)),
                                        simple_send(ms(:Self), :baz, []) ] ],
                                    none) }
    end

    context 'rescue exception with multiple catches' do
      let(:code) { %q{
        def foo
          bar
        rescue RuntimeError => e
          baz
        rescue RangeError => e
          foobar
        end
      } }

      it { check_valid result }
      it { expect(result).to eq try([ [ ms(:AsPattern, :e, ms(:TypePattern, :RuntimeError)),
                                        simple_send(ms(:Self), :baz, []) ],
                                      [ ms(:AsPattern, :e, ms(:TypePattern, :RangeError)),
                                        simple_send(ms(:Self), :foobar, []) ] ],
                                    none) }
    end

    context 'rescue with begin keyword' do
      let(:code) { %q{
        def foo
          begin
            bar
          rescue
            baz
          end
        end
      } }

      it { check_valid result }
      it { expect(result).to eq try([ [ ms(:WildcardPattern),
                                        simple_send(ms(:Self), :baz, []) ] ],
                                    none) }
    end

    context 'rescue with ensure' do
      let(:code) { %q{
        def foo
          bar
        rescue
          baz
        ensure
          foobar
        end
      } }

      it { check_valid result }
      it { expect(result).to eq try([ [ ms(:WildcardPattern),
                                        simple_send(ms(:Self), :baz, []) ] ],
                                    simple_send(ms(:Self), :foobar, [])) }
    end

    context 'op assignment -' do
      let(:code) { 'a -= 3' }

      it { check_valid result }
      it { expect(result).to eq(Mulang::Ruby.parse 'a = a - 3')}
    end

    context 'op assignment on local array var' do
      let(:code) { 'a[1] += 3' }

      it { check_valid result }
      it { expect(result).to eq(Mulang::Ruby.parse('a[1] = a[1] + 3'))}
    end

    context 'op assignment on instance array var' do
      let(:code) { '@a[1] *= 3' }

      it { check_valid result }
      it { expect(result).to eq(Mulang::Ruby.parse('@a[1] = @a[1] * 3'))}
    end

    context 'op assignment on local var with attribute accessor' do
      let(:code) { 'a.b /= 3' }

      it { check_valid result }
      it { expect(result).to eq(Mulang::Ruby.parse('a.b = a.b / 3'))}
    end

    context 'op assignment on instance var with attribute accessor' do
      let(:code) { '@a.b ||= false' }

      it { check_valid result }
      it { expect(result).to eq(Mulang::Ruby.parse('@a.b = @a.b || false'))}
    end

    context 'and assignment' do
      let(:code) { 'a &&= false' }

      it { check_valid result }
      it { expect(result).to eq(Mulang::Ruby.parse('a = a && false'))}
    end

    context 'it does not break on parameters with default value' do
      let(:code) { 'def foo(a = 123); end' }

      it { check_valid result }
      it { expect(result).to eq(simple_method(:foo, [ms(:OtherPattern, "(optarg :a\n  (int 123))", nil)], none))}
    end

    context 'it does not break on empty blocks' do
      let(:code) { '[].map {}' }

      it { check_valid result }
      it { expect(result).to eq(simple_send(ms(:MuList, []), :map, [ms(:Lambda, [], none)]))}
    end

    context 'it parses empty for' do
      let(:code) { 'for number in [1,2,3]; end' }

      it { check_valid result }
      it { expect(result).to eq(ms(:For, [ms(:Generator, ms(:VariablePattern, :number), ms(:MuList, ms(:MuNumber, 1), ms(:MuNumber, 2), ms(:MuNumber, 3)))], none))}
    end

    context 'it parses for with code' do
      let(:code) { 'for number in [1,2,3]; foo; end' }

      it { check_valid result }
      it { expect(result).to eq(ms(:For, [ms(:Generator, ms(:VariablePattern, :number), ms(:MuList, ms(:MuNumber, 1), ms(:MuNumber, 2), ms(:MuNumber, 3)))], simple_send(ms(:Self), :foo, [])))}
    end

    context 'it parses for with more code' do
      let(:code) { 'for number in [1,2,3]; foo; bar; end' }

      it { check_valid result }
      it { expect(result).to eq(ms(:For, [ms(:Generator, ms(:VariablePattern, :number), ms(:MuList, ms(:MuNumber, 1), ms(:MuNumber, 2), ms(:MuNumber, 3)))], ms(:Sequence, [simple_send(ms(:Self), :foo, []), simple_send(ms(:Self), :bar, [])])))}
    end

    context 'parses ill-formed code' do
      let(:code) { "def y" }

      it { check_invalid result }
    end

    context 'parses `else without rescue is useless` scenario' do
      let(:code) {
        %q{
          def y
          else
          end
        }
      }

      context 'ruby 2.4' do
        let(:result) { Mulang::Ruby.parse code, parser_class: Parser::Ruby24 }

        it { check_valid result }
        it { expect(result).to eq simple_method(:y, [], none) }
      end

      context 'default ruby' do
        it { check_invalid result }
        it { expect(result).to be nil }
      end
    end

    context 'parses parenthesis in args' do
      let(:code) { "foo { |(x)| }" }

      it { check_valid result }
      it { expect(result).to eq :tag=>:Send,
                                :contents=>
                                [{:tag=>:Self},
                                  {:tag=>:Reference, :contents=>:foo},
                                  [{:tag=>:Lambda, :contents=>[[{:tag=>:VariablePattern, :contents=>:x}], none]}]] }
    end
  end
end
