require 'selectpdf'

# ZUGFeRD / Factur-X hybrid electronic invoice.

$stdout.sync = true

print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"

# A minimal, well-formed EN 16931 CrossIndustryInvoice, inline so the sample runs without any extra files.
# A real integration produces this from its own invoice data - the API embeds the bytes as given
# and does not validate the invoice content.
invoice_xml = '<?xml version="1.0" encoding="UTF-8"?>' \
              '<rsm:CrossIndustryInvoice' \
              ' xmlns:rsm="urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100"' \
              ' xmlns:ram="urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100"' \
              ' xmlns:udt="urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100">' \
              '<rsm:ExchangedDocumentContext>' \
              '<ram:GuidelineSpecifiedDocumentContextParameter>' \
              '<ram:ID>urn:cen.eu:en16931:2017</ram:ID>' \
              '</ram:GuidelineSpecifiedDocumentContextParameter>' \
              '</rsm:ExchangedDocumentContext>' \
              '<rsm:ExchangedDocument>' \
              '<ram:ID>INV-2026-001</ram:ID>' \
              '<ram:TypeCode>380</ram:TypeCode>' \
              '<ram:IssueDateTime>' \
              '<udt:DateTimeString format="102">20260924</udt:DateTimeString>' \
              '</ram:IssueDateTime>' \
              '</rsm:ExchangedDocument>' \
              '</rsm:CrossIndustryInvoice>'

invoice_html = '<html><head><title>Invoice INV-2026-001</title></head><body>' \
               '<h1>Invoice INV-2026-001</h1>' \
               '<p>Seller Ltd &#8212; Buyer GmbH</p>' \
               '<table>' \
               '<tr><th>Item</th><th>Total</th></tr>' \
               '<tr><td>Consulting</td><td>1000.00 EUR</td></tr>' \
               '</table>' \
               '</body></html>'

local_file = 'Invoice.pdf'

# Electronic invoices require an API key - the keyless demo endpoint does not produce them,
# and InvoiceClient refuses a demo key rather than failing later on the server.
api_key = 'Your API key here'

begin
  client = SelectPdf::InvoiceClient.new(api_key)

  # set parameters - see full list at https://selectpdf.com/html-to-pdf-api-parameters/#invoicing

  # The invoice XML. From memory here; from disk with
  #   client.invoice_xml_file = 'factur-x.xml'
  # Either way the name recorded inside the PDF is the one the standard prescribes - recipients
  # look it up by name, so it is not taken from your file name.
  client.invoice_xml = invoice_xml

  # How much of the EN 16931 model the XML carries. Required.
  #   MINIMUM / BASIC_WL - not complete invoices
  #   BASIC / EN16931 / EXTENDED - complete, increasing detail
  #   XRECHNUNG - German public sector; the embedded file is then named xrechnung.xml instead of factur-x.xml
  client.zugferd_profile = SelectPdf::ZugferdProfile::EN16931

  # Optional. Left unset, the API derives the relationship from the profile: Alternative for Minimum and Basic_WL,
  # where the visible page carries more than the XML, and Data for the rest, where both carry the same content -
  # which Germany mandates for BASIC, EN 16931, EXTENDED and XRECHNUNG. Minimum or Basic_WL combined with Data
  # is rejected, because it would not be true.
  #
  #   client.zugferd_relationship = SelectPdf::ZugferdRelationship::DATA

  # Optional. Factur-X 1.0 is the current schema and the default;
  # ZUGFeRD 2.0 is deprecated and only for recipients that require it.
  #
  #   client.zugferd_schema = SelectPdf::ZugferdSchema::ZUGFERD_20

  # The carrier must be PDF/A-3. It defaults to PdfA3A, the accessible level, which the standards recommend
  # because it also makes the visible invoice readable by assistive technology. PdfA3B and PdfA3U are accepted;
  # anything else is rejected.
  #
  #   client.pdf_standard = SelectPdf::PdfStandard::PDF_A3B

  # Every ordinary conversion setting applies here as well, because InvoiceClient derives from HtmlToPdfClient.
  client.margins = 20

  print "Starting invoice conversion ...\n"

  # create the hybrid invoice from raw html, into a local file
  client.create_from_html_string_to_file(invoice_html, local_file)

  # ... or from the invoice page your application already renders
  # client.create_from_url_to_file('https://your-app.example/invoices/INV-2026-001', local_file)

  # ... or into memory
  # pdf = client.create_from_html_string(invoice_html)

  # ... or asynchronously, for long invoice runs
  # client.create_from_html_string_to_file_async(invoice_html, local_file)

  print "Finished! Number of pages: #{client.number_of_pages}.\n"
  print "Wrote #{local_file} - a PDF/A-3 document with factur-x.xml embedded.\n"

  # response telemetry
  print "Mode: #{client.mode}, Execution: #{client.execution_mode}.\n"
  print "Credits remaining: #{client.credits_remaining} / #{client.credits_total}.\n"
rescue SelectPdf::ApiException => e
  print("An error occurred: #{e}")
end
