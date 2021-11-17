require 'selectpdf'

$stdout.sync = true

print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"

url = 'https://selectpdf.com'
local_file = 'Test.pdf'
api_key = 'Your API key here'

begin
  client = SelectPdf::HtmlToPdfClient.new(api_key)

  # set parameters - see full list at https://selectpdf.com/html-to-pdf-api/

  client.page_size = SelectPdf::PageSize::A4 # PDF page size
  client.page_orientation = SelectPdf::PageOrientation::PORTRAIT # PDF page orientation
  client.margins = 0 # PDF page margins
  client.rendering_engine = SelectPdf::RenderingEngine::WEBKIT # rendering engine
  client.conversion_delay = 1 # conversion delay
  client.navigation_timeout = 30 # navigation timeout
  client.page_numbers = FALSE # page numbers
  client.page_breaks_enhanced_algorithm = TRUE # enhanced page break algorithm

  # additional properties

  # client.use_css_print = TRUE # enable CSS media print
  # client.disable_javascript = TRUE # disable javascript
  # client.disable_internal_links = TRUE # disable internal links
  # client.disable_external_links = TRUE # disable external links
  # client.keep_images_together = TRUE # keep images together
  # client.scale_images = TRUE # scale images to create smaller pdfs
  # client.single_page_pdf = TRUE # generate a single page PDF
  # client.user_password = 'password' # secure the PDF with a password

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

  # get API usage
  usage_client = SelectPdf::UsageClient.new(api_key)
  usage = usage_client.get_usage(FALSE)
  print("Usage: #{usage}\n")
  print('Conversions remained this month: ', usage['available'], "\n")
rescue SelectPdf::ApiException => e
  print("An error occurred: #{e}")
end
