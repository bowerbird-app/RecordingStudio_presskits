# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "simplecov_helper"
require "minitest/autorun"
require "rails"
require "active_support/time"
Time.zone ||= "UTC"
require "recording_studio_presskits"

# Minitest 6 dropped Object#stub. Keep a tiny replacement for generator/engine tests.
module PresskitsMinitestStub
  def stub(name, val = nil)
    name = name.to_sym
    singleton = singleton_class
    original = PresskitsMinitestStub.copy_if_owned(self, singleton, name)

    define_singleton_method(name) do |*args, **kwargs, &block|
      PresskitsMinitestStub.invoke(val, args, kwargs, block)
    end
    yield
  ensure
    PresskitsMinitestStub.restore(self, singleton, name, original)
  end

  def self.owned?(singleton, name)
    singleton.method_defined?(name, false) || singleton.private_method_defined?(name, false)
  end

  def self.copy_if_owned(object, singleton, name)
    return unless owned?(singleton, name)

    object.method(name)
  rescue NameError
    nil
  end

  def self.invoke(val, args, kwargs, block)
    val.respond_to?(:call) ? val.call(*args, **kwargs, &block) : val
  end

  def self.restore(object, singleton, name, original)
    singleton.remove_method(name) if owned?(singleton, name)
    object.define_singleton_method(name, original) if original
  end
end

Object.include(PresskitsMinitestStub) unless Object.method_defined?(:stub)
