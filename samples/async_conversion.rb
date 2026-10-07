require 'selectpdf'

$stdout.sync = true

print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"

url = 'https://selectpdf.com'
local_file = 'Test.pdf'

# Async conversions are not supported on the demo endpoint - this sample requires a paid API key.
api_key = 'Your API key here'

begin
  client = SelectPdf::HtmlToPdfClient.new(api_key)

  # Tune polling for the async job (optional).
  # The client polls /api2/asyncjob/ every async_calls_ping_interval seconds,
  # up to async_calls_max_pings times, then gives up.
  client.async_calls_ping_interval = 3 # seconds between polls
  client.async_calls_max_pings = 1000 # max polls before timeout

  client.page_size = SelectPdf::PageSize::A4
  client.page_orientation = SelectPdf::PageOrientation::PORTRAIT
  client.margins = 0
  client.page_breaks_enhanced_algorithm = true

  print "Starting async conversion ...\n"

  # url to file (async)
  client.convert_url_to_file_async(url, local_file)

  # url to memory (async)
  # pdf = client.convert_url_async(url)

  # html string to file (async)
  # client.convert_html_string_to_file_async('This is some <b>html</b>.', local_file)

  # html string to memory (async)
  # pdf = client.convert_html_string_async('This is some <b>html</b>.')

  print "Finished! Number of pages: #{client.number_of_pages}.\n"

  # response telemetry
  print "Mode: #{client.mode}, Execution: #{client.execution_mode}.\n"
  print "Credits remaining: #{client.credits_remaining} / #{client.credits_total}.\n"
rescue SelectPdf::ApiException => e
  print("An error occurred: #{e}")
end
