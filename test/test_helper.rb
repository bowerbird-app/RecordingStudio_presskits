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
    had_singleton = singleton.method_defined?(name, false) || singleton.private_method_defined?(name, false)
    original = begin
      method(name)
    rescue NameError
      nil
    end

    define_singleton_method(name) do |*args, **kwargs, &block|
      if val.respond_to?(:call)
        val.call(*args, **kwargs, &block)
      else
        val
      end
    end

    yield
  ensure
    if singleton.method_defined?(name, false) || singleton.private_method_defined?(name, false)
      singleton.remove_method(name)
    end
    define_singleton_method(name, original) if had_singleton && original
  end
end

Object.include(PresskitsMinitestStub) unless Object.method_defined?(:stub)
