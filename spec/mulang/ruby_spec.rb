require "spec_helper"

describe Mulang::Ruby do
  include Mulang::Sexp

  it "has a version number" do
    expect(Mulang::Ruby::VERSION).not_to be nil
  end

  describe '#parse' do
    let(:result) { Mulang::Ruby.parse code }
    context 'simple module' do
      let(:code) { %q{
        module Pepita
        end
      } }
      it { expect(result).to eq ms :Object, :Pepita, ms(:MuNull) }
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

    context 'ints' do
      let(:code) { %q{60} }
      it { expect(result).to eq ms(:MuNumber, 60) }
    end

    context 'doubles' do
      let(:code) { %q{60.4} }
      it { expect(result).to eq ms(:MuNumber, 60.4) }
      it { check_valid result }
    end

    context 'implicit sends' do
      let(:code) { %q{m 5} }
      it { expect(result).to eq ms :Send, ms(:Self), ms(:Reference, :m), [ms(:MuNumber, 5)] }
      it { check_valid result }
    end

    context 'math expressions' do
      let(:code) { %q{4 + 5} }
      it { expect(result).to eq ms :Send, ms(:MuNumber, 4), ms(:Reference, :+), [ms(:MuNumber, 5)] }
      it { check_valid result }
    end

    context 'equal comparisons' do
      let(:code) { %q{ 4 == 3 } }
      it { expect(result).to eq ms :Send, ms(:MuNumber, 4), {tag: :Equal}, [ms(:MuNumber, 3)] }
      it { check_valid result }
    end

    context 'not equal comparisons' do
      let(:code) { %q{ 4 != 3 } }
      it { expect(result).to eq ms :Send, ms(:MuNumber, 4), {tag: :NotEqual}, [ms(:MuNumber, 3)] }
      it { check_valid result }
    end

    context 'booleans' do
      let(:code) { %q{true} }
      it { expect(result).to eq ms :MuBool, true }
      it { check_valid result }
    end

    context 'lists' do
      let(:code) { %q{[4, 5]} }
      it { expect(result).to eq ms :MuList,  ms(:MuNumber, 4), ms(:MuNumber, 5) }
      it { check_valid result }
    end

    context 'lambdas' do
      let(:code) { %q{[].map { |x, y| 1 }} }
      skip { expect(result).to eq ms :MuList,  ms(:MuNumber, 4), ms(:MuNumber, 5) }
      it { check_valid result }
    end

    context 'message sends' do
      let(:code) { %q{
        a = 2
        a + 6
      } }
      it { expect(result[:contents][1]).to eq simple_send(ms(:Reference, :a), :+, [ms(:MuNumber, 6)]) }
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

    context 'module with module' do
      let(:code) { %q{
        module Pepita
          def self.canta
          end
        end
      } }
      it { expect(result).to eq ms(:Object, :Pepita, simple_method(:canta, [], ms(:MuNull))) }
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
      it { expect(result).to eq tag: :Object,
                                contents: [
                                  :Pepita,
                                  simple_method(
                                    :canta!,
                                    [],
                                    simple_send(
                                      ms(:Self),
                                      :puts,
                                      [{tag: :MuString, contents: 'pri'},
                                       {tag: :MuString, contents: 'pri'}]))
                                ]}
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
                                  simple_method(:vola!, [], {
                                    tag: :Sequence,
                                    contents: [
                                      simple_send(
                                        ms(:Self),
                                        :puts,
                                        [{tag: :MuString, contents: 'vuelo'}]),
                                      simple_send(
                                        ms(:Self),
                                        :puts,
                                        [{tag: :MuString, contents: 'luego existo'}])
                                    ]
                                  })
                                ] }
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
                          ms(:MuNull))) }
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
                                      ms(:MuNull)))) }
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
                                      ms(:MuNull),
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
                                      ms(:MuNull),
                                      simple_send(ms(:Self), :hacelo!, [])))) }
    end

    context 'simple class declararions' do
      let(:code) { %q{
        class Foo
        end
      } }
      it { expect(result).to eq ms(:Class, :Foo, :Object, ms(:MuNull)) }
      it { check_valid result }
    end

    context 'simple class declaration with inheritance' do
      let(:code) { %q{
        class Foo < Bar
        end
      } }
      it { expect(result).to eq ms(:Class, :Foo, :Bar, ms(:MuNull)) }
      it { check_valid result }
    end

    context 'mixins' do
      let(:code) { %q{
        class Foo
          include Bar
        end
      } }
      it { expect(result).to eq tag: :Class,
                                contents: [
                                  :Foo,
                                  :Object,
                                  simple_send(
                                    ms(:Self),
                                    :include,
                                    [ms(:Reference, :Bar)]),
                                  ] }
      it { check_valid result }
    end

    context 'unsupported features' do
      let(:code) { %q{
        class << self
        end
      } }
      it { expect(result).to eq tag: :Other }
      it { check_valid result }
    end
  end
end

