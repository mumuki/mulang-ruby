require "spec_helper"

describe Mulang::Ruby do
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
      it { expect(result).to eq tag: :Object,
                                contents: [:Pepita, { tag: :MuNull }] }
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
      it { expect(result).to eq tag: :Assignment,
                                contents: [
                                  :otra_pepita,
                                  {tag: :Reference, contents: :Pepita}]}
      it { check_valid result }
    end

    context 'ints' do
      let(:code) { %q{60} }
      it { expect(result).to eq tag: :MuNumber, contents: 60 }
    end

    context 'doubles' do
      let(:code) { %q{60.4} }
      it { expect(result).to eq tag: :MuNumber, contents: 60.4 }
      it { check_valid result }
    end

    context 'booleans' do
      let(:code) { %q{true} }
      it { expect(result).to eq tag: :MuBool, contents: true }
      it { check_valid result }
    end

    context 'lists' do
      let(:code) { %q{[4, 5]} }
      it { expect(result).to eq tag: :MuList, contents: [
                                                  Mulang::Ruby.number(4),
                                                  Mulang::Ruby.number(5)] }
      it { check_valid result }
    end

    context 'lambdas' do
      let(:code) { %q{[].map { |x, y| 1 }} }
      skip { expect(result).to eq tag: :MuList, contents: [
                                                  Mulang::Ruby.number(4),
                                                  Mulang::Ruby.number(5)] }
      it { check_valid result }
    end

    context 'message sends' do
      let(:code) { %q{
        a = 2
        a + 6
      } }
      it { expect(result[:contents][1]).to eq Mulang::Ruby.simple_send(
                                                {tag: :Reference, contents: :a},
                                                :+,
                                                [{tag: :MuNumber, contents: 6}]) }
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
      it { expect(result).to eq tag: :Object,
                                contents: [
                                  :Pepita,
                                  Mulang::Ruby.simple_method(:canta, [], {tag: :MuNull})
                                ]}
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
                                  Mulang::Ruby.simple_method(
                                    :canta!,
                                    [],
                                    Mulang::Ruby.simple_send(
                                      {tag: :Self},
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
                                  Mulang::Ruby.simple_method(:vola!, [], {
                                    tag: :Sequence,
                                    contents: [
                                      Mulang::Ruby.simple_send(
                                        {tag: :Self},
                                        :puts,
                                        [{tag: :MuString, contents: 'vuelo'}]),
                                      Mulang::Ruby.simple_send(
                                        {tag: :Self},
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
      it { expect(result).to eq tag: :Object,
                                contents: [
                                  :Pepita,
                                  Mulang::Ruby.simple_method(
                                    :come!,
                                    [Mulang::Ruby.param(:cantidad),
                                     Mulang::Ruby.param(:unidad)],
                                    {tag: :MuNull})
                                ]}
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
                                  Mulang::Ruby.simple_method(
                                    :decidi!,
                                    [],
                                    { tag: :If,
                                      contents: [
                                        Mulang::Ruby.simple_send(
                                          {tag: :Self},
                                          :esta_bien?,
                                          []),
                                        Mulang::Ruby.simple_send(
                                          {tag: :Self},
                                          :hacelo!,
                                          []),
                                        Mulang::Ruby.simple_send(
                                          {tag: :Self},
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
      it { expect(result).to eq tag: :Object,
                                contents: [
                                  :Pepita,
                                  Mulang::Ruby.simple_method(
                                    :decidi!,
                                    [],
                                    { tag: :If,
                                      contents: [
                                        Mulang::Ruby.simple_send(
                                          {tag: :Self},
                                          :esta_bien?,
                                          []),
                                        Mulang::Ruby.simple_send(
                                          {tag: :Self},
                                          :hacelo!,
                                          []),
                                        {tag: :MuNull}
                                      ]})
                                ]}
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
      it { expect(result).to eq tag: :Object,
                                contents: [
                                  :Pepita,
                                  Mulang::Ruby.simple_method(
                                    :decidi!,
                                    [],
                                    { tag: :If,
                                      contents: [
                                        Mulang::Ruby.simple_send(
                                          {tag: :Self},
                                          :esta_bien?,
                                          []),
                                        {tag: :MuNull},
                                        Mulang::Ruby.simple_send(
                                          {tag: :Self},
                                          :hacelo!,
                                          [])
                                      ]})
                                ]}
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
      it { expect(result).to eq tag: :Object,
                                contents: [
                                  :Pepita,
                                  Mulang::Ruby.simple_method(
                                    :decidi!,
                                    [],
                                    { tag: :If,
                                      contents: [
                                        Mulang::Ruby.simple_send(
                                          {tag: :Self},
                                          :esta_bien?,
                                          []),
                                        {tag: :MuNull},
                                        Mulang::Ruby.simple_send(
                                          {tag: :Self},
                                          :hacelo!,
                                          [])
                                      ]})
                                ]}
    end
    context 'unsupported features' do
      let(:code) { %q{
        class Foo
          include Bar
        end
      } }
      it { expect(result).to eq tag: :Other }
      it { check_valid result }
    end
  end
end

