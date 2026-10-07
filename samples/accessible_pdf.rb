require 'selectpdf'

# Tagged (accessible) PDF and PDF conformance standards.

$stdout.sync = true

print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"

url = 'https://selectpdf.com'
local_file = 'Accessible.pdf'

# Works with the keyless demo endpoint too - set the key to nil or 'demo'.
# Note the demo stamps its output after conversion, so a demo PDF demonstrates
# the feature rather than being a conformant artifact; use a real key for output you intend to ship.
api_key = 'Your API key here'

begin
  client = SelectPdf::HtmlToPdfClient.new(api_key)

  # set parameters - see full list at https://selectpdf.com/html-to-pdf-api-parameters/

  # Produce a tagged PDF: a logical structure tree covering headings, paragraphs, lists, tables,
  # figures with alternate text, links and reading order - what a screen reader needs to read the document.
  client.tagged = true

  # A tagged document needs a title. Without this the converter falls back to the HTML <title>.
  client.doc_title = 'SelectPdf - accessible sample'

  # Shown by viewers that honour it; accessible PDF expects it on, and the API turns it on
  # for you whenever tagged output is requested.
  client.viewer_display_doc_title = true

  # The document language, written as the PDF /Lang entry and onto the tagged structure elements.
  client.doc_language = 'en-US'

  # Conformance target. PdfA3A is the ACCESSIBLE level of PDF/A-3: it implies a tagged document on its own,
  # and it is the level required to carry a ZUGFeRD / Factur-X invoice (see electronic_invoice.rb).
  #   FULL   - the complete PDF feature set (default)
  #   PDF_A / PDF_A2B / PDF_A3B / PDF_A3U - long term archiving
  #   PDF_A3A - archiving + accessibility
  #   PDF_X   - graphics exchange
  #   PDF_SIQQ_A / PDF_SIQQ_B - digital signatures
  client.pdf_standard = SelectPdf::PdfStandard::PDF_A3A

  # Tagged output requires the Blink or Chromium engine - the WebKit engines cannot build a structure tree.
  # You can name one explicitly:
  #
  #   client.rendering_engine = SelectPdf::RenderingEngine::CHROMIUM
  #
  # If you don't, the API promotes the conversion to Chromium for you and reports the engine it used
  # in the X-SelectPdf-Engine response header. Asking for tagged output together with an explicit WebKit
  # engine is rejected with HTTP 400 rather than silently producing an untagged PDF.

  print "Starting conversion ...\n"

  # convert url to local file
  client.convert_url_to_file(url, local_file)

  # convert url to memory
  # pdf = client.convert_url(url)

  print "Finished! Number of pages: #{client.number_of_pages}.\n"

  # response telemetry
  print "Mode: #{client.mode}, Execution: #{client.execution_mode}.\n"
  print "Credits remaining: #{client.credits_remaining} / #{client.credits_total}.\n"
rescue SelectPdf::ApiException => e
  print("An error occurred: #{e}")
end
