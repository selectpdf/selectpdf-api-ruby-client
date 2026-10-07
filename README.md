# SelectPdf Online REST API - Ruby Client

## HTML To PDF API - Ruby Client

SelectPdf HTML To PDF Online REST API is a professional solution that lets you create PDF from web pages and raw HTML code in your applications. The API is easy to use and the integration takes only a few lines of code.

### Features

* Create PDF from any web page or html string.
* Full html5/css3/javascript support.
* Set PDF options such as page size and orientation, margins, security, web page settings.
* Set PDF viewer options and PDF document information.
* Create custom headers and footers for the pdf document.
* Hide web page elements during the conversion.
* Automatically generate bookmarks during the html to pdf conversion.
* Support for partial page conversion.
* Tagged (accessible) PDF and PDF/A, PDF/X, PDF/SiqQ conformance.
* ZUGFeRD / Factur-X hybrid electronic invoices.
* Try it without an API key with the keyless demo endpoint.
* Works in all programming languages.

Sign up for for free to get instant API access to SelectPdf [HTML to PDF API](https://selectpdf.com/html-to-pdf-api/).

### Sample Code

    require 'selectpdf'
    print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"

    url = 'https://selectpdf.com'
    local_file = 'Test.pdf'
    api_key = 'Your API key here'

    begin
        api = SelectPdf::HtmlToPdfClient.new(api_key)

        api.page_size = SelectPdf::PageSize::A4
        api.margins = 0
        api.page_numbers = false
        api.page_breaks_enhanced_algorithm = true

        api.convert_url_to_file(url, local_file)
    rescue SelectPdf::ApiException => e
        print("An error occurred: #{e}")
    end

### Demo Mode (no API key)

Construct `HtmlToPdfClient` with no key, an empty key or `'demo'` to use the keyless demo endpoint. No signup is required, but the output is watermarked, capped at 5 pages and always rendered with the Chromium engine.

    client = SelectPdf::HtmlToPdfClient.new # or HtmlToPdfClient.new('demo')
    pdf = client.convert_url('https://selectpdf.com')

    print "Demo mode: #{client.demo_mode?}, demo response: #{client.demo_response?}\n"
    print "Clamped: #{client.clamped_fields.join(', ')}\n" if client.was_clamped?
    print "Dropped: #{client.dropped_fields.join(', ')}\n" if client.was_any_field_dropped?

* `demo_mode?` - the client was constructed without a key. `demo_response?` - the last response came from the demo endpoint.
* `clamped_fields` - parameters the demo endpoint modified (e.g. `max_load_time` is capped to 15 seconds, `engine` is forced to Chromium).
* `dropped_fields` - parameters the demo endpoint ignored: `auth_username`, `auth_password`, `cookies_string` (set with `cookies`), `raw_parameters`, `pdf_name`, `async`, `pdf_web_elements_selectors`.
* PDF passwords (`user_password`, `owner_password`) and asynchronous calls are not available in demo mode and raise `SelectPdf::DemoUnsupportedException`.
* Only public urls are converted. Internal or private hosts are rejected with `SelectPdf::DemoSafetyException`.
* Per-IP and global rate limits raise `SelectPdf::DemoRateLimitException`.

### Exceptions

All errors raise `SelectPdf::ApiException`. The demo endpoint errors raise typed subclasses, so you can react to them without parsing the message:

| Exception | Raised when | Attributes |
| --- | --- | --- |
| `SelectPdf::DemoRateLimitException` | the demo rate limit is reached (HTTP 429 or 503) | `status_code`, `reason` (`per_ip`, `concurrency`, `daily_cap`), `retry_after`, `upgrade_url`, `response_body` |
| `SelectPdf::DemoSafetyException` | a url field references a non-public host (HTTP 400) | `status_code`, `field`, `reason`, `response_body` |
| `SelectPdf::DemoUnsupportedException` | a feature is not available in demo mode (HTTP 400, or before the request is sent with `status_code` 0) | `status_code`, `field`, `upgrade_url`, `response_body` |

    begin
        client = SelectPdf::HtmlToPdfClient.new
        client.convert_url_to_file('https://selectpdf.com', 'Test.pdf')
    rescue SelectPdf::DemoRateLimitException => e
        print("Demo rate limit (#{e.reason}). Retry after #{e.retry_after}s. Upgrade: #{e.upgrade_url}\n")
    rescue SelectPdf::DemoUnsupportedException => e
        print("Feature '#{e.field}' not available in demo mode.\n")
    rescue SelectPdf::ApiException => e
        print("An error occurred: #{e}")
    end

### Response Telemetry

Every client exposes what the server reported for the most recent call:

* `number_of_pages` - number of pages of the resulted PDF.
* `credits_total` - monthly conversion limit of the subscription (-1 = unlimited, nil when not reported, e.g. in demo mode).
* `credits_remaining` - conversions remaining this month (-1 = unlimited, nil when not reported).
* `mode` - `production` or `demo`.
* `execution_mode` - server-side execution path of the conversion (e.g. `worker`).

### Accessible PDF and PDF Standards

    client = SelectPdf::HtmlToPdfClient.new(api_key)

    client.tagged = true # tagged (accessible) PDF - needs the Blink or Chromium engine
    client.doc_title = 'Accessible document' # a tagged document needs a title
    client.doc_language = 'en-US' # document language (PDF /Lang entry)
    client.pdf_standard = SelectPdf::PdfStandard::PDF_A3A # Full, PdfA, PdfA2B, PdfA3A, PdfA3B, PdfA3U, PdfX, PdfSiqQ_A, PdfSiqQ_B
    client.rendering_engine = SelectPdf::RenderingEngine::CHROMIUM # optional - the API promotes tagged requests to Chromium

    client.convert_url_to_file('https://selectpdf.com', 'Accessible.pdf')

Other parameters added in 1.6.0:

* `web_page_fixed_size` - leave out the content below `web_page_height` instead of letting the page flow onto further pages.
* `auth_username`, `auth_password` - HTTP Basic authentication credentials for the web page being converted.

See [HTML to PDF API parameters](https://selectpdf.com/html-to-pdf-api-parameters/) for the full list of parameters.

## Electronic Invoice API

`SelectPdf::InvoiceClient` creates ZUGFeRD / Factur-X hybrid electronic invoices: one PDF/A-3 document carrying both the page a human reads and the invoice XML an accounting system reads. It derives from `HtmlToPdfClient`, so every conversion setting applies too. An API key is required - the demo endpoint does not create invoices.

### Features

* Create the visible invoice from a url or an html string, synchronously or asynchronously.
* Embed the invoice XML from a local file (`invoice_xml_file`) or from memory (`invoice_xml`).
* Profiles: `MINIMUM`, `BASIC_WL`, `BASIC`, `EN16931`, `EXTENDED`, `XRECHNUNG` (`SelectPdf::ZugferdProfile`).
* Optional relationship (`SelectPdf::ZugferdRelationship`) - derived from the profile when not set - and schema (`SelectPdf::ZugferdSchema`, Factur-X 1.0 by default).
* The carrier is PDF/A-3A by default; `PDF_A3B` and `PDF_A3U` are also accepted.

### Sample Code

    require 'selectpdf'

    api_key = 'Your API key here'

    begin
        client = SelectPdf::InvoiceClient.new(api_key)

        client.invoice_xml_file = 'factur-x.xml' # or client.invoice_xml = xml_string
        client.zugferd_profile = SelectPdf::ZugferdProfile::EN16931
        # client.zugferd_relationship = SelectPdf::ZugferdRelationship::DATA # optional
        # client.zugferd_schema = SelectPdf::ZugferdSchema::FACTUR_X_10 # optional

        client.create_from_html_string_to_file('<h1>Invoice INV-2026-001</h1>', 'Invoice.pdf')
        # client.create_from_url_to_file('https://your-app.example/invoices/INV-2026-001', 'Invoice.pdf')
        # pdf = client.create_from_html_string_async('<h1>Invoice INV-2026-001</h1>')

        print "Finished! Number of pages: #{client.number_of_pages}.\n"
    rescue SelectPdf::ApiException => e
        print("An error occurred: #{e}")
    end

Available methods: `create_from_url`, `create_from_url_to_stream`, `create_from_url_to_file`, `create_from_html_string`, `create_from_html_string_with_base_url`, `create_from_html_string_to_stream`, `create_from_html_string_to_stream_with_base_url`, `create_from_html_string_to_file`, `create_from_html_string_with_base_url_to_file` and the asynchronous `create_from_url_async`, `create_from_url_to_stream_async`, `create_from_url_to_file_async`, `create_from_html_string_async`, `create_from_html_string_with_base_url_async`, `create_from_html_string_to_stream_async`, `create_from_html_string_to_file_async`.

See `samples/electronic_invoice.rb` for a complete sample with an inline invoice XML.

## Pdf Merge API

SelectPdf Pdf Merge REST API is an online solution that lets you merge local or remote PDFs into a final PDF document.

### Features

* Merge local PDF document.
* Merge remote PDF from public url.
* Set PDF viewer options and PDF document information.
* Secure generated PDF with a password.
* Works in all programming languages.

See [PDF Merge API](https://selectpdf.com/pdf-merge-api/) page for full list of parameters.

### Sample Code

    require 'selectpdf'
    print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"

    test_url = 'https://selectpdf.com/demo/files/selectpdf.pdf'
    test_pdf = 'Input.pdf'
    local_file = 'Result.pdf'
    api_key = 'Your API key here'

    begin
        client = SelectPdf::PdfMergeClient.new(api_key)

        # specify the pdf files that will be merged (order will be preserved in the final pdf)
        client.add_file(test_pdf) # add PDF from local file
        client.add_url_file(test_url) # add PDF from public url

        # merge pdfs to local file
        client.save_to_file(local_file)
    rescue SelectPdf::ApiException => e
        print("An error occurred: #{e}")
    end

## Pdf To Text API

SelectPdf Pdf To Text REST API is an online solution that lets you extract text from your PDF documents or search your PDF document for certain words.

### Features

* Extract text from PDF.
* Search PDF.
* Specify start and end page for partial file processing.
* Specify output format (plain text or html).
* Use a PDF from an online location (url) or upload a local PDF document.

See [Pdf To Text API](https://selectpdf.com/pdf-to-text-api/) page for full list of parameters.

### Sample Code

    require 'selectpdf'
    print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"

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

        print "Finished! Number of pages processed: #{client.number_of_pages}.\n"
    rescue SelectPdf::ApiException => e
        print("An error occurred: #{e}")
    end


