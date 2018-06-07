# frozen_string_literal: true

begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"

  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "activerecord", path: "."
  gem "activesupport", path: "../activesupport"
  gem "activemodel", path: "../activemodel"
  gem 'benchmark-ips'
  gem 'pg'
  gem 'mysql2'
  gem 'sqlite3'
  gem 'memory_profiler'
end

require "active_record"

class Monkey < ActiveRecord::Base
end

SCENARIOS = {
  "MySQL"            => {adapter: 'mysql2', username: "root", database: 'bench'},
  "PostreSQL"           => {adapter: 'postgresql', database: 'bench'},
  "SQLite"          => {adapter: 'sqlite3', database: 'bench.sqlite3'},
}

SCENARIOS.each_pair do |name, value|
  puts
  puts " #{name} ".center(80, "=")
  puts

  ActiveRecord::Base.establish_connection(value)

  Monkey.connection.create_table :monkeys, force: true do |t|
  end

  5000.times{ Monkey.create }

  Benchmark.ips do |x|
    x.report("pluck")      { Monkey.all.pluck(:id) }
    x.report("pluck!")     { Monkey.all.pluck!(:id)  }
    x.compare!
  end

  puts " PLUCK ".center(80, "=")

  MemoryProfiler.report do
    Monkey.all.pluck(:id)
  end.pretty_print(detailed_report: false, allocated_strings: 0, retained_strings: 0)

  puts " PLUCK! ".center(80, "=")

  MemoryProfiler.report do
    Monkey.all.pluck!(:id)
  end.pretty_print(detailed_report: false, allocated_strings: 0, retained_strings: 0)
end
