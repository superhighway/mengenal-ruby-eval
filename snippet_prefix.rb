require 'set'
require 'active_support'
require 'active_support/all'
require 'markaby'

def load_fake_root(directory, h, i)
  Dir["#{directory}/*"].each do |f|
    components = f.split('/')

    if File.directory? f
      dirname = components[i]
      h[dirname] = {}
      load_fake_root f, h[dirname], (i+1)
    else
      h[components.last] = File.read f
    end
  end
end

DIRECTORY_MAP = {}
load_fake_root "fake-root", DIRECTORY_MAP, 1

require 'fakefs'

class << IO
  [:sysopen, :for_fd, :popen, :readlines, :read, :binread, :binwrite, :select, :pipe, :try_convert, :copy_stream, :remove_class_variable, :class_variable_get, :class_variable_set, :public_constant, :private_constant, :public_instance_method, :!~, :singleton_class, :untrust, :untrusted?, :trust, :remove_instance_variable, :tap, :public_send, :extend, :display, :method, :public_method, :define_singleton_method, :object_id, :to_enum, :enum_for, :__id__].each { |m| define_method( m) { |*args| undef_method m }}
end

class Object
  remove_const :ENV
end

module Kernel
  [:warn, :trace_var, :untrace_var, :at_exit, :syscall, :open, :gets, :readline, :select, :readlines, :`, :test, :srand, :rand, :trap, :exec, :fork, :exit!, :system, :spawn, :sleep, :exit, :abort, :load, :require, :require_relative, :caller, :caller_locations, :set_trace_func, :!~, :untrust, :untrusted?, :trust, :tap, :display].each { |m| undef_method m }
end

