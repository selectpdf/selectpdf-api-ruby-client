require 'selectpdf'

$stdout.sync = true

print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"

test_url = 'https://selectpdf.com/demo/files/selectpdf.pdf'
test_pdf = 'Input.pdf'
local_file = 'Result.txt'
api_key = 'Your API key here'

begin
  client = SelectPdf::PdfToTextClient.new(api_key)

  # set parameters - see full list at https://selectpdf.com/pdf-to-text-api/
  client.start_page = 1 # start page (processing starts from here)
  client.end_page = 0 # end page (set 0 to process file til the end)
  client.output_format = SelectPdf::OutputFormat::TEXT # set output format (Text or HTML)

  print "Starting pdf to text ...\n"

  # convert local pdf to local text file
  client.text_from_file_to_file(test_pdf, local_file)

  # extract text from local pdf to memory
  # text = client.text_from_file(test_pdf)
  # print text

  # convert pdf from public url to local text file
  # client.text_from_url_to_file(test_url, local_file)

  # extract text from pdf from public url to memory
  # text = client.text_from_url(test_url)
  # print text

  print "Finished! Number of pages processed: #{client.number_of_pages}.\n"

  # get API usage
  usage_client = SelectPdf::UsageClient.new(api_key)
  usage = usage_client.get_usage(FALSE)
  print("Usage: #{usage}\n")
  print('Conversions remained this month: ', usage['available'], "\n")
rescue SelectPdf::ApiException => e
  print("An error occurred: #{e}")
end
