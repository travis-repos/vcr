@webmock @net_http @httpclient @wip
Feature: Development Logging
  In order to see what HTTP requests my application makes
  As a web application developer using VCR
  I want to log all HTTP interactions to a file

  Scenario: Logging all http requests
    Given the "http_logs" directory does not exist
      And a file named "http_logging_example_1.rb" with:
      """
      require 'net/http'
      require 'httpclient'
      require 'vcr'

      # stub the time so we have a deterministic time stamp
      def Time.now; Time.local(2010, 9, 21, 12); end

      VCR.log_http_to('http_logs')

      puts Net::HTTP.get_response(URI.parse('http://example.com/net_http')).body

      puts HTTPClient.new.get('http://example.com/httpclient').body.content
      """
      And a file named "http_logging_example_2.rb" with:
      """
      require 'net/http'
      require 'vcr'

      # stub the time so we have a deterministic time stamp
      def Time.now; Time.local(2010, 9, 21, 13); end

      VCR.log_http_to('http_logs')

      puts Net::HTTP.get_response(URI.parse('http://example.com/foo')).body
      """
    When I run "ruby ./http_logging_example_1.rb"
    Then the output should contain "net_http was not found"
     And the output should contain "httpclient was not found"
     And the file "http_logs/http_interactions.yml" should contain each of the following:
       | http://example.com:80/net_http   |
       | net_http was not found        |
       | http://example.com:80/httpclient |
       | httpclient was not found      |
     And the file "http_logs/http_interactions.2010-09-21_12-00-00.yml" should be identical to the file "http_logs/http_interactions.yml"

    When I run "ruby ./http_logging_example_2.rb"
    Then the output should contain "foo was not found"
     And the file "http_logs/http_interactions.yml" should contain each of the following:
       | http://example.com:80/foo |
       | foo was not found      |
     And the file "http_logs/http_interactions.2010-09-21_13-00-00.yml" should be identical to the file "http_logs/http_interactions.yml"
     And the file "http_logs/http_interactions.2010-09-21_12-00-00.yml" should contain each of the following:
       | http://example.com:80/net_http   |
       | net_http was not found        |
       | http://example.com:80/httpclient |
       | httpclient was not found      |
