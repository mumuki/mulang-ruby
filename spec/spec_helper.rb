require "bundler/setup"
require "mulang/ruby"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def check_valid(mulang_ast)
  input = {
    sample: { tag: "MulangSample", ast: mulang_ast },
    spec: {
      smellsSet: { tag: "NoSmells" },
      expectations: [],
      signatureAnalysisType: { tag: "NoSignatures" },
    }
  }.to_json
  out = JSON.pretty_parse %x{mulang '#{input}' 2>&1}
  expect(out['tag']).to eq 'AnalysisCompleted'
end

