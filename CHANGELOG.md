### 1.6.0
* Includes the 1.5.0 features of the SelectPdf API clients (there was no separate 1.5.0 Ruby release).
* Accessible PDF and PDF standards on HtmlToPdfClient: tagged, pdf_standard (new SelectPdf::PdfStandard class: Full, PdfA, PdfA2B, PdfA3A, PdfA3B, PdfA3U, PdfX, PdfSiqQ_A, PdfSiqQ_B) and doc_language.
* Electronic invoices: new InvoiceClient creates ZUGFeRD / Factur-X hybrid invoices (PDF/A-3 with the invoice XML embedded) from a url or an html string, synchronously or asynchronously. Invoice XML from a file (invoice_xml_file) or from memory (invoice_xml), zugferd_profile, zugferd_relationship, zugferd_schema (new SelectPdf::ZugferdProfile, SelectPdf::ZugferdRelationship, SelectPdf::ZugferdSchema classes). Requires an API key.
* HtmlToPdfClient: web_page_fixed_size, auth_username, auth_password.
* 1.5.0: keyless demo mode - HtmlToPdfClient.new with no key, an empty key or 'demo' uses the demo endpoint (watermarked output, 5 pages, Chromium engine). New demo_mode?, demo_response?, clamped_fields, dropped_fields, was_clamped?, was_any_field_dropped?.
* 1.5.0: typed demo exceptions (subclasses of ApiException): DemoRateLimitException, DemoSafetyException, DemoUnsupportedException. user_password, owner_password and asynchronous calls raise DemoUnsupportedException in demo mode.
* 1.5.0: response telemetry on every client - credits_total, credits_remaining, mode, execution_mode.
* 1.5.0: SelectPdf::RenderingEngine::CHROMIUM.
* Number of pages and job id are read from the X-SelectPdf-Pages and X-SelectPdf-Job-Id response headers. Asynchronous jobs are complete when the job status is no longer 202 Accepted.
* Fixes: TRUE / FALSE constants (removed in Ruby 3.2) replaced with true / false, including the default arguments of the PdfToTextClient search methods; multipart requests (PDF merge, PDF to text) now send parameters set to false instead of skipping them; cookies are encoded with %20 for spaces, as the API expects.

### 1.4.0
* Pdf Merge Client, Pdf To Text Client

### 1.3.0
* Html To Pdf Client
