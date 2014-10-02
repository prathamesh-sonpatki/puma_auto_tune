require 'get_process_mem'

module PumaAutoTune; end

require 'puma_auto_tune/version'
require 'puma_auto_tune/master'
require 'puma_auto_tune/worker'
require 'puma_auto_tune/memory'


module PumaAutoTune
  INFINITY    = 1/0.0
  RESOURCES = { ram: PumaAutoTune::Memory.new }

  extend self

  def self.default_ram
    ulimit = `ulimit -u`
    ulimit = if $?.success?
               ulimit.chomp.to_i
             else
               nil
             end

    result = case ulimit
             when 256
               512
             when 512
               1024
             when 32768
               8192
             else
               nil
             end

    default = result || 512

    puts "Default RAM set to #{default}"
    default
  end

  attr_accessor :ram, :max_worker_limit, :frequency, :reap_duration
  self.ram                = self.default_ram  # mb
  self.max_worker_limit   = INFINITY
  self.frequency          = 10 # seconds
  self.reap_duration      = 90 # seconds

  def self.config
    yield self
    self
  end

  def self.hooks(name = nil, resource = nil, &block)
    @hooks       ||= {}
    return @hooks if name.nil?
    resource     ||= RESOURCES[name] || raise("no default resource specified for #{name.inspect}")
    @hooks[name] ||= Hook.new(resource)
    block.call(@hooks[name]) if block
    @hooks[name]
  end

  def start
    hooks.map {|name, hook| hook.auto_cycle }
  end
end


require 'puma_auto_tune/hook'
