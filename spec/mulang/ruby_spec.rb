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
                                  Mulang::Ruby.simple_method(:canta!, [], {
                                    tag: :Send,
                                    contents: [
                                      {tag: :Self},
                                      {tag: :Reference, contents: :puts},
                                      [{tag: :MuString, contents: 'pri'},
                                       {tag: :MuString, contents: 'pri'}]
                                    ]
                                  })
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
                                      {
                                        tag: :Send,
                                        contents: [
                                          {tag: :Self},
                                          {tag: :Reference, contents: :puts},
                                          [{tag: :MuString, contents: 'vuelo'}]
                                        ]
                                      },
                                      {
                                        tag: :Send,
                                        contents: [
                                          {tag: :Self},
                                          {tag: :Reference, contents: :puts},
                                          [{tag: :MuString, contents: 'luego existo'}]
                                        ]
                                      }
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
  end
end
