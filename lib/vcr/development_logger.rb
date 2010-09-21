module VCR
  class DevelopmentLogger
    def initialize(logging_dir)
      @logging_dir = logging_dir
      setup_files
      setup_recording_hooks
    end

    def log(http_interaction)
      # TODO: thread synchronization
      log_file.write(yaml_for_http_interaction(http_interaction))
    ensure
      @previously_logged = true
    end

    private

    def yaml_for_http_interaction(http_interaction)
      # Ensure the log file is always a valid yaml file containing 
      # an array of http interactions.
      yaml = [http_interaction].to_yaml

      if @previously_logged
        yaml = yaml.gsub(/\A--- \n/, '')
      end

      yaml
    end

    def timestamp
      @timestamp ||= Time.now.strftime("%Y-%m-%d_%H-%M-%S")
    end

    LOG_FILE_BASE_NAME = 'http_interactions'

    def main_log_file
      @main_log_file ||= File.join(@logging_dir, "#{LOG_FILE_BASE_NAME}.yml")
    end

    def timestamped_log_file
      @timestamped_log_file ||= File.join(@logging_dir, "#{LOG_FILE_BASE_NAME}.#{timestamp}.yml")
    end

    def log_file
      # We use the timestamped log file rather than the main log file.
      # That way we'll log to the correct file if someone starts a second
      # instance of their app.
      @log_file ||= begin
        # TODO: what if the file already exists?  (i.e. two servers started on the same second)
        file = File.open(timestamped_log_file, 'w')
        file.sync = true
        file
      end
    end

    def setup_files
      FileUtils.mkdir_p(@logging_dir)
      FileUtils.touch(timestamped_log_file)
      FileUtils.ln_s(File.basename(timestamped_log_file), main_log_file, :force => true)
    end

    def setup_recording_hooks
      VCR.config { |c| c.http_stubbing_library = :webmock }
      VCR.http_stubbing_adapter.http_connections_allowed = true
    end
  end
end
