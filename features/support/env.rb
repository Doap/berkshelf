require 'rubygems'
require 'bundler'
require 'spork'
require "json_spec/cucumber"

Spork.prefork do
  require 'rspec'
  require 'pp'
  require 'aruba/cucumber'
  require 'vcr'

  APP_ROOT = File.expand_path('../../../', __FILE__)

  ENV["BERKSHELF_PATH"] = File.join(APP_ROOT, "tmp", "berkshelf")
  ENV["BERKSHELF_CHEF_CONFIG"] = File.join(APP_ROOT, "tmp", "knife.rb")

  Dir[File.join(APP_ROOT, "spec/support/**/*.rb")].each {|f| require f}

  Around do |scenario, block|
    VCR.use_cassette(scenario.title) do
      block.call
    end
  end

  Before do
    clean_cookbook_store
    @aruba_io_wait_seconds = 5
    @aruba_timeout_seconds = 8
  end

  Before('@slow_process') do
    @aruba_timeout_seconds = 60
    @aruba_io_wait_seconds = 10
  end

  def cookbook_store
    Pathname.new(File.join(ENV["BERKSHELF_PATH"],"cookbooks"))
  end

  def clean_cookbook_store
    FileUtils.rm_rf(cookbook_store)
    FileUtils.mkdir_p(cookbook_store)
  end

  def app_root_path
    Pathname.new(APP_ROOT)
  end

  def tmp_path
    app_root_path.join('spec/tmp')
  end

  def fixtures_path
    app_root_path.join('spec/fixtures')
  end

  # Set the output json_spec will parse for testing JSON responses
  def last_json
    all_output
  end
end

Spork.each_run do
  Berkshelf::RSpec::Knife.load_knife_config(File.join(APP_ROOT, 'spec/knife.rb'))

  require 'berkshelf'
end
