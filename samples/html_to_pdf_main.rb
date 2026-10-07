require 'selectpdf'

$stdout.sync = true

print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"

url = 'https://selectpdf.com'
local_file = 'Test.pdf'
api_key = 'Your API key here'

# Use nil, '' or 'demo' as the key to use the keyless demo endpoint
# (output is watermarked, capped at 5 pages, Chromium engine only).
# Replace it with a real key for full production output.
# api_key = nil

begin
  client = SelectPdf::HtmlToPdfClient.new(api_key)

  # set parameters - see full list at https://selectpdf.com/html-to-pdf-api/

  client.page_size = SelectPdf::PageSize::A4 # PDF page size
  client.page_orientation = SelectPdf::PageOrientation::PORTRAIT # PDF page orientation
  client.margins = 0 # PDF page margins
  client.rendering_engine = SelectPdf::RenderingEngine::WEBKIT # rendering engine (demo mode forces Chromium)
  client.conversion_delay = 1 # conversion delay
  client.navigation_timeout = 30 # navigation timeout
  client.page_numbers = false # page numbers
  client.page_breaks_enhanced_algorithm = true # enhanced page break algorithm

  # additional properties

  # client.use_css_print = true # enable CSS media print
  # client.disable_javascript = true # disable javascript
  # client.disable_internal_links = true # disable internal links
  # client.disable_external_links = true # disable external links
  # client.keep_images_together = true # keep images together
  # client.scale_images = true # scale images to create smaller pdfs
  # client.single_page_pdf = true # generate a single page PDF
  # client.user_password = 'password' # secure the PDF with a password (paid keys only)

  # generate automatic bookmarks

  # client.pdf_bookmarks_selectors = 'H1, H2' # create outlines (bookmarks) for the specified elements
  # client.viewer_page_mode = SelectPdf::PageMode::USE_OUTLINES # display outlines (bookmarks) in viewer

  print "Starting conversion ...\n"

  # convert url to file
  client.convert_url_to_file(url, local_file)

  # convert url to memory
  # pdf = client.convert_url(url)

  # convert html string to file
  # client.convert_html_string_to_file('This is some <b>html</b>.', local_file)

  # convert html string to memory
  # pdf = client.convert_html_string('This is some <b>html</b>.')

  print "Finished! Number of pages: #{client.number_of_pages}.\n"

  # response telemetry
  print "Mode: #{client.mode}, Execution: #{client.execution_mode}.\n"

  if client.demo_mode?
    print "Demo clamped: #{client.clamped_fields.join(', ')}.\n" if client.was_clamped?
    print "Demo dropped: #{client.dropped_fields.join(', ')}.\n" if client.was_any_field_dropped?
  else
    print "Credits remaining: #{client.credits_remaining} / #{client.credits_total}.\n"

    # get API usage (paid keys only - the demo endpoint has no usage account)
    usage_client = SelectPdf::UsageClient.new(api_key)
    usage = usage_client.get_usage(false)
    print("Usage: #{usage}\n")
    print('Conversions remained this month: ', usage['available'], "\n")
  end
rescue SelectPdf::DemoRateLimitException => e
  # reason is one of: per_ip, daily_cap, concurrency
  print("Demo rate limit (#{e.reason}). Retry after #{e.retry_after}s. Upgrade: #{e.upgrade_url}\n")
rescue SelectPdf::DemoSafetyException => e
  # the demo only converts public urls - internal/private hosts are rejected
  print("Demo safety guard rejected '#{e.field}' (reason=#{e.reason}).\n")
rescue SelectPdf::DemoUnsupportedException => e
  # feature not available on the demo endpoint (e.g. user_password)
  print("Feature '#{e.field}' not available in demo mode. Upgrade: #{e.upgrade_url}\n")
rescue SelectPdf::ApiException => e
  print("An error occurred: #{e}")
end
