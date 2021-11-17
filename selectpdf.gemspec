Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'selectpdf'
  s.version     = '1.4.0'
  s.summary     = 'SelectPdf Online REST API client library for Ruby. Contains HTML to PDF converter, PDF merge, PDF to text extractor, search PDF.'
  s.description = <<-EOF
                      SelectPdf Online REST API is a professional solution for managing PDF documents online.
                      SelectPdf cloud API consists of the following:
                      HTML to PDF REST API – SelectPdf HTML To PDF Online REST API is a professional solution that lets you create PDF from web pages and raw HTML code in your applications.
                      PDF to TEXT REST API – SelectPdf Pdf To Text REST API is an online solution that lets you extract text from your PDF documents or search your PDF document for certain words.
                      PDF Merge REST API – SelectPdf Pdf Merge REST API is an online solution that lets you merge local or remote PDFs into a final PDF document.
  EOF
  s.authors     = ['SelectPdf']
  s.email       = 'support@selectpdf.com'
  s.homepage    = 'https://selectpdf.com/html-to-pdf-api/'
  s.files       = [
      'lib/selectpdf.rb',
      'README.md',
      'CHANGELOG.md',
      'samples/simple_url_to_pdf.rb',
      'samples/simple_html_string_to_pdf.rb',
      'samples/html_to_pdf_main.rb',
      'samples/html_to_pdf_headers_and_footers.rb',
      'samples/pdf_merge.rb',
      'samples/pdf_to_text.rb',
      'samples/search_pdf.rb'
  ]
  s.license     = 'MIT'
end
