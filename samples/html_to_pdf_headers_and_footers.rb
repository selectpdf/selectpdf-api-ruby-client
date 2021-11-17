require 'selectpdf'

$stdout.sync = true

print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"

url = 'https://selectpdf.com'
local_file = 'Test.pdf'
api_key = 'Your API key here'

begin
  client = SelectPdf::HtmlToPdfClient.new(api_key)

  # set parameters - see full list at https://selectpdf.com/html-to-pdf-api/

  client.margins = 0 # PDF page margins
  client.page_breaks_enhanced_algorithm = TRUE # enhanced page break algorithm

  # header properties
  client.show_header = TRUE # display header
  # client.header_height = 50 # header height
  # client.header_url = url # header url
  client.header_html = 'This is the <b>HEADER</b>!!!!' # header html

  # footer properties
  client.show_footer = TRUE # display footer
  # client.footer_height = 60 # footer height
  # client.footer_url = url # footer url
  client.footer_html = 'This is the <b>FOOTER</b>!!!!' # footer html

  # footer page numbers
  client.page_numbers = TRUE # show page numbers in footer
  client.page_numbers_template = '{page_number} / {total_pages}' # page numbers template
  client.page_numbers_font_name = 'Verdanda' # page numbers font name
  client.page_numbers_font_size = 12 # page numbers font size
  client.page_numbers_alignment = SelectPdf::PageNumbersAlignment::CENTER # page numbers alignment

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
