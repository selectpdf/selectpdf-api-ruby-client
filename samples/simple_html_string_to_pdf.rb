require 'selectpdf'
print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"

html = 'This is a <b>test HTML</b>.'
local_file = 'Test.pdf'
api_key = 'Your API key here'

begin
  api = SelectPdf::HtmlToPdfClient.new(api_key)

  api.page_size = SelectPdf::PageSize::A4
  api.margins = 0
  api.page_numbers = FALSE
  api.page_breaks_enhanced_algorithm = TRUE

  api.convert_html_string_to_file(html, local_file)
rescue SelectPdf::ApiException => e
  print("An error occurred: #{e}")
end
