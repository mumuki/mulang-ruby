require 'bundler/setup'
require 'mulang/ruby'
require 'mulang'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def check_valid(mulang_ast)
  out = analyse(mulang_ast)
  expect(out['tag']).to eq 'AnalysisCompleted'
end

def check_invalid(mulang_ast)
  out = analyse(mulang_ast)
  expect(out['tag']).to eq 'AnalysisFailed'
end

def analyse(mulang_ast)
  Mulang::Code.new(Mulang::Language::External.new, mulang_ast).analyse({})
end
