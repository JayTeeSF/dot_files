module ProfileGrapher
  module ClassMethods

    # FIXME: I should really add output_file and mode to the options hash
    # My one public method
    def profile(options={}, output_file="/tmp/profile_html_output_#{timestamp}.html", mode='w+', &block)
      return unless block_given?

      browser = options[:no_browser] ? false : true
      options.delete(:no_browser)

      profiler = options[:profiler] || :pt_profile
      options.delete(:profiler)

      result, output_file = send(profiler, options, output_file, mode, &block)

      browse(output_file) if browser

      result
    end

  protected
    def timestamp
      Time.now.strftime("%Y%m%d%H%M%S")
    end

    def pt_profile(options={}, output_file="/tmp/my_app_profile_#{timestamp}", mode='w+', &block)
      require 'perftools'
      num_times = options[:num_times] || 5_000
      options.delete(:num_times)

      final_result = nil
      PerfTools::CpuProfiler.start(output_file) do
          num_times.times { final_result = block.call }
      end

      generate_image(output_file)

      [final_result, image_file(output_file) ]
    end

    # profile { some_method }
    def rp_profile(options={}, output_file="/tmp/profile_html_output_#{timestamp}.html", mode='w+', &block)
      require 'ruby-prof'

      options[:min_percent] ||= 0
      num_times = options[:num_times] || 5_000
      options.delete(:num_times)

      final_result = nil
      RubyProf.start

      num_times.times { final_result = block.call }

      printer = RubyProf::GraphHtmlPrinter.new( RubyProf.stop )
      my_file = File.new(output_file, mode)
      printer.print(my_file, options)
      my_file.close

      [ final_result, output_file ]
    end

    def image_file(output_file, extension='.gif')
      output_file + extension
    end

    def generate_image(output_file, the_image_file=nil)
      the_image_file ||= image_file(output_file)
      `pprof.rb --gif #{output_file} > #{the_image_file}`
    end

    def browse(application_mapped_file)
      `open #{application_mapped_file} &`
    end
  end

  def self.included(base)
    base.extend ClassMethods
  end

  extend ClassMethods
end
