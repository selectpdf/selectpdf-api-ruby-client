require 'selectpdf'

$stdout.sync = true

print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"

url = 'https://selectpdf.com'
local_file = 'Test.pdf'

# Web elements lookup requires a paid API key (the demo endpoint does not expose the elements service).
api_key = 'Your API key here'

begin
  client = SelectPdf::HtmlToPdfClient.new(api_key)

  # CSS selectors used to identify HTML elements whose location in the resulting PDF
  # should be reported back. See the API docs for selector syntax: https://selectpdf.com/html-to-pdf-api/
  client.page_size = SelectPdf::PageSize::A4
  client.margins = 0
  client.pdf_web_elements_selectors = 'H1, H2, *.menu, *#footer'

  print "Starting conversion ...\n"

  client.convert_url_to_file(url, local_file)

  print "Finished! Number of pages: #{client.number_of_pages}.\n"

  # Retrieve element rectangles. Returns an empty list if no element matched the configured selectors.
  elements = client.web_elements
  print "Web elements found: #{elements.length}.\n"

  elements.each do |element|
    rectangles = element['PdfRectangles'] || []
    print " - <#{element['HtmlElementTagName']}> id='#{element['HtmlElementId']}' " \
          "class='#{element['HtmlElementCssClassName']}' rectangles=#{rectangles.length}\n"
  end

  print "Mode: #{client.mode}, Execution: #{client.execution_mode}.\n"
  print "Credits remaining: #{client.credits_remaining} / #{client.credits_total}.\n"
rescue SelectPdf::ApiException => e
  print("An error occurred: #{e}")
end
