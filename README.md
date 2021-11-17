# SelectPdf Online REST API - Ruby Client

SelectPdf Online REST API is a professional solution for managing PDF documents online. It now has a dedicated, easy to use, Ruby client library that can be setup in minutes.

## Installation

Install SelectPdf Ruby Client for Online API via [RubyGems](https://rubygems.org/gems/selectpdf).

```
gem install selectpdf
```

OR

Download [selectpdf-api-ruby-client-1.4.0.zip](https://github.com/selectpdf/selectpdf-api-ruby-client/releases/download/1.4.0/selectpdf-api-ruby-client-1.4.0.zip), unzip it and run:

```
cd selectpdf-api-ruby-client-1.4.0
gem build selectpdf.gemspec
gem install selectpdf-1.4.0.gem
```

OR

Clone [selectpdf-api-ruby-client](https://github.com/selectpdf/selectpdf-api-ruby-client) from Github and install the library.

```
git clone https://github.com/selectpdf/selectpdf-api-ruby-client
cd selectpdf-api-ruby-client
gem build selectpdf.gemspec
gem install selectpdf-1.4.0.gem
```

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
* Works in all programming languages.

Sign up for for free to get instant API access to SelectPdf [HTML to PDF API](https://selectpdf.com/html-to-pdf-api/).

### Sample Code

```ruby
    require 'selectpdf'
    print "This is SelectPdf-#{SelectPdf::CLIENT_VERSION}\n"

    url = 'https://selectpdf.com'
    local_file = 'Test.pdf'
    api_key = 'Your API key here'

    begin
        api = SelectPdf::HtmlToPdfClient.new(api_key)

        api.page_size = SelectPdf::PageSize::A4
        api.margins = 0
        api.page_numbers = FALSE
        api.page_breaks_enhanced_algorithm = TRUE

        api.convert_url_to_file(url, local_file)
    rescue SelectPdf::ApiException => e
        print("An error occurred: #{e}")
    end
```

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

```ruby
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
```

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

```ruby
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
```

