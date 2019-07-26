# .irbrc
# vim: set syntax=ruby foldmethod=marker :
require 'irb/completion'
#require 'irb/ext/save-history'
require 'fileutils'
require 'pp'

# 1000 entries in the list
IRB.conf[:SAVE_HISTORY] = 1000

  #ap
%w[
  rubygems
  awesome_print
  interactive_editor
].each do |gem|
  begin
    require gem
  rescue LoadError
  end
end


ARGV.concat [ "--readline",
  "--prompt-mode",
  "simple" ]

# Store results in home directory with specified file name
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb-history"
IRB.conf[:PROMPT_MODE] = :SIMPLE

# Copy/Paste stuff for OS X {{{1
def copy(str)
  IO.popen('pbcopy', 'w') { |f| f << str.to_s }
end

def copy_history
  history = Readline::HISTORY.entries
  index = history.rindex("exit") || -1
  content = history[(index+1)..-2].join("\n")
  puts content
  copy content
end

def paste
  `pbpaste`
end

# This extension adds a UNIX-style pipe to strings {{{1
#
# Synopsis:
#
# >> puts "UtilityBelt is better than alfalfa" | "cowsay"
#  ____________________________________
# < UtilityBelt is better than alfalfa >
#  ------------------------------------
#         \   ^__^
#          \  (oo)\_______
#             (__)\       )\/\
#                 ||----w |
#                 ||     ||
# => nil
class String
  def |(cmd)
    IO.popen(cmd.to_s, 'r+') do |pipe|
      pipe.write(self)
      pipe.close_write
      pipe.read
    end
  end
end

# return if "universal-darwin10.0" == RUBY_PLATFORM


MACRUBY = false
if ! MACRUBY # macruby has trouble w/ this
  require 'irb/completion'
  module IRB  # now you can type: IRB.quiet or IRB.verbose from within irb
    def self.output_value
      ap @context.last_value
    end

    def self.result_format 
      conf[:PROMPT][conf[:PROMPT_MODE]][:RETURN] 
    end 
    def self.result_format=(str) 
      result_format.replace(str) 
    end 
    def self.verbose 
      self.result_format = "=> %s\n" 
    end 
    def self.quiet 
      self.result_format = '' 
    end 
  end 

  # Load your rails specific stuff (.railsrc)
  script_console_running = ENV.include?('RAILS_ENV') && IRB.conf[:LOAD_MODULES] && IRB.conf[:LOAD_MODULES].include?('console_with_helpers')
  rails_running = ENV.include?('RAILS_ENV') && !(IRB.conf[:LOAD_MODULES] && IRB.conf[:LOAD_MODULES].include?('console_with_helpers'))
  irb_standalone_running = !script_console_running && !rails_running
end

unless self.class.const_defined? "IRB_RC_HAS_LOADED"

  begin # ANSI codes
    ANSI_BLACK    = "\033[0;30m"
    ANSI_GRAY     = "\033[1;30m"
    ANSI_LGRAY    = "\033[0;37m"
    ANSI_WHITE    =  "\033[1;37m"
    ANSI_RED      ="\033[0;31m"
    ANSI_LRED     = "\033[1;31m"
    ANSI_GREEN    = "\033[0;32m"
    ANSI_LGREEN   = "\033[1;32m"
    ANSI_BROWN    = "\033[0;33m"
    ANSI_YELLOW   = "\033[1;33m"
    ANSI_BLUE     = "\033[0;34m"
    ANSI_LBLUE    = "\033[1;34m"
    ANSI_PURPLE   = "\033[0;35m"
    ANSI_LPURPLE  = "\033[1;35m"
    ANSI_CYAN     = "\033[0;36m"
    ANSI_LCYAN    = "\033[1;36m"

    ANSI_BACKBLACK  = "\033[40m"
    ANSI_BACKRED    = "\033[41m"
    ANSI_BACKGREEN  = "\033[42m"
    ANSI_BACKYELLOW = "\033[43m"
    ANSI_BACKBLUE   = "\033[44m"
    ANSI_BACKPURPLE = "\033[45m"
    ANSI_BACKCYAN   = "\033[46m"
    ANSI_BACKGRAY   = "\033[47m"

    ANSI_RESET      = "\033[0m"
    ANSI_BOLD       = "\033[1m"
    ANSI_UNDERSCORE = "\033[4m"
    ANSI_BLINK      = "\033[5m"
    ANSI_REVERSE    = "\033[7m"
    ANSI_CONCEALED  = "\033[8m"

    XTERM_SET_TITLE   = "\033]2;"
    XTERM_END         = "\007"
    ITERM_SET_TAB     = "\033]1;"
    ITERM_END         = "\007"
    SCREEN_SET_STATUS = "\033]0;"
    SCREEN_END        = "\007"
  end

  # e = FooClass.new
  # pm(e, :minus_all => true)
  # pm(e, :minus_klass => [ActiveRecord::Base])
  # pm(e, :minus => true)
  # pm(e, :instance_methods => true)
  begin # Utility methods
    def pm(obj, options={}) # Print methods
      methods = obj.methods
      methods = obj.respond_to(:meta_class) ?  obj.meta_class.instance_methods(false) : obj.class.instance_methods(false) if options[:instance_methods]

      # puts "options: #{options.inspect}"

      # puts "(0) method_count: #{methods.count}"

      methods -= Object.methods unless options[:more]

      # puts "(1) method_count: #{methods.count}"
      parent_objects = obj.class.ancestors
      if defined?(ActiveRecord::Base) && parent_objects.include?(ActiveRecord::Base)
        ar_base_idx = parent_objects.rindex(ActiveRecord::Base) || 1
      end
      # puts "ar_base_idx: #{ar_base_idx}; p_o.size: #{parent_objects.size}"

      if parent_objects.size > 1
        parent_objects[1 .. ar_base_idx].collect{|klass| methods -= klass.methods} if options[:minus]
        parent_objects[1 .. (parent_objects.size - 1)].collect{|klass| methods -= klass.methods} if options[:minus_all]
        # puts "(1b) method_count: #{methods.count}"

        if options[:minus_klass] && options[:minus_klass].kind_of?(Array)
          options[:minus_klass].collect do |klass|
            methods -= parent_objects[parent_objects.rindex(klass)].methods if parent_objects.include?(klass)
          end
        end
      end
      # puts "(2a) method_count: #{methods.count}"

      filter = options[:filter] if options[:filter].kind_of?(Regexp)
      methods = methods.select {|name| name =~ filter} if filter
      # puts "(2b) method_count: #{methods.count}"

      data = methods.sort.collect do |name|
        method = obj.method(name)
        if method.arity == 0
          args = "()"
        elsif method.arity > 0
          n = method.arity
          args = "(#{(1..n).collect {|i| "arg#{i}"}.join(", ")})"
        elsif method.arity < 0
          n = -method.arity
          args = "(#{(1..n).collect {|i| "arg#{i}"}.join(", ")}, ...)"
        end
        klass = $1 if method.inspect =~ /Method: (.*?)#/
        [name, args, klass]
      end
      max_name = data.collect {|item| item[0].to_s.size}.max
      max_args = data.collect {|item| item[1].to_s.size}.max
      data.each do |item| 
        print " #{ANSI_BOLD}#{item[0].to_s.rjust(max_name)}#{ANSI_RESET}"
        print "#{ANSI_GRAY}#{item[1].to_s.ljust(max_args)}#{ANSI_RESET}"
        print "   #{ANSI_LGRAY}#{item[2]}#{ANSI_RESET}\n"
      end
      data.size
    end
  end
  IRB_RC_HAS_LOADED = true
end

#if ENV['RAILS_ENV']
#  load File.dirname(__FILE__) + '/.railsrc'
#end

# extras:
#require 'ap'
#if ! MACRUBY
#  require 'wirble'
#  Wirble.init
#  Wirble.colorize
#end

#load File.dirname(__FILE__) + '/.irb_lib/*.rb'
#Dir[File.dirname(__FILE__) + "/.irb_lib/*.rb"].each { |file| require(file)}
#include ProfileGrapher
