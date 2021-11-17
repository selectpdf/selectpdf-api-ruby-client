# frozen_string_literal: true

require 'net/https'
require 'json'
require 'fileutils'

#
# SelectPdf Online REST API Ruby client library. Contains HTML to PDF converter, PDF merge, PDF to text extractor, search PDF.
#
#
# Convert HTML to PDF
#
#  require 'selectpdf'
#  print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"
#
#  url = 'https://selectpdf.com'
#  local_file = 'Test.pdf'
#  api_key = 'Your API key here'
#
#  begin
#    api = SelectPdf::HtmlToPdfClient.new(api_key)
#
#    api.page_size = SelectPdf::PageSize::A4
#    api.margins = 0
#    api.page_numbers = FALSE
#    api.page_breaks_enhanced_algorithm = TRUE
#
#    api.convert_url_to_file(url, local_file)
#  rescue SelectPdf::ApiException => e
#    print("An error occurred: #{e}")
#  end
#
# Merge PDFs from local disk or public url and save result into a file on disk.
#
#  require 'selectpdf'
#
#  $stdout.sync = true
#  
#  print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"
#  
#  test_url = 'https://selectpdf.com/demo/files/selectpdf.pdf'
#  test_pdf = 'Input.pdf'
#  local_file = 'Result.pdf'
#  api_key = 'Your API key here'
#  
#  begin
#    client = SelectPdf::PdfMergeClient.new(api_key)
#  
#    # set parameters - see full list at https://selectpdf.com/pdf-merge-api/
#  
#    # specify the pdf files that will be merged (order will be preserved in the final pdf)
#    client.add_file(test_pdf) # add PDF from local file
#    client.add_url_file(test_url) # add PDF from public url
#    # client.add_file(test_pdf, 'pdf_password') # add PDF (that requires a password) from local file
#    # client.add_url_file(test_url, 'pdf_password') # add PDF (that requires a password) from public url
#  
#    print "Starting pdf merge ...\n"
#  
#    # merge pdfs to local file
#    client.save_to_file(local_file)
#  
#    # merge pdfs to memory
#    # pdf = client.save
#  
#    print "Finished! Number of pages: #{client.number_of_pages}.\n"
#  
#    # get API usage
#    usage_client = SelectPdf::UsageClient.new(api_key)
#    usage = usage_client.get_usage(FALSE)
#    print("Usage: #{usage}\n")
#    print('Conversions remained this month: ', usage['available'], "\n")
#  rescue SelectPdf::ApiException => e
#    print("An error occurred: #{e}")
#  end
#
# Extract text from PDF
#
#  require 'selectpdf'
#
#  $stdout.sync = true
#
#  print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"
#
#  test_url = 'https://selectpdf.com/demo/files/selectpdf.pdf'
#  test_pdf = 'Input.pdf'
#  local_file = 'Result.txt'
#  api_key = 'Your API key here'
#
#  begin
#    client = SelectPdf::PdfToTextClient.new(api_key)
#
#    # set parameters - see full list at https://selectpdf.com/pdf-to-text-api/
#    client.start_page = 1 # start page (processing starts from here)
#    client.end_page = 0 # end page (set 0 to process file til the end)
#    client.output_format = SelectPdf::OutputFormat::TEXT # set output format (Text or HTML)
#
#    print "Starting pdf to text ...\n"
#
#    # convert local pdf to local text file
#    client.text_from_file_to_file(test_pdf, local_file)
#
#    # extract text from local pdf to memory
#    # text = client.text_from_file(test_pdf)
#    # print text
#
#    # convert pdf from public url to local text file
#    # client.text_from_url_to_file(test_url, local_file)
#
#    # extract text from pdf from public url to memory
#    # text = client.text_from_url(test_url)
#    # print text
#
#    print "Finished! Number of pages processed: #{client.number_of_pages}.\n"
#
#    # get API usage
#    usage_client = SelectPdf::UsageClient.new(api_key)
#    usage = usage_client.get_usage(FALSE)
#    print("Usage: #{usage}\n")
#    print('Conversions remained this month: ', usage['available'], "\n")
#  rescue SelectPdf::ApiException => e
#    print("An error occurred: #{e}")
#  end
#
# Search Pdf
#
#    require 'selectpdf'
#
#    $stdout.sync = true
#    
#    print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"
#    
#    test_url = 'https://selectpdf.com/demo/files/selectpdf.pdf'
#    test_pdf = 'Input.pdf'
#    api_key = 'Your API key here'
#    
#    begin
#      client = SelectPdf::PdfToTextClient.new(api_key)
#    
#      # set parameters - see full list at https://selectpdf.com/pdf-to-text-api/
#      client.start_page = 1 # start page (processing starts from here)
#      client.end_page = 0 # end page (set 0 to process file til the end)
#      client.output_format = SelectPdf::OutputFormat::TEXT # set output format (Text or HTML)
#    
#      print "Starting search pdf ...\n"
#    
#      # search local pdf
#      results = client.search_file(test_pdf, 'pdf')
#    
#      # search pdf from public url
#      # results = client.search_url(test_url, 'pdf')
#    
#      print "Search results: #{results}.\nSearch results count: #{results.length}\n"
#    
#      print "Finished! Number of pages processed: #{client.number_of_pages}.\n"
#    
#      # get API usage
#      usage_client = SelectPdf::UsageClient.new(api_key)
#      usage = usage_client.get_usage(FALSE)
#      print("Usage: #{usage}\n")
#      print('Conversions remained this month: ', usage['available'], "\n")
#    rescue SelectPdf::ApiException => e
#      print("An error occurred: #{e}")
#    end
#
module SelectPdf
  # Multipart/form-data boundary
  MULTIPART_FORM_DATA_BOUNDARY = '------------SelectPdf_Api_Boundry_$'

  # New line
  NEW_LINE = "\r\n"

  # Library version
  CLIENT_VERSION = '1.4.0'

  attr_reader :code, :message
  #
  # Exception thrown by SelectPdf API Client.
  #
  class ApiException < RuntimeError
    # Class constructor
    def initialize(message, code = nil)
      super()
      @message = message
      @code = code
    end

    # Get complete error message
    def to_s
      @code ? "(#{@code}) #{@message}" : @message
    end
  end

  # Base class for API clients. Do not use this directly.
  class ApiClient
    # API endpoint
    attr_reader :api_endpoint

    # API endpoint
    attr_writer :api_endpoint

    # API async jobs endpoint
    attr_reader :api_async_endpoint

    # API async jobs endpoint
    attr_writer :api_async_endpoint

    # API web elements endpoint
    attr_reader :api_web_elements_endpoint

    # API web elements endpoint
    attr_writer :api_web_elements_endpoint

    # Ping interval in seconds for asynchronous calls. Default value is 3 seconds.
    attr_reader :async_calls_ping_interval

    # Ping interval in seconds for asynchronous calls. Default value is 3 seconds.
    attr_writer :async_calls_ping_interval

    # Maximum number of pings for asynchronous calls. Default value is 1,000 pings.
    attr_reader :async_calls_max_pings

    # Maximum number of pings for asynchronous calls. Default value is 1,000 pings.
    attr_writer :async_calls_max_pings

    # Number of pages of the pdf document resulted from the conversion.
    attr_reader :number_of_pages

    # Class constructor
    def initialize
      # API endpoint
      @api_endpoint = 'https://selectpdf.com/api2/convert/'

      # API async jobs endpoint
      @api_async_endpoint = 'https://selectpdf.com/api2/asyncjob/'

      # API web elements endpoint
      @api_web_elements_endpoint = 'https://selectpdf.com/api2/webelements/'

      # Parameters that will be sent to the API.
      @parameters = {}

      # HTTP Headers that will be sent to the API.
      @headers = {}

      # Files that will be sent to the API.
      @files = {}

      # Binary data that will be sent to the API.
      @binary_data = {}

      # Number of pages of the pdf document resulted from the conversion.
      @number_of_pages = 0

      # Job ID for asynchronous calls or for calls that require a second request.
      @job_id = ''

      # Ping interval in seconds for asynchronous calls. Default value is 3 seconds.
      @async_calls_ping_interval = 3

      # Maximum number of pings for asynchronous calls. Default value is 1,000 pings.
      @async_calls_max_pings = 1000
    end

    # Create a POST request.
    #
    # @param out_stream Output response to this stream, if specified.
    # @return If output stream is not specified, return response.
    def perform_post(out_stream = nil)
      # reset results
      @number_of_pages = 0
      @job_id = ''

      uri = URI(api_endpoint)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = @api_endpoint.downcase.start_with?('https')
      http.read_timeout = 600 # timeout in seconds 600s=10minutes

      http.start do |connection|
        request = Net::HTTP::Post.new uri.request_uri
        request.set_form_data(@parameters)

        # add headers
        request['selectpdf-api-client'] = "ruby-#{RUBY_VERSION}-#{CLIENT_VERSION}"
        request['Content-Type'] = 'application/x-www-form-urlencoded'
        @headers.each do |key, value|
          request[key] = value
        end

        connection.request request do |response|
          case response
          when Net::HTTPSuccess
            # all ok
            @number_of_pages = (response['selectpdf-api-pages'] || 0).to_i
            @job_id = response['selectpdf-api-jobid']

            return response.body unless out_stream # return response if out_stream is not provided

            # out_steam is provided - write to it
            response.read_body do |chunk|
              out_stream.write chunk
            end
          when Net::HTTPAccepted
            # request accepted (for asynchronous jobs)
            @job_id = response['selectpdf-api-jobid']

            return nil
          else
            # error - get error message
            raise ApiException.new(response.body, response.code), response.body
          end
        end
      end
    rescue ApiException
      raise
    rescue SocketError => e
      raise ApiException.new("Socket Error: #{e}"), "Socket Error: #{e}"
    rescue Timeout::Error
      raise ApiException.new("Connection Timeout: #{http.read_timeout}s exceeded"), "Connection Timeout: #{http.read_timeout}s exceeded"
    rescue OpenSSL::SSL::SSLError => e
      raise ApiException.new("SSL Error: #{e}"), "SSL Error: #{e}"
    rescue StandardError => e
      raise ApiException.new("Connection refused: #{e}"), "Connection refused: #{e}"
    end
    protected :perform_post

    # Create a multipart/form-data POST request (that can handle file uploads).
    #
    # @param out_stream Output response to this stream, if specified.
    # @return If output stream is not specified, return response.
    def perform_post_as_multipart_formdata(out_stream = nil)
      # reset results
      @number_of_pages = 0
      @job_id = ''

      uri = URI(api_endpoint)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = @api_endpoint.downcase.start_with?('https')
      http.read_timeout = 600 # timeout in seconds 600s=10minutes

      http.start do |connection|
        request = Net::HTTP::Post.new uri.request_uri
        request.body = encode_multipart_form_data

        # add headers
        request['selectpdf-api-client'] = "ruby-#{RUBY_VERSION}-#{CLIENT_VERSION}"
        request['Content-Type'] = "multipart/form-data; boundary=#{MULTIPART_FORM_DATA_BOUNDARY}"
        request['Content-Length'] = request.body.length

        @headers.each do |key, value|
          request[key] = value
        end

        connection.request request do |response|
          case response
          when Net::HTTPSuccess
            # all ok
            @number_of_pages = (response['selectpdf-api-pages'] || 0).to_i
            @job_id = response['selectpdf-api-jobid']

            return response.body unless out_stream # return response if out_stream is not provided

            # out_steam is provided - write to it
            response.read_body do |chunk|
              out_stream.write chunk
            end
          when Net::HTTPAccepted
            # request accepted (for asynchronous jobs)
            @job_id = response['selectpdf-api-jobid']

            return nil
          else
            # error - get error message
            raise ApiException.new(response.body, response.code), response.body
          end
        end
      end
    rescue ApiException
      raise
    rescue SocketError => e
      raise ApiException.new("Socket Error: #{e}"), "Socket Error: #{e}"
    rescue Timeout::Error
      raise ApiException.new("Connection Timeout: #{http.read_timeout}s exceeded"), "Connection Timeout: #{http.read_timeout}s exceeded"
    rescue OpenSSL::SSL::SSLError => e
      raise ApiException.new("SSL Error: #{e}"), "SSL Error: #{e}"
    rescue StandardError => e
      raise ApiException.new("Connection refused: #{e}"), "Connection refused: #{e}"
    end
    protected :perform_post_as_multipart_formdata

    # Encode data for multipart POST
    def encode_multipart_form_data
      data = []

      # encode regular parameters
      @parameters.each do |key, value|
        data << '--' + MULTIPART_FORM_DATA_BOUNDARY << 'Content-Disposition: form-data; name="%s"' % key << '' << value.to_s if value
      end

      # encode files
      @files.each do |key, value|
        File.open(value, 'rb') do |f|
          data << '--' + MULTIPART_FORM_DATA_BOUNDARY
          data << 'Content-Disposition: form-data; name="%s"; filename="%s"' % [key, value]
          data << 'Content-Type: application/octet-stream'
          data << ''
          data << f.read.force_encoding('UTF-8')
        end
      end

      # encode additional binary data
      @binary_data.each do |key, value|
        data << '--' + MULTIPART_FORM_DATA_BOUNDARY
        data << 'Content-Disposition: form-data; name="%s"; filename="%s"' % [key, key]
        data << 'Content-Type: application/octet-stream'
        data << ''
        data << value.force_encoding('UTF-8')
      end

      # final boundary
      data << '--' + MULTIPART_FORM_DATA_BOUNDARY + '--'
      data << ''

      data.join(NEW_LINE)
    end
    private :encode_multipart_form_data

    # Start an asynchronous job.
    #
    # @return Asynchronous job ID.
    def start_async_job
      @parameters['async'] = 'True'
      perform_post
      @job_id
    end
    protected :start_async_job

    # Start an asynchronous job that requires multipart forma data.
    #
    # @return Asynchronous job ID.
    def start_async_job_multipart_form_data
      @parameters['async'] = 'True'
      perform_post_as_multipart_formdata
      @job_id
    end
    protected :start_async_job_multipart_form_data
  end

  # Get usage details for SelectPdf Online API.
  class UsageClient < ApiClient
    # Construct the Usage client.
    #
    # @param api_key API Key.
    def initialize(api_key)
      super()
      @api_endpoint = 'https://selectpdf.com/api2/usage/'
      @parameters['key'] = api_key
    end

    # Get API usage information with history if specified.
    #
    # @param get_history Get history or not.
    # @return Usage information.
    def get_usage(get_history = false)
      @headers['Accept'] = 'text/json'
      @parameters['get_history'] = 'True' if get_history

      result = perform_post
      JSON.parse(result)
    end
  end

  # PDF page size.
  class PageSize
    # Custom page size.
    CUSTOM = 'Custom'

    # A0 page size.
    A0 = 'A0'

    # A1 page size.
    A1 = 'A1'

    # A2 page size.
    A2 = 'A2'

    # A3 page size.
    A3 = 'A3'

    # A4 page size.
    A4 = 'A4'

    # A5 page size.
    A5 = 'A5'

    # A6 page size.
    A6 = 'A6'

    # A7 page size.
    A7 = 'A7'

    # A8 page size.
    A8 = 'A8'

    # Letter page size.
    LETTER = 'Letter'

    # Half Letter page size.
    HALF_LETTER = 'HalfLetter'

    # Ledger page size.
    LEDGER = 'Ledger'

    # A5 page size.
    LEGAL = 'Legal'
  end

  # PDF page orientation.
  class PageOrientation
    # Portrait page orientation.
    PORTRAIT = 'Portrait'

    # Landscape page orientation.
    LANDSCAPE = 'Landscape'
  end

  # Rendering engine used for HTML to PDF conversion.
  class RenderingEngine
    # WebKit rendering engine.
    WEBKIT = 'WebKit'

    # WebKit Restricted rendering engine.
    RESTRICTED = 'Restricted'

    # Blink rendering engine.
    BLINK = 'Blink'
  end

  # Protocol used for secure (HTTPS) connections.
  class SecureProtocol
    # TLS 1.1 or newer. Recommended value.
    TLS_11_OR_NEWER = 0

    # TLS 1.0 only.
    TLS10 = 1

    # SSL v3 only.
    SSL3 = 2
  end

  # The page layout to be used when the pdf document is opened in a viewer.
  class PageLayout
    # Displays one page at a time.
    SINGLE_PAGE = 0

    # Displays the pages in one column.
    ONE_COLUMN = 1

    # Displays the pages in two columns, with odd-numbered pages on the left.
    TWO_COLUMN_LEFT = 2

    # Displays the pages in two columns, with odd-numbered pages on the right.
    TWO_COLUMN_RIGHT = 3
  end

  # The PDF document's page mode.
  class PageMode
    # Neither document outline (bookmarks) nor thumbnail images are visible.
    USE_NONE = 0

    # Document outline (bookmarks) are visible.
    USE_OUTLINES = 1

    # Thumbnail images are visible.
    USE_THUMBS = 2

    # Full-screen mode, with no menu bar, window controls or any other window visible.
    FULL_SCREEN = 3

    # Optional content group panel is visible.
    USE_OC = 4

    # Document attachments are visible.
    USE_ATTACHMENTS = 5
  end

  # Alignment for page numbers.
  class PageNumbersAlignment
    # Align left.
    LEFT = 1

    # Align center.
    CENTER = 2

    # Align right.
    RIGHT = 3
  end

  # Specifies the converter startup mode.
  class StartupMode
    # The conversion starts right after the page loads.
    AUTOMATIC = 'Automatic'

    # The conversion starts only when called from JavaScript.
    MANUAL = 'Manual'
  end

  # The output text layout (for pdf to text calls).
  class TextLayout
    # The original layout of the text from the PDF document is preserved.
    ORIGINAL = 0

    # The text is produced in reading order.
    READING = 1
  end

  # The output format (for pdf to text calls).
  class OutputFormat
    # Text
    TEXT = 0

    # Html
    HTML = 1
  end

  # Html To Pdf Conversion with SelectPdf Online API.
  #
  # Code sample:
  #
  #  require 'selectpdf'
  #
  #  $stdout.sync = true
  #  
  #  print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"
  #  
  #  url = 'https://selectpdf.com'
  #  local_file = 'Test.pdf'
  #  api_key = 'Your API key here'
  #  
  #  begin
  #    client = SelectPdf::HtmlToPdfClient.new(api_key)
  #  
  #    # set parameters - see full list at https://selectpdf.com/html-to-pdf-api/
  #  
  #    client.page_size = SelectPdf::PageSize::A4 # PDF page size
  #    client.page_orientation = SelectPdf::PageOrientation::PORTRAIT # PDF page orientation
  #    client.margins = 0 # PDF page margins
  #    client.rendering_engine = SelectPdf::RenderingEngine::WEBKIT # rendering engine
  #    client.conversion_delay = 1 # conversion delay
  #    client.navigation_timeout = 30 # navigation timeout
  #    client.page_numbers = FALSE # page numbers
  #    client.page_breaks_enhanced_algorithm = TRUE # enhanced page break algorithm
  #  
  #    # additional properties
  #  
  #    # client.use_css_print = TRUE # enable CSS media print
  #    # client.disable_javascript = TRUE # disable javascript
  #    # client.disable_internal_links = TRUE # disable internal links
  #    # client.disable_external_links = TRUE # disable external links
  #    # client.keep_images_together = TRUE # keep images together
  #    # client.scale_images = TRUE # scale images to create smaller pdfs
  #    # client.single_page_pdf = TRUE # generate a single page PDF
  #    # client.user_password = 'password' # secure the PDF with a password
  #  
  #    # generate automatic bookmarks
  #  
  #    # client.pdf_bookmarks_selectors = 'H1, H2' # create outlines (bookmarks) for the specified elements
  #    # client.viewer_page_mode = SelectPdf::PageMode::USE_OUTLINES # display outlines (bookmarks) in viewer
  #  
  #    print "Starting conversion ...\n"
  #  
  #    # convert url to file
  #    client.convert_url_to_file(url, local_file)
  #  
  #    # convert url to memory
  #    # pdf = client.convert_url(url)
  #  
  #    # convert html string to file
  #    # client.convert_html_string_to_file('This is some <b>html</b>.', local_file)
  #  
  #    # convert html string to memory
  #    # pdf = client.convert_html_string('This is some <b>html</b>.')
  #  
  #    print "Finished! Number of pages: #{client.number_of_pages}.\n"
  #  
  #    # get API usage
  #    usage_client = SelectPdf::UsageClient.new(api_key)
  #    usage = usage_client.get_usage(FALSE)
  #    print("Usage: #{usage}\n")
  #    print('Conversions remained this month: ', usage['available'], "\n")
  #  rescue SelectPdf::ApiException => e
  #    print("An error occurred: #{e}")
  #  end
  class HtmlToPdfClient < ApiClient
    # Construct the Html To Pdf Client.
    #
    # @param api_key API Key.
    def initialize(api_key)
      super()
      @api_endpoint = 'https://selectpdf.com/api2/convert/'
      @parameters['key'] = api_key
    end

    # Convert the specified url to PDF.
    # SelectPdf online API can convert http:// and https:// publicly available urls.
    #
    # @param url Address of the web page being converted.
    # @return The resulted pdf.
    def convert_url(url)
      if !url.downcase.start_with?('http://') && !url.downcase.start_with?('https://')
        raise ApiException.new('The supported protocols for the converted webpage are http:// and https://.'), 'The supported protocols for the converted webpage are http:// and https://.'
      end

      if url.downcase.start_with?('http://localhost')
        raise ApiException.new('Cannot convert local urls. SelectPdf online API can only convert publicly available urls.'), 'Cannot convert local urls. SelectPdf online API can only convert publicly available urls.'
      end

      @parameters['url'] = url
      @parameters.delete('html')
      @parameters.delete('base_url')
      @parameters['async'] = 'False'

      perform_post
    end

    # Convert the specified url to PDF and writes the resulted PDF to an output stream. 
    # SelectPdf online API can convert http:// and https:// publicly available urls.
    #
    # @param url Address of the web page being converted.
    # @param stream The output stream where the resulted PDF will be written.
    def convert_url_to_stream(url, stream)
      if !url.downcase.start_with?('http://') && !url.downcase.start_with?('https://')
        raise ApiException.new('The supported protocols for the converted webpage are http:// and https://.'), 'The supported protocols for the converted webpage are http:// and https://.'
      end

      if url.downcase.start_with?('http://localhost')
        raise ApiException.new('Cannot convert local urls. SelectPdf online API can only convert publicly available urls.'), 'Cannot convert local urls. SelectPdf online API can only convert publicly available urls.'
      end

      @parameters['url'] = url
      @parameters.delete('html')
      @parameters.delete('base_url')
      @parameters['async'] = 'False'

      perform_post(stream)
    end

    # Convert the specified url to PDF and writes the resulted PDF to a local file.
    # SelectPdf online API can convert http:// and https:// publicly available urls.
    #
    # @param url Address of the web page being converted.
    # @param file_path Local file including path if necessary.
    def convert_url_to_file(url, file_path)
      if !url.downcase.start_with?('http://') && !url.downcase.start_with?('https://')
        raise ApiException.new('The supported protocols for the converted webpage are http:// and https://.'), 'The supported protocols for the converted webpage are http:// and https://.'
      end

      if url.downcase.start_with?('http://localhost')
        raise ApiException.new('Cannot convert local urls. SelectPdf online API can only convert publicly available urls.'), 'Cannot convert local urls. SelectPdf online API can only convert publicly available urls.'
      end

      @parameters['url'] = url
      @parameters.delete('html')
      @parameters.delete('base_url')
      @parameters['async'] = 'False'

      begin
        File.open(file_path, 'wb') do |file|
          perform_post(file)
        end
      rescue ApiException
        FileUtils.rm(file_path) if File.exist?(file_path)
        raise
      end
    end

    # Convert the specified url to PDF using an asynchronous call.
    # SelectPdf online API can convert http:// and https:// publicly available urls.
    #
    # @param url Address of the web page being converted.
    # @return The resulted pdf.
    def convert_url_async(url)
      if !url.downcase.start_with?('http://') && !url.downcase.start_with?('https://')
        raise ApiException.new('The supported protocols for the converted webpage are http:// and https://.'), 'The supported protocols for the converted webpage are http:// and https://.'
      end

      if url.downcase.start_with?('http://localhost')
        raise ApiException.new('Cannot convert local urls. SelectPdf online API can only convert publicly available urls.'), 'Cannot convert local urls. SelectPdf online API can only convert publicly available urls.'
      end

      @parameters['url'] = url
      @parameters.delete('html')
      @parameters.delete('base_url')

      job_id = start_async_job

      if job_id.nil? || job_id.empty?
        raise ApiException.new('An error occurred launching the asynchronous call.'), 'An error occurred launching the asynchronous call.'
      end

      no_pings = 0

      while no_pings < @async_calls_max_pings
        no_pings += 1

        # sleep for a few seconds before next ping
        sleep(@async_calls_ping_interval)

        async_job_client = AsyncJobClient.new(@parameters['key'], @job_id)
        async_job_client.api_endpoint = @api_async_endpoint

        result = async_job_client.result

        next if result.nil?

        @number_of_pages = async_job_client.number_of_pages
        return result
      end

      raise ApiException.new('Asynchronous call did not finish in expected timeframe.'), 'Asynchronous call did not finish in expected timeframe.'
    end

    # Convert the specified url to PDF using an asynchronous call and writes the resulted PDF to an output stream.
    # SelectPdf online API can convert http:// and https:// publicly available urls.
    #
    # @param url Address of the web page being converted.
    # @param stream The output stream where the resulted PDF will be written.
    def convert_url_to_stream_async(url, stream)
      result = convert_url_async(url)
      stream.write(result)
    end

    # Convert the specified url to PDF using an asynchronous call and writes the resulted PDF to a local file. 
    # SelectPdf online API can convert http:// and https:// publicly available urls.
    #
    # @param url Address of the web page being converted.
    # @param file_path Local file including path if necessary.
    def convert_url_to_file_async(url, file_path)
      result = convert_url_async(url)
      File.open(file_path, 'wb') do |file|
        file.write(result)
      end
    rescue ApiException
      FileUtils.rm(file_path) if File.exist?(file_path)
      raise
    end

    # Convert the specified HTML string to PDF. Use a base url to resolve relative paths to resources.
    #
    # @param html_string HTML string with the content being converted.
    # @param base_url Base url used to resolve relative paths to resources (css, images, javascript, etc). Must be a http:// or https:// publicly available url.
    def convert_html_string_with_base_url(html_string, base_url)
      @parameters.delete('url')
      @parameters['async'] = 'False'
      @parameters['html'] = html_string
      @parameters['base_url'] = base_url unless base_url.nil? || base_url.empty?

      perform_post
    end

    # Convert the specified HTML string to PDF and writes the resulted PDF to an output stream. Use a base url to resolve relative paths to resources.
    #
    # @param html_string HTML string with the content being converted.
    # @param base_url Base url used to resolve relative paths to resources (css, images, javascript, etc). Must be a http:// or https:// publicly available url.
    # @param stream The output stream where the resulted PDF will be written.
    def convert_html_string_to_stream_with_base_url(html_string, base_url, stream)
      @parameters.delete('url')
      @parameters['async'] = 'False'
      @parameters['html'] = html_string
      @parameters['base_url'] = base_url unless base_url.nil? || base_url.empty?

      perform_post(stream)
    end

    # Convert the specified HTML string to PDF and writes the resulted PDF to a local file. Use a base url to resolve relative paths to resources.
    #
    # @param html_string HTML string with the content being converted.
    # @param base_url Base url used to resolve relative paths to resources (css, images, javascript, etc). Must be a http:// or https:// publicly available url.
    # @param file_path Local file including path if necessary.
    def convert_html_string_with_base_url_to_file(html_string, base_url, file_path)
      @parameters.delete('url')
      @parameters['async'] = 'False'
      @parameters['html'] = html_string
      @parameters['base_url'] = base_url unless base_url.nil? || base_url.empty?

      begin
        File.open(file_path, 'wb') do |file|
          perform_post(file)
        end
      rescue ApiException
        FileUtils.rm(file_path) if File.exist?(file_path)
        raise
      end
    end

    # Convert the specified HTML string to PDF with an asynchronous call. Use a base url to resolve relative paths to resources.
    #
    # @param html_string HTML string with the content being converted.
    # @param base_url Base url used to resolve relative paths to resources (css, images, javascript, etc). Must be a http:// or https:// publicly available url.
    def convert_html_string_with_base_url_async(html_string, base_url)
      @parameters.delete('url')
      @parameters['html'] = html_string
      @parameters['base_url'] = base_url unless base_url.nil? || base_url.empty?

      job_id = start_async_job

      if job_id.nil? || job_id.empty?
        raise ApiException.new('An error occurred launching the asynchronous call.'), 'An error occurred launching the asynchronous call.'
      end

      no_pings = 0

      while no_pings < @async_calls_max_pings
        no_pings += 1

        # sleep for a few seconds before next ping
        sleep(@async_calls_ping_interval)

        async_job_client = AsyncJobClient.new(@parameters['key'], @job_id)
        async_job_client.api_endpoint = @api_async_endpoint

        result = async_job_client.result

        next if result.nil?

        @number_of_pages = async_job_client.number_of_pages
        return result
      end

      raise ApiException.new('Asynchronous call did not finish in expected timeframe.'), 'Asynchronous call did not finish in expected timeframe.'
    end

    # Convert the specified HTML string to PDF with an asynchronous call and writes the resulted PDF to an output stream. Use a base url to resolve relative paths to resources.
    #
    # @param html_string HTML string with the content being converted.
    # @param base_url Base url used to resolve relative paths to resources (css, images, javascript, etc). Must be a http:// or https:// publicly available url.
    # @param stream The output stream where the resulted PDF will be written.
    def convert_html_string_to_stream_with_base_url_async(html_string, base_url, stream)
      result = convert_html_string_with_base_url_async(html_string, base_url)
      stream.write(result)
    end

    # Convert the specified HTML string to PDF with an asynchronous call and writes the resulted PDF to a local file. Use a base url to resolve relative paths to resources.
    #
    # @param html_string HTML string with the content being converted.
    # @param base_url Base url used to resolve relative paths to resources (css, images, javascript, etc). Must be a http:// or https:// publicly available url.
    # @param file_path Local file including path if necessary.
    def convert_html_string_with_base_url_to_file_async(html_string, base_url, file_path)
      result = convert_html_string_with_base_url_async(html_string, base_url)
      File.open(file_path, 'wb') do |file|
        file.write(result)
      end
    rescue ApiException
      FileUtils.rm(file_path) if File.exist?(file_path)
      raise
    end

    # Convert the specified HTML string to PDF.
    #
    # @param html_string HTML string with the content being converted.
    def convert_html_string(html_string)
      convert_html_string_with_base_url(html_string, nil)
    end

    # Convert the specified HTML string to PDF and writes the resulted PDF to an output stream.
    #
    # @param html_string HTML string with the content being converted.
    # @param stream The output stream where the resulted PDF will be written.
    def convert_html_string_to_stream(html_string, stream)
      convert_html_string_to_stream_with_base_url(html_string, nil, stream)
    end

    # Convert the specified HTML string to PDF and writes the resulted PDF to a local file.
    #
    # @param html_string HTML string with the content being converted.
    # @param file_path Local file including path if necessary.
    def convert_html_string_to_file(html_string, file_path)
      convert_html_string_with_base_url_to_file(html_string, nil, file_path)
    end

    # Convert the specified HTML string to PDF with an asynchronous call.
    #
    # @param html_string HTML string with the content being converted.
    def convert_html_string_async(html_string)
      convert_html_string_with_base_url_async(html_string, nil)
    end

    # Convert the specified HTML string to PDF with an asynchronous call and writes the resulted PDF to an output stream.
    #
    # @param html_string HTML string with the content being converted.
    # @param stream The output stream where the resulted PDF will be written.
    def convert_html_string_to_stream_async(html_string, stream)
      convert_html_string_to_stream_with_base_url_async(html_string, nil, stream)
    end

    # Convert the specified HTML string to PDF with an asynchronous call and writes the resulted PDF to a local file.
    #
    # @param html_string HTML string with the content being converted.
    # @param file_path Local file including path if necessary.
    def convert_html_string_to_file_async(html_string, file_path)
      convert_html_string_with_base_url_to_file_async(html_string, nil, file_path)
    end

    # Set PDF page size. Default value is A4.
    # If page size is set to Custom, use setPageWidth and setPageHeight methods to set the custom width/height of the PDF pages.
    #
    # @param page_size PDF page size. Possible values: Custom, A0, A1, A2, A3, A4, A5, A6, A7, A8, Letter, HalfLetter, Ledger, Legal. Use constants from SelectPdf::PageSize class.
    def page_size=(page_size)
      unless /(?i)^(Custom|A0|A1|A2|A3|A4|A5|A6|A7|A8|Letter|HalfLetter|Ledger|Legal)$/.match(page_size)
        raise ApiException.new('Allowed values for Page Size: Custom, A0, A1, A2, A3, A4, A5, A6, A7, A8, Letter, HalfLetter, Ledger, Legal.'), 'Allowed values for Page Size: Custom, A0, A1, A2, A3, A4, A5, A6, A7, A8, Letter, HalfLetter, Ledger, Legal.'
      end

      @parameters['page_size'] = page_size
    end

    # Set PDF page width in points. Default value is 595pt (A4 page width in points). 1pt = 1/72 inch.
    # This is taken into account only if page size is set to SelectPdf::PageSize::CUSTOM using page_size property.
    #
    # @param page_width Page width in points.
    def page_width=(page_width)
      @parameters['page_width'] = page_width
    end

    # Set PDF page height in points. Default value is 842pt (A4 page height in points). 1pt = 1/72 inch.
    # This is taken into account only if page size is set to SelectPdf::PageSize::CUSTOM using page_size property.
    #
    # @param page_height Page height in points.
    def page_height=(page_height)
      @parameters['page_height'] = page_height
    end

    # Set PDF page orientation. Default value is Portrait.
    #
    # @param page_orientation PDF page orientation. Possible values: Portrait, Landscape. Use constants from SelectPdf::PageOrientation class.
    def page_orientation=(page_orientation)
      unless /(?i)^(Portrait|Landscape)$/.match(page_orientation)
        raise ApiException.new('Allowed values for Page Orientation: Portrait, Landscape.'), 'Allowed values for Page Orientation: Portrait, Landscape.'
      end

      @parameters['page_orientation'] = page_orientation
    end

    # Set top margin of the PDF pages. Default value is 5pt.
    #
    # @param margin_top Margin value in points. 1pt = 1/72 inch.
    def margin_top=(margin_top)
      @parameters['margin_top'] = margin_top
    end

    # Set right margin of the PDF pages. Default value is 5pt.
    #
    # @param margin_right Margin value in points. 1pt = 1/72 inch.
    def margin_right=(margin_right)
      @parameters['margin_right'] = margin_right
    end

    # Set bottom margin of the PDF pages. Default value is 5pt.
    #
    # @param margin_bottom Margin value in points. 1pt = 1/72 inch.
    def margin_bottom=(margin_bottom)
      @parameters['margin_bottom'] = margin_bottom
    end

    # Set left margin of the PDF pages. Default value is 5pt.
    #
    # @param margin_left Margin value in points. 1pt = 1/72 inch.
    def margin_left=(margin_left)
      @parameters['margin_left'] = margin_left
    end

    # Set all margins of the PDF pages to the same value. Default value is 5pt.
    #
    # @param margin Margin value in points. 1pt = 1/72 inch.
    def margins=(margin)
      @parameters['margin_top'] = margin
      @parameters['margin_right'] = margin
      @parameters['margin_bottom'] = margin
      @parameters['margin_left'] = margin
    end

    # Specify the name of the pdf document that will be created. The default value is Document.pdf.
    #
    # @param pdf_name Name of the generated PDF document.
    def pdf_name=(pdf_name)
      @parameters['pdf_name'] = pdf_name
    end

    # Set the rendering engine used for the HTML to PDF conversion. Default value is WebKit.
    #
    # @param rendering_engine HTML rendering engine. Use constants from SelectPdf::RenderingEngine class.
    def rendering_engine=(rendering_engine)
      unless /(?i)^(WebKit|Restricted|Blink)$/.match(rendering_engine)
        raise ApiException.new('Allowed values for Rendering Engine: WebKit, Restricted, Blink.'), 'Allowed values for Rendering Engine: WebKit, Restricted, Blink.'
      end

      @parameters['engine'] = rendering_engine
    end

    # Set PDF user password.
    #
    # @param user_password PDF user password.
    def user_password=(user_password)
      @parameters['user_password'] = user_password
    end

    # Set PDF owner password.
    #
    # @param owner_password PDF owner password.
    def owner_password=(owner_password)
      @parameters['owner_password'] = owner_password
    end

    # Set the width used by the converter's internal browser window in pixels. The default value is 1024px.
    #
    # @param web_page_width Browser window width in pixels.
    def web_page_width=(web_page_width)
      @parameters['web_page_width'] = web_page_width
    end

    # Set the height used by the converter's internal browser window in pixels.
    # The default value is 0px and it means that the page height is automatically calculated by the converter.
    #
    # @param web_page_height Browser window height in pixels. Set it to 0px to automatically calculate page height.
    def web_page_height=(web_page_height)
      @parameters['web_page_height'] = web_page_height
    end

    # Introduce a delay (in seconds) before the actual conversion to allow the web page to fully load. This property is an alias for conversion_delay.
    # The default value is 1 second. Use a larger value if the web page has content that takes time to render when it is displayed in the browser.
    #
    # @param min_load_time Delay in seconds.
    def min_load_time=(min_load_time)
      @parameters['min_load_time'] = min_load_time
    end

    # Introduce a delay (in seconds) before the actual conversion to allow the web page to fully load. This method is an alias for min_load_time.
    # The default value is 1 second. Use a larger value if the web page has content that takes time to render when it is displayed in the browser.
    #
    # @param conversion_delay Delay in seconds.
    def conversion_delay=(conversion_delay)
      self.min_load_time = conversion_delay
    end

    # Set the maximum amount of time (in seconds) that the convert will wait for the page to load. This method is an alias for navigation_timeout.
    # A timeout error is displayed when this time elapses. The default value is 30 seconds. Use a larger value (up to 120 seconds allowed) for pages that take a long time to load.
    #
    # @param max_load_time Timeout in seconds.
    def max_load_time=(max_load_time)
      @parameters['max_load_time'] = max_load_time
    end

    # Set the maximum amount of time (in seconds) that the convert will wait for the page to load. This method is an alias for max_load_time.
    # A timeout error is displayed when this time elapses. The default value is 30 seconds. Use a larger value (up to 120 seconds allowed) for pages that take a long time to load.
    #
    # @param navigation_timeout Timeout in seconds.
    def navigation_timeout=(navigation_timeout)
      self.max_load_time = navigation_timeout
    end

    # Set the protocol used for secure (HTTPS) connections. Set this only if you have an older server that only works with older SSL connections.
    #
    # @param secure_protocol Secure protocol. Possible values: 0 (TLS 1.1 or newer), 1 (TLS 1.0), 2 (SSL v3 only). Use constants from SelectPdf::SecureProtocol class.
    def secure_protocol=(secure_protocol)
      unless [0, 1, 2].include?(secure_protocol)
        raise ApiException.new('Allowed values for Secure Protocol: 0 (TLS 1.1 or newer), 1 (TLS 1.0), 2 (SSL v3 only).'), 'Allowed values for Secure Protocol: 0 (TLS 1.1 or newer), 1 (TLS 1.0), 2 (SSL v3 only).'
      end

      @parameters['protocol'] = secure_protocol
    end

    # Specify if the CSS Print media type is used instead of the Screen media type. The default value is FALSE.
    #
    # @param use_css_print Use CSS Print media or not.
    def use_css_print=(use_css_print)
      @parameters['use_css_print'] = use_css_print
    end

    # Specify the background color of the PDF page in RGB html format. The default is #FFFFFF.
    #
    # @param background_color Background color in #RRGGBB format.
    def background_color=(background_color)
      unless /^#?[0-9a-fA-F]{6}$/.match(background_color)
        raise ApiException.new('Color value must be in #RRGGBB format.'), 'Color value must be in #RRGGBB format.'
      end

      @parameters['background_color'] = background_color
    end

    # Set a flag indicating if the web page background is rendered in PDF. The default value is TRUE.
    #
    # @param draw_html_background Draw the HTML background or not.
    def draw_html_background=(draw_html_background)
      @parameters['draw_html_background'] = draw_html_background
    end

    # Do not run JavaScript in web pages. The default value is False and javascript is executed.
    #
    # @param disable_javascript Disable javascript or not.
    def disable_javascript=(disable_javascript)
      @parameters['disable_javascript'] = disable_javascript
    end

    # Do not create internal links in the PDF. The default value is False and internal links are created.
    #
    # @param disable_internal_links Disable internal links or not.
    def disable_internal_links=(disable_internal_links)
      @parameters['disable_internal_links'] = disable_internal_links
    end

    # Do not create external links in the PDF. The default value is False and external links are created.
    #
    # @param disable_external_links Disable external links or not.
    def disable_external_links=(disable_external_links)
      @parameters['disable_external_links'] = disable_external_links
    end

    # Try to render the PDF even in case of the web page loading timeout. The default value is False and an exception is raised in case of web page navigation timeout.
    #
    # @param render_on_timeout Render in case of timeout or not.
    def render_on_timeout=(render_on_timeout)
      @parameters['render_on_timeout'] = render_on_timeout
    end

    # Avoid breaking images between PDF pages. The default value is False and images are split between pages if larger.
    #
    # @param keep_images_together Try to keep images on same page or not.
    def keep_images_together=(keep_images_together)
      @parameters['keep_images_together'] = keep_images_together
    end

    # Set the PDF document title.
    #
    # @param doc_title Document title.
    def doc_title=(doc_title)
      @parameters['doc_title'] = doc_title
    end

    # Set the subject of the PDF document.
    #
    # @param doc_subject Document subject.
    def doc_subject=(doc_subject)
      @parameters['doc_subject'] = doc_subject
    end

    # Set the PDF document keywords.
    #
    # @param doc_keywords Document keywords.
    def doc_keywords=(doc_keywords)
      @parameters['doc_keywords'] = doc_keywords
    end

    # Set the name of the PDF document author.
    #
    # @param doc_author Document author.
    def doc_author=(doc_author)
      @parameters['doc_author'] = doc_author
    end

    # Add the date and time when the PDF document was created to the PDF document information. The default value is False.
    #
    # @param doc_add_creation_date Add creation date to the document metadata or not.
    def doc_add_creation_date=(doc_add_creation_date)
      @parameters['doc_add_creation_date'] = doc_add_creation_date
    end

    # Set the page layout to be used when the document is opened in a PDF viewer. The default value is SelectPdf::PageLayout::ONE_COLUMN.
    #
    # @param viewer_page_layout Page layout. Possible values: 0 (Single Page), 1 (One Column), 2 (Two Column Left), 3 (Two Column Right).
    # Use constants from SelectPdf::PageLayout class.
    def viewer_page_layout=(viewer_page_layout)
      unless [0, 1, 2, 3].include?(viewer_page_layout)
        raise ApiException.new('Allowed values for Page Layout: 0 (Single Page), 1 (One Column), 2 (Two Column Left), 3 (Two Column Right).'), 'Allowed values for Page Layout: 0 (Single Page), 1 (One Column), 2 (Two Column Left), 3 (Two Column Right).'
      end

      @parameters['viewer_page_layout'] = viewer_page_layout
    end

    # Set the document page mode when the pdf document is opened in a PDF viewer. The default value is SelectPdf::PageMode::USE_NONE.
    #
    # @param viewer_page_mode Page mode. Possible values: 0 (Use None), 1 (Use Outlines), 2 (Use Thumbs), 3 (Full Screen), 4 (Use OC), 5 (Use Attachments).
    # Use constants from SelectPdf::PageMode class.
    def viewer_page_mode=(viewer_page_mode)
      unless [0, 1, 2, 3, 4, 5].include?(viewer_page_mode)
        raise ApiException.new('Allowed values for Page Mode: 0 (Use None), 1 (Use Outlines), 2 (Use Thumbs), 3 (Full Screen), 4 (Use OC), 5 (Use Attachments).'),
              'Allowed values for Page Mode: 0 (Use None), 1 (Use Outlines), 2 (Use Thumbs), 3 (Full Screen), 4 (Use OC), 5 (Use Attachments).'
      end

      @parameters['viewer_page_mode'] = viewer_page_mode
    end

    # Set a flag specifying whether to position the document's window in the center of the screen. The default value is False.
    #
    # @param viewer_center_window Center window or not.
    def viewer_center_window=(viewer_center_window)
      @parameters['viewer_center_window'] = viewer_center_window
    end

    # Set a flag specifying whether the window's title bar should display the document title taken from document information. The default value is False.
    #
    # @param viewer_display_doc_title Display title or not.
    def viewer_display_doc_title=(viewer_display_doc_title)
      @parameters['viewer_display_doc_title'] = viewer_display_doc_title
    end

    # Set a flag specifying whether to resize the document's window to fit the size of the first displayed page. The default value is False.
    #
    # @param viewer_fit_window Fit window or not.
    def viewer_fit_window=(viewer_fit_window)
      @parameters['viewer_fit_window'] = viewer_fit_window
    end

    # Set a flag specifying whether to hide the pdf viewer application's menu bar when the document is active. The default value is False.
    #
    # @param viewer_hide_menu_bar Hide menu bar or not.
    def viewer_hide_menu_bar=(viewer_hide_menu_bar)
      @parameters['viewer_hide_menu_bar'] = viewer_hide_menu_bar
    end

    # Set a flag specifying whether to hide the pdf viewer application's tool bars when the document is active. The default value is False.
    #
    # @param viewer_hide_toolbar Hide tool bars or not.
    def viewer_hide_toolbar=(viewer_hide_toolbar)
      @parameters['viewer_hide_toolbar'] = viewer_hide_toolbar
    end

    # Set a flag specifying whether to hide user interface elements in the document's window (such as scroll bars and navigation controls), leaving only the document's contents displayed.
    #
    # @param viewer_hide_window_ui Hide window UI or not.
    def viewer_hide_window_ui=(viewer_hide_window_ui)
      @parameters['viewer_hide_window_ui'] = viewer_hide_window_ui
    end

    # Control if a custom header is displayed in the generated PDF document. The default value is False.
    #
    # @param show_header Show header or not.
    def show_header=(show_header)
      @parameters['show_header'] = show_header
    end

    # The height of the pdf document header. This height is specified in points. 1 point is 1/72 inch. The default value is 50.
    #
    # @param header_height Header height.
    def header_height=(header_height)
      @parameters['header_height'] = header_height
    end

    # Set the url of the web page that is converted and rendered in the PDF document header.
    #
    # @param header_url The url of the web page that is converted and rendered in the pdf document header.
    def header_url=(header_url)
      if !header_url.downcase.start_with?('http://') && !header_url.downcase.start_with?('https://')
        raise ApiException.new('The supported protocols for the converted webpage are http:// and https://.'), 'The supported protocols for the converted webpage are http:// and https://.'
      end

      if header_url.downcase.start_with?('http://localhost')
        raise ApiException.new('Cannot convert local urls. SelectPdf online API can only convert publicly available urls.'), 'Cannot convert local urls. SelectPdf online API can only convert publicly available urls.'
      end

      @parameters['header_url'] = header_url
    end

    # Set the raw html that is converted and rendered in the pdf document header.
    #
    # @param header_html The raw html that is converted and rendered in the pdf document header.
    def header_html=(header_html)
      @parameters['header_html'] = header_html
    end

    # Set an optional base url parameter can be used together with the header HTML to resolve relative paths from the html string.
    #
    # @param header_base_url Header base url.
    def header_base_url=(header_base_url)
      if !header_base_url.downcase.start_with?('http://') && !header_base_url.downcase.start_with?('https://')
        raise ApiException.new('The supported protocols for the converted webpage are http:// and https://.'), 'The supported protocols for the converted webpage are http:// and https://.'
      end

      if header_base_url.downcase.start_with?('http://localhost')
        raise ApiException.new('Cannot convert local urls. SelectPdf online API can only convert publicly available urls.'), 'Cannot convert local urls. SelectPdf online API can only convert publicly available urls.'
      end

      @parameters['header_base_url'] = header_base_url
    end

    # Control the visibility of the header on the first page of the generated pdf document. The default value is True.
    #
    # @param header_display_on_first_page Display header on the first page or not.
    def header_display_on_first_page=(header_display_on_first_page)
      @parameters['header_display_on_first_page'] = header_display_on_first_page
    end

    # Control the visibility of the header on the odd numbered pages of the generated pdf document. The default value is True.
    #
    # @param header_display_on_odd_pages Display header on odd pages or not.
    def header_display_on_odd_pages=(header_display_on_odd_pages)
      @parameters['header_display_on_odd_pages'] = header_display_on_odd_pages
    end

    # Control the visibility of the header on the even numbered pages of the generated pdf document. The default value is True.
    #
    # @param header_display_on_even_pages Display header on even pages or not.
    def header_display_on_even_pages=(header_display_on_even_pages)
      @parameters['header_display_on_even_pages'] = header_display_on_even_pages
    end

    # Set the width in pixels used by the converter's internal browser window during the conversion of the header content. The default value is 1024px.
    #
    # @param header_web_page_width Browser window width in pixels.
    def header_web_page_width=(header_web_page_width)
      @parameters['header_web_page_width'] = header_web_page_width
    end

    # Set the height in pixels used by the converter's internal browser window during the conversion of the header content.
    # The default value is 0px and it means that the page height is automatically calculated by the converter.
    #
    # @param header_web_page_height Browser window height in pixels. Set it to 0px to automatically calculate page height.
    def header_web_page_height=(header_web_page_height)
      @parameters['header_web_page_height'] = header_web_page_height
    end

    # Control if a custom footer is displayed in the generated PDF document. The default value is False.
    #
    # @param show_footer Show footer or not.
    def show_footer=(show_footer)
      @parameters['show_footer'] = show_footer
    end

    # The height of the pdf document footer. This height is specified in points. 1 point is 1/72 inch. The default value is 50.
    #
    # @param footer_height Footer height.
    def footer_height=(footer_height)
      @parameters['footer_height'] = footer_height
    end

    # Set the url of the web page that is converted and rendered in the PDF document footer.
    #
    # @param footer_url The url of the web page that is converted and rendered in the pdf document footer.
    def footer_url=(footer_url)
      if !footer_url.downcase.start_with?('http://') && !footer_url.downcase.start_with?('https://')
        raise ApiException.new('The supported protocols for the converted webpage are http:// and https://.'), 'The supported protocols for the converted webpage are http:// and https://.'
      end

      if footer_url.downcase.start_with?('http://localhost')
        raise ApiException.new('Cannot convert local urls. SelectPdf online API can only convert publicly available urls.'), 'Cannot convert local urls. SelectPdf online API can only convert publicly available urls.'
      end

      @parameters['footer_url'] = footer_url
    end

    # Set the raw html that is converted and rendered in the pdf document footer.
    #
    # @param footer_html The raw html that is converted and rendered in the pdf document footer.
    def footer_html=(footer_html)
      @parameters['footer_html'] = footer_html
    end

    # Set an optional base url parameter can be used together with the footer HTML to resolve relative paths from the html string.
    #
    # @param footer_base_url Footer base url.
    def footer_base_url=(footer_base_url)
      if !footer_base_url.downcase.start_with?('http://') && !footer_base_url.downcase.start_with?('https://')
        raise ApiException.new('The supported protocols for the converted webpage are http:// and https://.'), 'The supported protocols for the converted webpage are http:// and https://.'
      end

      if footer_base_url.downcase.start_with?('http://localhost')
        raise ApiException.new('Cannot convert local urls. SelectPdf online API can only convert publicly available urls.'), 'Cannot convert local urls. SelectPdf online API can only convert publicly available urls.'
      end

      @parameters['footer_base_url'] = footer_base_url
    end

    # Control the visibility of the footer on the first page of the generated pdf document. The default value is True.
    #
    # @param footer_display_on_first_page Display footer on the first page or not.
    def footer_display_on_first_page=(footer_display_on_first_page)
      @parameters['footer_display_on_first_page'] = footer_display_on_first_page
    end

    # Control the visibility of the footer on the odd numbered pages of the generated pdf document. The default value is True.
    #
    # @param footer_display_on_odd_pages Display footer on odd pages or not.
    def footer_display_on_odd_pages=(footer_display_on_odd_pages)
      @parameters['footer_display_on_odd_pages'] = footer_display_on_odd_pages
    end

    # Control the visibility of the footer on the even numbered pages of the generated pdf document. The default value is True.
    #
    # @param footer_display_on_even_pages Display footer on even pages or not.
    def footer_display_on_even_pages=(footer_display_on_even_pages)
      @parameters['footer_display_on_even_pages'] = footer_display_on_even_pages
    end

    # Add a special footer on the last page of the generated pdf document only. The default value is False.
    # Use footer_url or footer_html and footer_base_url to specify the content of the last page footer.
    # Use footer_height to specify the height of the special last page footer.
    #
    # @param footer_display_on_last_page Display special footer on the last page or not.
    def footer_display_on_last_page=(footer_display_on_last_page)
      @parameters['footer_display_on_last_page'] = footer_display_on_last_page
    end

    # Set the width in pixels used by the converter's internal browser window during the conversion of the footer content. The default value is 1024px.
    #
    # @param footer_web_page_width Browser window width in pixels.
    def footer_web_page_width=(footer_web_page_width)
      @parameters['footer_web_page_width'] = footer_web_page_width
    end

    # Set the height in pixels used by the converter's internal browser window during the conversion of the footer content.
    # The default value is 0px and it means that the page height is automatically calculated by the converter.
    #
    # @param footer_web_page_height Browser window height in pixels. Set it to 0px to automatically calculate page height.
    def footer_web_page_height=(footer_web_page_height)
      @parameters['footer_web_page_height'] = footer_web_page_height
    end

    # Show page numbers. Default value is True. Page numbers will be displayed in the footer of the PDF document.
    #
    # @param page_numbers Show page numbers or not.
    def page_numbers=(page_numbers)
      @parameters['page_numbers'] = page_numbers
    end

    # Control the page number for the first page being rendered. The default value is 1.
    #
    # @param page_numbers_first First page number.
    def page_numbers_first=(page_numbers_first)
      @parameters['page_numbers_first'] = page_numbers_first
    end

    # Control the total number of pages offset in the generated pdf document. The default value is 0.
    #
    # @param page_numbers_offset Offset for the total number of pages in the generated pdf document.
    def page_numbers_offset=(page_numbers_offset)
      @parameters['page_numbers_offset'] = page_numbers_offset
    end

    # Set the text that is used to display the page numbers.
    # It can contain the placeholder \\{page_number} for the current page number and \\{total_pages} for the total number of pages.
    # The default value is "Page: \\{page_number} of \\{total_pages}".
    #
    # @param page_numbers_template Page numbers template.
    def page_numbers_template=(page_numbers_template)
      @parameters['page_numbers_template'] = page_numbers_template
    end

    # Set the font used to display the page numbers text. The default value is "Helvetica".
    #
    # @param page_numbers_font_name The font used to display the page numbers text.
    def page_numbers_font_name=(page_numbers_font_name)
      @parameters['page_numbers_font_name'] = page_numbers_font_name
    end

    # Set the size of the font used to display the page numbers. The default value is 10 points.
    #
    # @param page_numbers_font_size The size in points of the font used to display the page numbers.
    def page_numbers_font_size=(page_numbers_font_size)
      @parameters['page_numbers_font_size'] = page_numbers_font_size
    end

    # Set the alignment of the page numbers text. The default value is SelectPdf::PageNumbersAlignment::RIGHT.
    #
    # @param page_numbers_alignment The alignment of the page numbers text.
    def page_numbers_alignment=(page_numbers_alignment)
      unless [1, 2, 3].include?(page_numbers_alignment)
        raise ApiException.new('Allowed values for Page Numbers Alignment: 1 (Left), 2 (Center), 3 (Right).'),
              'Allowed values for Page Numbers Alignment: 1 (Left), 2 (Center), 3 (Right).'
      end

      @parameters['page_numbers_alignment'] = page_numbers_alignment
    end

    # Specify the color of the page numbers text in #RRGGBB html format. The default value is #333333.
    #
    # @param page_numbers_color Page numbers color.
    def page_numbers_color=(page_numbers_color)
      unless /^#?[0-9a-fA-F]{6}$/.match(page_numbers_color)
        raise ApiException.new('Color value must be in #RRGGBB format.'), 'Color value must be in #RRGGBB format.'
      end

      @parameters['page_numbers_color'] = page_numbers_color
    end

    # Specify the position in points on the vertical where the page numbers text is displayed in the footer. The default value is 10 points.
    #
    # @param page_numbers_pos_y Page numbers Y position in points.
    def page_numbers_pos_y=(page_numbers_pos_y)
      @parameters['page_numbers_pos_y'] = page_numbers_pos_y
    end

    # Generate automatic bookmarks in pdf. The elements that will be bookmarked are defined using CSS selectors.
    # For example, the selector for all the H1 elements is "H1", the selector for all the elements with the CSS class name 'myclass' is "*.myclass" and
    # the selector for the elements with the id 'myid' is "*#myid". Read more about CSS selectors <a href="http://www.w3schools.com/cssref/css_selectors.asp" target="_blank">here</a>.
    #
    # @param pdf_bookmarks_selectors CSS selectors used to identify HTML elements, comma separated.
    def pdf_bookmarks_selectors=(pdf_bookmarks_selectors)
      @parameters['pdf_bookmarks_selectors'] = pdf_bookmarks_selectors
    end

    # Exclude page elements from the conversion. The elements that will be excluded are defined using CSS selectors.
    # For example, the selector for all the H1 elements is "H1", the selector for all the elements with the CSS class name 'myclass' is "*.myclass" and
    # the selector for the elements with the id 'myid' is "*#myid". Read more about CSS selectors <a href="http://www.w3schools.com/cssref/css_selectors.asp" target="_blank">here</a>.
    #
    # @param pdf_hide_elements CSS selectors used to identify HTML elements, comma separated.
    def pdf_hide_elements=(pdf_hide_elements)
      @parameters['pdf_hide_elements'] = pdf_hide_elements
    end

    # Convert only a specific section of the web page to pdf. 
    # The section that will be converted to pdf is specified by the html element ID.
    # The element can be anything (image, table, table row, div, text, etc).
    #
    # @param pdf_show_only_element_id HTML element ID.
    def pdf_show_only_element_id=(pdf_show_only_element_id)
      @parameters['pdf_show_only_element_id'] = pdf_show_only_element_id
    end

    # Get the locations of page elements from the conversion. The elements that will have their locations retrieved are defined using CSS selectors.
    # For example, the selector for all the H1 elements is "H1", the selector for all the elements with the CSS class name 'myclass' is "*.myclass" and
    # the selector for the elements with the id 'myid' is "*#myid". Read more about CSS selectors <a href="http://www.w3schools.com/cssref/css_selectors.asp" target="_blank">here</a>.
    #
    # @param pdf_web_elements_selectors CSS selectors used to identify HTML elements, comma separated.
    def pdf_web_elements_selectors=(pdf_web_elements_selectors)
      @parameters['pdf_web_elements_selectors'] = pdf_web_elements_selectors
    end

    # Set converter startup mode. The default value is SelectPdf::StartupMode::AUTOMATIC and the conversion is started immediately.
    # By default this is set to SelectPdf::StartupMode::AUTOMATIC and the conversion is started as soon as the page loads (and conversion delay set with conversion_delay elapses).
    # If set to SelectPdf::StartupMode::MANUAL, the conversion is started only by a javascript call to SelectPdf.startConversion() from within the web page.
    #
    # @param startup_mode Converter startup mode.
    def startup_mode=(startup_mode)
      unless /(?i)^(Automatic|Manual)$/.match(startup_mode)
        raise ApiException.new('Allowed values for Startup Mode: Automatic, Manual.'), 'Allowed values for Startup Mode: Automatic, Manual.'
      end

      @parameters['startup_mode'] = startup_mode
    end

    # Internal use only.
    #
    # @param skip_decoding The default value is True.
    def skip_decoding=(skip_decoding)
      @parameters['skip_decoding'] = skip_decoding
    end

    # Set a flag indicating if the images from the page are scaled during the conversion process. The default value is False and images are not scaled.
    #
    # @param scale_images Scale images or not.
    def scale_images=(scale_images)
      @parameters['scale_images'] = scale_images
    end

    # Generate a single page PDF. The converter will automatically resize the PDF page to fit all the content in a single page.
    # The default value of this property is False and the PDF will contain several pages if the content is large.
    #
    # @param single_page_pdf Generate a single page PDF or not.
    def single_page_pdf=(single_page_pdf)
      @parameters['single_page_pdf'] = single_page_pdf
    end

    # Get or set a flag indicating if an enhanced custom page breaks algorithm is used.
    # The enhanced algorithm is a little bit slower but it will prevent the appearance of hidden text in the PDF when custom page breaks are used.
    # The default value for this property is False.
    #
    # @param page_breaks_enhanced_algorithm Enable enhanced page breaks algorithm or not.
    def page_breaks_enhanced_algorithm=(page_breaks_enhanced_algorithm)
      @parameters['page_breaks_enhanced_algorithm'] = page_breaks_enhanced_algorithm
    end

    # Set HTTP cookies for the web page being converted.
    #
    # @param cookies HTTP cookies that will be sent to the page being converted.
    def cookies=(cookies)
      @parameters['cookies_string'] = URI.encode_www_form(cookies)
    end

    # Set a custom parameter. Do not use this method unless advised by SelectPdf.
    #
    # @param parameter_name Parameter name.
    # @param parameter_value Parameter value.
    def set_custom_parameter(parameter_name, parameter_value)
      @parameters[parameter_name] = parameter_value
    end

    # Get the locations of certain web elements. This is retrieved if pdf_web_elements_selectors parameter is set and elements were found to match the selectors.
    #
    # @return List of web elements locations.
    def web_elements
      web_elements_client = WebElementsClient.new(@parameters['key'], @job_id)
      web_elements_client.api_endpoint = @api_web_elements_endpoint

      web_elements_client.web_elements
    end
  end

  # Get the locations of certain web elements.
  # This is retrieved if pdf_web_elements_selectors parameter was set during the initial conversion call and elements were found to match the selectors.
  class WebElementsClient < ApiClient
    # Construct the web elements client.
    #
    # @param api_key API Key.
    # @param job_id Job ID.
    def initialize(api_key, job_id)
      super()
      @api_endpoint = 'https://selectpdf.com/api2/webelements/'
      @parameters['key'] = api_key
      @parameters['job_id'] = job_id
    end

    # Get the locations of certain web elements.
    # This is retrieved if pdf_web_elements_selectors parameter is set and elements were found to match the selectors.
    #
    # @return List of web elements locations.
    def web_elements
      @headers['Accept'] = 'text/json'

      result = perform_post
      return JSON.parse(result) unless result.nil? || result.empty?

      []
    end
  end

  # Get the result of an asynchronous call.
  class AsyncJobClient < ApiClient
    # Construct the async job client.
    #
    # @param api_key API Key.
    # @param job_id Job ID.
    def initialize(api_key, job_id)
      super()
      @api_endpoint = 'https://selectpdf.com/api2/asyncjob/'
      @parameters['key'] = api_key
      @parameters['job_id'] = job_id
    end

    # Get result of the asynchronous job.
    #
    # @return Byte array containing the resulted file if the job is finished. Returns nil if the job is still running. Throws an exception if an error occurred.
    def result
      result = perform_post

      return result if @job_id.nil? || @job_id.empty?

      return nil
    end
  end

  # Pdf Merge with SelectPdf Online API.
  #
  # Code sample:
  #
  #  require 'selectpdf'
  #
  #  $stdout.sync = true
  #  
  #  print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"
  #  
  #  test_url = 'https://selectpdf.com/demo/files/selectpdf.pdf'
  #  test_pdf = 'Input.pdf'
  #  local_file = 'Result.pdf'
  #  api_key = 'Your API key here'
  #  
  #  begin
  #    client = SelectPdf::PdfMergeClient.new(api_key)
  #  
  #    # set parameters - see full list at https://selectpdf.com/pdf-merge-api/
  #  
  #    # specify the pdf files that will be merged (order will be preserved in the final pdf)
  #    client.add_file(test_pdf) # add PDF from local file
  #    client.add_url_file(test_url) # add PDF from public url
  #    # client.add_file(test_pdf, 'pdf_password') # add PDF (that requires a password) from local file
  #    # client.add_url_file(test_url, 'pdf_password') # add PDF (that requires a password) from public url
  #  
  #    print "Starting pdf merge ...\n"
  #  
  #    # merge pdfs to local file
  #    client.save_to_file(local_file)
  #  
  #    # merge pdfs to memory
  #    # pdf = client.save
  #  
  #    print "Finished! Number of pages: #{client.number_of_pages}.\n"
  #  
  #    # get API usage
  #    usage_client = SelectPdf::UsageClient.new(api_key)
  #    usage = usage_client.get_usage(FALSE)
  #    print("Usage: #{usage}\n")
  #    print('Conversions remained this month: ', usage['available'], "\n")
  #  rescue SelectPdf::ApiException => e
  #    print("An error occurred: #{e}")
  #  end
  class PdfMergeClient < ApiClient
    # Construct the Pdf Merge Client.
    #
    # @param api_key API Key.
    def initialize(api_key)
      super()
      @api_endpoint = 'https://selectpdf.com/api2/pdfmerge/'
      @parameters['key'] = api_key

      @file_idx = 0
    end

    # Add local PDF document to the list of input files.
    #
    # @param input_pdf Path to a local PDF file.
    # @param user_password User password for the PDF document (optional).
    def add_file(input_pdf, user_password = nil)
      @file_idx += 1

      @files["file_#{@file_idx}"] = input_pdf
      @parameters.delete("url_#{@file_idx}")

      if user_password.nil? || user_password.empty?
        @parameters.delete("password_#{@file_idx}")
      else
        @parameters["password_#{@file_idx}"] = user_password
      end
    end

    # Add remote PDF document to the list of input files.
    #
    # @param input_url Url of a remote PDF file.
    # @param user_password User password for the PDF document (optional).
    def add_url_file(input_url, user_password = nil)
      @file_idx += 1

      @parameters["url_#{@file_idx}"] = input_url
      @files.delete("file_#{@file_idx}")

      if user_password.nil? || user_password.empty?
        @parameters.delete("password_#{@file_idx}")
      else
        @parameters["password_#{@file_idx}"] = user_password
      end
    end

    # Merge all specified input pdfs and return the resulted PDF.
    #
    # @return Byte array containing the resulted PDF.
    def save
      @parameters['async'] = 'False'
      @parameters['files_no'] = @file_idx

      result = perform_post_as_multipart_formdata

      @file_idx = 0
      @files = {}

      result
    end

    # Merge all specified input pdfs and writes the resulted PDF to a specified stream.
    #
    # @param stream The output stream where the resulted PDF will be written.
    def save_to_stream(stream)
      result = save
      stream.write(result)
    end

    # Merge all specified input pdfs and writes the resulted PDF to a local file.
    #
    # @param file_path Local file including path if necessary.
    def save_to_file(file_path)
      result = save
      File.open(file_path, 'wb') do |file|
        file.write(result)
      end
    rescue ApiException
      FileUtils.rm(file_path) if File.exist?(file_path)
      raise
    end

    # Merge all specified input pdfs and return the resulted PDF. An asynchronous call is used.
    #
    # @return Byte array containing the resulted PDF.
    def save_async
      @parameters['files_no'] = @file_idx

      job_id = start_async_job_multipart_form_data

      if job_id.nil? || job_id.empty?
        raise ApiException.new('An error occurred launching the asynchronous call.'), 'An error occurred launching the asynchronous call.'
      end

      no_pings = 0

      while no_pings < @async_calls_max_pings
        no_pings += 1

        # sleep for a few seconds before next ping
        sleep(@async_calls_ping_interval)

        async_job_client = AsyncJobClient.new(@parameters['key'], @job_id)
        async_job_client.api_endpoint = @api_async_endpoint

        result = async_job_client.result

        next if result.nil?

        @number_of_pages = async_job_client.number_of_pages
        @file_idx = 0
        @files = {}

        return result
      end

      @file_idx = 0
      @files = {}

      raise ApiException.new('Asynchronous call did not finish in expected timeframe.'), 'Asynchronous call did not finish in expected timeframe.'
    end

    # Merge all specified input pdfs and writes the resulted PDF to a specified stream. An asynchronous call is used.
    #
    # @param stream The output stream where the resulted PDF will be written.
    def save_to_stream_async(stream)
      result = save_async
      stream.write(result)
    end

    # Merge all specified input pdfs and writes the resulted PDF to a local file. An asynchronous call is used.
    #
    # @param file_path Local file including path if necessary.
    def save_to_file_async(file_path)
      result = save_async
      File.open(file_path, 'wb') do |file|
        file.write(result)
      end
    rescue ApiException
      FileUtils.rm(file_path) if File.exist?(file_path)
      raise
    end

    # Set the PDF document title.
    #
    # @param doc_title Document title.
    def doc_title=(doc_title)
      @parameters['doc_title'] = doc_title
    end

    # Set the subject of the PDF document.
    #
    # @param doc_subject Document subject.
    def doc_subject=(doc_subject)
      @parameters['doc_subject'] = doc_subject
    end

    # Set the PDF document keywords.
    #
    # @param doc_keywords Document keywords.
    def doc_keywords=(doc_keywords)
      @parameters['doc_keywords'] = doc_keywords
    end

    # Set the name of the PDF document author.
    #
    # @param doc_author Document author.
    def doc_author=(doc_author)
      @parameters['doc_author'] = doc_author
    end

    # Add the date and time when the PDF document was created to the PDF document information. The default value is False.
    #
    # @param doc_add_creation_date Add creation date to the document metadata or not.
    def doc_add_creation_date=(doc_add_creation_date)
      @parameters['doc_add_creation_date'] = doc_add_creation_date
    end

    # Set the page layout to be used when the document is opened in a PDF viewer. The default value is SelectPdf::PageLayout::ONE_COLUMN.
    #
    # @param viewer_page_layout Page layout. Possible values: 0 (Single Page), 1 (One Column), 2 (Two Column Left), 3 (Two Column Right).
    # Use constants from SelectPdf::PageLayout class.
    def viewer_page_layout=(viewer_page_layout)
      unless [0, 1, 2, 3].include?(viewer_page_layout)
        raise ApiException.new('Allowed values for Page Layout: 0 (Single Page), 1 (One Column), 2 (Two Column Left), 3 (Two Column Right).'), 'Allowed values for Page Layout: 0 (Single Page), 1 (One Column), 2 (Two Column Left), 3 (Two Column Right).'
      end

      @parameters['viewer_page_layout'] = viewer_page_layout
    end

    # Set the document page mode when the pdf document is opened in a PDF viewer. The default value is SelectPdf::PageMode::USE_NONE.
    #
    # @param viewer_page_mode Page mode. Possible values: 0 (Use None), 1 (Use Outlines), 2 (Use Thumbs), 3 (Full Screen), 4 (Use OC), 5 (Use Attachments).
    # Use constants from SelectPdf::PageMode class.
    def viewer_page_mode=(viewer_page_mode)
      unless [0, 1, 2, 3, 4, 5].include?(viewer_page_mode)
        raise ApiException.new('Allowed values for Page Mode: 0 (Use None), 1 (Use Outlines), 2 (Use Thumbs), 3 (Full Screen), 4 (Use OC), 5 (Use Attachments).'),
              'Allowed values for Page Mode: 0 (Use None), 1 (Use Outlines), 2 (Use Thumbs), 3 (Full Screen), 4 (Use OC), 5 (Use Attachments).'
      end

      @parameters['viewer_page_mode'] = viewer_page_mode
    end

    # Set a flag specifying whether to position the document's window in the center of the screen. The default value is False.
    #
    # @param viewer_center_window Center window or not.
    def viewer_center_window=(viewer_center_window)
      @parameters['viewer_center_window'] = viewer_center_window
    end

    # Set a flag specifying whether the window's title bar should display the document title taken from document information. The default value is False.
    #
    # @param viewer_display_doc_title Display title or not.
    def viewer_display_doc_title=(viewer_display_doc_title)
      @parameters['viewer_display_doc_title'] = viewer_display_doc_title
    end

    # Set a flag specifying whether to resize the document's window to fit the size of the first displayed page. The default value is False.
    #
    # @param viewer_fit_window Fit window or not.
    def viewer_fit_window=(viewer_fit_window)
      @parameters['viewer_fit_window'] = viewer_fit_window
    end

    # Set a flag specifying whether to hide the pdf viewer application's menu bar when the document is active. The default value is False.
    #
    # @param viewer_hide_menu_bar Hide menu bar or not.
    def viewer_hide_menu_bar=(viewer_hide_menu_bar)
      @parameters['viewer_hide_menu_bar'] = viewer_hide_menu_bar
    end

    # Set a flag specifying whether to hide the pdf viewer application's tool bars when the document is active. The default value is False.
    #
    # @param viewer_hide_toolbar Hide tool bars or not.
    def viewer_hide_toolbar=(viewer_hide_toolbar)
      @parameters['viewer_hide_toolbar'] = viewer_hide_toolbar
    end

    # Set a flag specifying whether to hide user interface elements in the document's window (such as scroll bars and navigation controls), leaving only the document's contents displayed.
    #
    # @param viewer_hide_window_ui Hide window UI or not.
    def viewer_hide_window_ui=(viewer_hide_window_ui)
      @parameters['viewer_hide_window_ui'] = viewer_hide_window_ui
    end

    # Set PDF user password.
    #
    # @param user_password PDF user password.
    def user_password=(user_password)
      @parameters['user_password'] = user_password
    end

    # Set PDF owner password.
    #
    # @param owner_password PDF owner password.
    def owner_password=(owner_password)
      @parameters['owner_password'] = owner_password
    end

    # Set the maximum amount of time (in seconds) for this job.
    # The default value is 30 seconds. Use a larger value (up to 120 seconds allowed) for large documents.
    #
    # @param timeout Timeout in seconds.
    def timeout=(timeout)
      @parameters['timeout'] = timeout
    end

    # Set a custom parameter. Do not use this method unless advised by SelectPdf.
    #
    # @param parameter_name Parameter name.
    # @param parameter_value Parameter value.
    def set_custom_parameter(parameter_name, parameter_value)
      @parameters[parameter_name] = parameter_value
    end
  end

  # Pdf To Text Conversion with SelectPdf Online API.
  #
  # Code Sample for PDF To Text
  #
  #  require 'selectpdf'
  #
  #  $stdout.sync = true
  #
  #  print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"
  #
  #  test_url = 'https://selectpdf.com/demo/files/selectpdf.pdf'
  #  test_pdf = 'Input.pdf'
  #  local_file = 'Result.txt'
  #  api_key = 'Your API key here'
  #
  #  begin
  #    client = SelectPdf::PdfToTextClient.new(api_key)
  #
  #    # set parameters - see full list at https://selectpdf.com/pdf-to-text-api/
  #    client.start_page = 1 # start page (processing starts from here)
  #    client.end_page = 0 # end page (set 0 to process file til the end)
  #    client.output_format = SelectPdf::OutputFormat::TEXT # set output format (Text or HTML)
  #
  #    print "Starting pdf to text ...\n"
  #
  #    # convert local pdf to local text file
  #    client.text_from_file_to_file(test_pdf, local_file)
  #
  #    # extract text from local pdf to memory
  #    # text = client.text_from_file(test_pdf)
  #    # print text
  #
  #    # convert pdf from public url to local text file
  #    # client.text_from_url_to_file(test_url, local_file)
  #
  #    # extract text from pdf from public url to memory
  #    # text = client.text_from_url(test_url)
  #    # print text
  #
  #    print "Finished! Number of pages processed: #{client.number_of_pages}.\n"
  #
  #    # get API usage
  #    usage_client = SelectPdf::UsageClient.new(api_key)
  #    usage = usage_client.get_usage(FALSE)
  #    print("Usage: #{usage}\n")
  #    print('Conversions remained this month: ', usage['available'], "\n")
  #  rescue SelectPdf::ApiException => e
  #    print("An error occurred: #{e}")
  #  end
  #
  # Code Sample for Search Pdf
  #
  #    require 'selectpdf'
  #
  #    $stdout.sync = true
  #    
  #    print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"
  #    
  #    test_url = 'https://selectpdf.com/demo/files/selectpdf.pdf'
  #    test_pdf = 'Input.pdf'
  #    api_key = 'Your API key here'
  #    
  #    begin
  #      client = SelectPdf::PdfToTextClient.new(api_key)
  #    
  #      # set parameters - see full list at https://selectpdf.com/pdf-to-text-api/
  #      client.start_page = 1 # start page (processing starts from here)
  #      client.end_page = 0 # end page (set 0 to process file til the end)
  #      client.output_format = SelectPdf::OutputFormat::TEXT # set output format (Text or HTML)
  #    
  #      print "Starting search pdf ...\n"
  #    
  #      # search local pdf
  #      results = client.search_file(test_pdf, 'pdf')
  #    
  #      # search pdf from public url
  #      # results = client.search_url(test_url, 'pdf')
  #    
  #      print "Search results: #{results}.\nSearch results count: #{results.length}\n"
  #    
  #      print "Finished! Number of pages processed: #{client.number_of_pages}.\n"
  #    
  #      # get API usage
  #      usage_client = SelectPdf::UsageClient.new(api_key)
  #      usage = usage_client.get_usage(FALSE)
  #      print("Usage: #{usage}\n")
  #      print('Conversions remained this month: ', usage['available'], "\n")
  #    rescue SelectPdf::ApiException => e
  #      print("An error occurred: #{e}")
  #    end
  #
  class PdfToTextClient < ApiClient
    # Construct the Pdf To Text Client.
    #
    # @param api_key API Key.
    def initialize(api_key)
      super()
      @api_endpoint = 'https://selectpdf.com/api2/pdftotext/'
      @parameters['key'] = api_key

      @file_idx = 0
    end

    # Get the text from the specified pdf.
    #
    # @param input_pdf Path to a local PDF file.
    # @return Extracted text.
    def text_from_file(input_pdf)
      @parameters['async'] = 'False'
      @parameters['action'] = 'Convert'
      @parameters.delete('url')

      @files = {}
      @files['inputPdf'] = input_pdf

      perform_post_as_multipart_formdata
    end

    # Get the text from the specified pdf and write it to the specified text file.
    #
    # @param input_pdf Path to a local PDF file.
    # @param output_file_path The output file where the resulted text will be written.
    def text_from_file_to_file(input_pdf, output_file_path)
      result = text_from_file(input_pdf)
      File.open(output_file_path, 'wb') do |file|
        file.write(result)
      end
    rescue ApiException
      FileUtils.rm(output_file_path) if File.exist?(output_file_path)
      raise
    end

    # Get the text from the specified pdf and write it to the specified stream.
    #
    # @param input_pdf Path to a local PDF file.
    # @param stream The output stream where the resulted PDF will be written.
    def text_from_file_to_stream(input_pdf, stream)
      result = text_from_file(input_pdf)
      stream.write(result)
    end

    # Get the text from the specified pdf with an asynchronous call.
    #
    # @param input_pdf Path to a local PDF file.
    # @return Extracted text.
    def text_from_file_async(input_pdf)
      @parameters['action'] = 'Convert'
      @parameters.delete('url')

      @files = {}
      @files['inputPdf'] = input_pdf

      job_id = start_async_job_multipart_form_data

      if job_id.nil? || job_id.empty?
        raise ApiException.new('An error occurred launching the asynchronous call.'), 'An error occurred launching the asynchronous call.'
      end

      no_pings = 0

      while no_pings < @async_calls_max_pings
        no_pings += 1

        # sleep for a few seconds before next ping
        sleep(@async_calls_ping_interval)

        async_job_client = AsyncJobClient.new(@parameters['key'], @job_id)
        async_job_client.api_endpoint = @api_async_endpoint

        result = async_job_client.result

        next if result.nil?

        @number_of_pages = async_job_client.number_of_pages

        return result
      end

      raise ApiException.new('Asynchronous call did not finish in expected timeframe.'), 'Asynchronous call did not finish in expected timeframe.'
    end

    # Get the text from the specified pdf with an asynchronous call and write it to the specified text file.
    #
    # @param input_pdf Path to a local PDF file.
    # @param output_file_path The output file where the resulted text will be written.
    def text_from_file_to_file_async(input_pdf, output_file_path)
      result = text_from_file_async(input_pdf)
      File.open(output_file_path, 'wb') do |file|
        file.write(result)
      end
    rescue ApiException
      FileUtils.rm(output_file_path) if File.exist?(output_file_path)
      raise
    end

    # Get the text from the specified pdf with an asynchronous call and write it to the specified stream.
    #
    # @param input_pdf Path to a local PDF file.
    # @param stream The output stream where the resulted PDF will be written.
    def text_from_file_to_stream_async(input_pdf, stream)
      result = text_from_file_async(input_pdf)
      stream.write(result)
    end

    # Get the text from the specified pdf.
    #
    # @param url Address of the PDF file.
    # @return Extracted text.
    def text_from_url(url)
      if !url.downcase.start_with?('http://') && !url.downcase.start_with?('https://')
        raise ApiException.new('The supported protocols for the PDFs available online are http:// and https://.'),
              'The supported protocols for the PDFs available online are http:// and https://.'
      end

      if url.downcase.start_with?('http://localhost')
        raise ApiException.new('Cannot convert local urls via this method. Use getTextFromFile instead.'),
              'Cannot convert local urls via this method. Use text_from_file instead.'
      end

      @parameters['async'] = 'False'
      @parameters['action'] = 'Convert'

      @files = {}
      @parameters['url'] = url

      perform_post_as_multipart_formdata
    end

    # Get the text from the specified pdf and write it to the specified text file.
    #
    # @param url Address of the PDF file.
    # @param output_file_path The output file where the resulted text will be written.
    def text_from_url_to_file(url, output_file_path)
      result = text_from_url(url)
      File.open(output_file_path, 'wb') do |file|
        file.write(result)
      end
    rescue ApiException
      FileUtils.rm(output_file_path) if File.exist?(output_file_path)
      raise
    end

    # Get the text from the specified pdf and write it to the specified stream.
    #
    # @param url Address of the PDF file.
    # @param stream The output stream where the resulted PDF will be written.
    def text_from_url_to_stream(url, stream)
      result = text_from_url(url)
      stream.write(result)
    end

    # Get the text from the specified pdf with an asynchronous call.
    #
    # @param url Address of the PDF file.
    # @return Extracted text.
    def text_from_url_async(url)
      if !url.downcase.start_with?('http://') && !url.downcase.start_with?('https://')
        raise ApiException.new('The supported protocols for the PDFs available online are http:// and https://.'),
              'The supported protocols for the PDFs available online are http:// and https://.'
      end

      if url.downcase.start_with?('http://localhost')
        raise ApiException.new('Cannot convert local urls via this method. Use getTextFromFile instead.'),
              'Cannot convert local urls via this method. Use text_from_file_async instead.'
      end

      @parameters['action'] = 'Convert'

      @files = {}
      @parameters['url'] = url

      job_id = start_async_job_multipart_form_data

      if job_id.nil? || job_id.empty?
        raise ApiException.new('An error occurred launching the asynchronous call.'), 'An error occurred launching the asynchronous call.'
      end

      no_pings = 0

      while no_pings < @async_calls_max_pings
        no_pings += 1

        # sleep for a few seconds before next ping
        sleep(@async_calls_ping_interval)

        async_job_client = AsyncJobClient.new(@parameters['key'], @job_id)
        async_job_client.api_endpoint = @api_async_endpoint

        result = async_job_client.result

        next if result.nil?

        @number_of_pages = async_job_client.number_of_pages

        return result
      end

      raise ApiException.new('Asynchronous call did not finish in expected timeframe.'),
            'Asynchronous call did not finish in expected timeframe.'
    end

    # Get the text from the specified pdf with an asynchronous call and write it to the specified text file.
    #
    # @param url Address of the PDF file.
    # @param output_file_path The output file where the resulted text will be written.
    def text_from_url_to_file_async(url, output_file_path)
      result = text_from_url_async(url)
      File.open(output_file_path, 'wb') do |file|
        file.write(result)
      end
    rescue ApiException
      FileUtils.rm(output_file_path) if File.exist?(output_file_path)
      raise
    end

    # Get the text from the specified pdf with an asynchronous call and write it to the specified stream.
    #
    # @param url Address of the PDF file.
    # @param stream The output stream where the resulted PDF will be written.
    def text_from_url_to_stream_async(url, stream)
      result = text_from_url_async(url)
      stream.write(result)
    end

    # Search for a specific text in a PDF document.
    # Pages that participate to this operation are specified by start_page and end_page methods.
    #
    # @param input_pdf Path to a local PDF file.
    # @param text_to_search Text to search.
    # @param case_sensitive If the search is case sensitive or not.
    # @param whole_words_only If the search works on whole words or not.
    # @return List with text positions in the current PDF document.
    def search_file(input_pdf, text_to_search, case_sensitive = FALSE, whole_words_only = FALSE)
      if text_to_search.nil? || text_to_search.empty?
        raise ApiException.new('Search text cannot be empty.'), 'Search text cannot be empty.'
      end

      @parameters['async'] = 'False'
      @parameters['action'] = 'Search'
      @parameters.delete('url')
      @parameters['search_text'] = text_to_search
      @parameters['case_sensitive'] = case_sensitive
      @parameters['whole_words_only'] = whole_words_only

      @files = {}
      @files['inputPdf'] = input_pdf

      @headers['Accept'] = 'text/json'

      result = perform_post_as_multipart_formdata
      return [] if result.nil? || result.empty?

      JSON.parse(result)
    end

    # Search for a specific text in a PDF document with an asynchronous call.
    # Pages that participate to this operation are specified by start_page and end_page methods.
    #
    # @param input_pdf Path to a local PDF file.
    # @param text_to_search Text to search.
    # @param case_sensitive If the search is case sensitive or not.
    # @param whole_words_only If the search works on whole words or not.
    # @return List with text positions in the current PDF document.
    def search_file_async(input_pdf, text_to_search, case_sensitive = FALSE, whole_words_only = FALSE)
      if text_to_search.nil? || text_to_search.empty?
        raise ApiException.new('Search text cannot be empty.'), 'Search text cannot be empty.'
      end

      @parameters['action'] = 'Search'
      @parameters.delete('url')
      @parameters['search_text'] = text_to_search
      @parameters['case_sensitive'] = case_sensitive
      @parameters['whole_words_only'] = whole_words_only

      @files = {}
      @files['inputPdf'] = input_pdf

      @headers['Accept'] = 'text/json'

      job_id = start_async_job_multipart_form_data

      if job_id.nil? || job_id.empty?
        raise ApiException.new('An error occurred launching the asynchronous call.'),
              'An error occurred launching the asynchronous call.'
      end

      no_pings = 0

      while no_pings < @async_calls_max_pings
        no_pings += 1

        # sleep for a few seconds before next ping
        sleep(@async_calls_ping_interval)

        async_job_client = AsyncJobClient.new(@parameters['key'], @job_id)
        async_job_client.api_endpoint = @api_async_endpoint

        result = async_job_client.result

        next if result.nil?

        @number_of_pages = async_job_client.number_of_pages
        return [] if result.empty?

        return JSON.parse(result)
      end

      raise ApiException.new('Asynchronous call did not finish in expected timeframe.'),
            'Asynchronous call did not finish in expected timeframe.'
    end

    # Search for a specific text in a PDF document.
    # Pages that participate to this operation are specified by start_page and end_page methods.
    #
    # @param url Address of the PDF file.
    # @param text_to_search Text to search.
    # @param case_sensitive If the search is case sensitive or not.
    # @param whole_words_only If the search works on whole words or not.
    # @return List with text positions in the current PDF document.
    def search_url(url, text_to_search, case_sensitive = FALSE, whole_words_only = FALSE)
      if text_to_search.nil? || text_to_search.empty?
        raise ApiException.new('Search text cannot be empty.'), 'Search text cannot be empty.'
      end

      @parameters['async'] = 'False'
      @parameters['action'] = 'Search'
      @parameters['search_text'] = text_to_search
      @parameters['case_sensitive'] = case_sensitive
      @parameters['whole_words_only'] = whole_words_only

      @files = {}
      @parameters['url'] = url

      @headers['Accept'] = 'text/json'

      result = perform_post_as_multipart_formdata
      return [] if result.nil? || result.empty?

      JSON.parse(result)
    end

    # Search for a specific text in a PDF document with an asynchronous call.
    # Pages that participate to this operation are specified by start_page and end_page methods.
    #
    # @param url Address of the PDF file.
    # @param text_to_search Text to search.
    # @param case_sensitive If the search is case sensitive or not.
    # @param whole_words_only If the search works on whole words or not.
    # @return List with text positions in the current PDF document.
    def search_url_async(url, text_to_search, case_sensitive = FALSE, whole_words_only = FALSE)
      if text_to_search.nil? || text_to_search.empty?
        raise ApiException.new('Search text cannot be empty.'), 'Search text cannot be empty.'
      end

      @parameters['action'] = 'Search'
      @parameters['search_text'] = text_to_search
      @parameters['case_sensitive'] = case_sensitive
      @parameters['whole_words_only'] = whole_words_only

      @files = {}
      @parameters['url'] = url

      @headers['Accept'] = 'text/json'

      job_id = start_async_job_multipart_form_data

      if job_id.nil? || job_id.empty?
        raise ApiException.new('An error occurred launching the asynchronous call.'),
              'An error occurred launching the asynchronous call.'
      end

      no_pings = 0

      while no_pings < @async_calls_max_pings
        no_pings += 1

        # sleep for a few seconds before next ping
        sleep(@async_calls_ping_interval)

        async_job_client = AsyncJobClient.new(@parameters['key'], @job_id)
        async_job_client.api_endpoint = @api_async_endpoint

        result = async_job_client.result

        next if result.nil?

        @number_of_pages = async_job_client.number_of_pages
        return [] if result.empty?

        return JSON.parse(result)
      end

      raise ApiException.new('Asynchronous call did not finish in expected timeframe.'),
            'Asynchronous call did not finish in expected timeframe.'
    end

    # Set Start Page number. Default value is 1 (first page of the document).
    #
    # @param start_page Start page number (1-based).
    def start_page=(start_page)
      @parameters['start_page'] = start_page
    end

    # Set End Page number. Default value is 0 (process till the last page of the document).
    #
    # @param end_page End page number (1-based).
    def end_page=(end_page)
      @parameters['end_page'] = end_page
    end

    # Set PDF user password.
    #
    # @param user_password PDF user password.
    def user_password=(user_password)
      @parameters['user_password'] = user_password
    end

    # Set the text layout. The default value is SelectPdf::TextLayout::ORIGINAL.
    #
    # @param text_layout The text layout. Possible values: Original, Reading. Use constants from SelectPdf::TextLayout class.
    def text_layout=(text_layout)
      unless [0, 1].include?(text_layout)
        raise ApiException.new('Allowed values for Text Layout: 0 (Original), 1 (Reading).'), 'Allowed values for Text Layout: 0 (Original), 1 (Reading).'
      end

      @parameters['text_layout'] = text_layout
    end

    # Set the output format. The default value is SelectPdf::OutputFormat::TEXT.
    #
    # @param output_format The output format. Possible values: Text, Html. Use constants from SelectPdf::OutputFormat class.
    def output_format=(output_format)
      unless [0, 1].include?(output_format)
        raise ApiException.new('Allowed values for Output Format: 0 (Text), 1 (Html).'), 'Allowed values for Output Format: 0 (Text), 1 (Html).'
      end

      @parameters['output_format'] = output_format
    end

    # Set the maximum amount of time (in seconds) for this job.
    # The default value is 30 seconds. Use a larger value (up to 120 seconds allowed) for large documents.
    #
    # @param timeout Timeout in seconds.
    def timeout=(timeout)
      @parameters['timeout'] = timeout
    end

    # Set a custom parameter. Do not use this method unless advised by SelectPdf.
    #
    # @param parameter_name Parameter name.
    # @param parameter_value Parameter value.
    def set_custom_parameter(parameter_name, parameter_value)
      @parameters[parameter_name] = parameter_value
    end
  end
end
