require 'selectpdf'

$stdout.sync = true

print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"

test_url = 'https://selectpdf.com/demo/files/selectpdf.pdf'
test_pdf = 'Input.pdf'
local_file = 'Result.pdf'
api_key = 'Your API key here'

begin
  client = SelectPdf::PdfMergeClient.new(api_key)

  # set parameters - see full list at https://selectpdf.com/pdf-merge-api/

  # specify the pdf files that will be merged (order will be preserved in the final pdf)
  client.add_file(test_pdf) # add PDF from local file
  client.add_url_file(test_url) # add PDF from public url
  # client.add_file(test_pdf, 'pdf_password') # add PDF (that requires a password) from local file
  # client.add_url_file(test_url, 'pdf_password') # add PDF (that requires a password) from public url

  print "Starting pdf merge ...\n"

  # merge pdfs to local file
  client.save_to_file(local_file)

  # merge pdfs to memory
  # pdf = client.save

  print "Finished! Number of pages: #{client.number_of_pages}.\n"

  # get API usage
  usage_client = SelectPdf::UsageClient.new(api_key)
  usage = usage_client.get_usage(FALSE)
  print("Usage: #{usage}\n")
  print('Conversions remained this month: ', usage['available'], "\n")
rescue SelectPdf::ApiException => e
  print("An error occurred: #{e}")
end
