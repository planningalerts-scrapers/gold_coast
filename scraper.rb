require "mechanize"
require 'scraperwiki'

# This is using the ePathway system.

class GoldCoastScraper
  attr_reader :agent

  def initialize
    @agent = Mechanize.new
  end

  def extract_urls_from_page(page)
    content = page.at('table.ContentPanel')
    if content
      content.search('tr')[1..-1].map do |app|
        (page.uri + app.search('td')[0].at('a')["href"]).to_s
      end
    else
      []
    end
  end

  # The main url for the planning system which can be reached directly without getting a stupid session timed out error
  def enquiry_url
    "https://cogc.cloud.infor.com/ePathway/epthprod/Web/GeneralEnquiry/EnquiryLists.aspx?ModuleCode=LAP"
  end

  # Returns a list of URLs for all the applications on exhibition
  def urls
    # Get the main page and ask for the list of DAs on exhibition
    page = agent.get(enquiry_url)
    form = page.forms.first
    form.radiobuttons[1].click
    page = form.submit(form.button_with(:value => /Next/))

    page_label = page.at('#ctl00_MainBodyContent_mPagingControl_pageNumberLabel')
    if page_label.nil?
      # If we can't find the label assume there is only one page of results
      number_of_pages = 1
    elsif page_label.inner_text =~ /Page \d+ of (\d+)/
      number_of_pages = $~[1].to_i
    else
      raise "Unexpected form for number of pages"
    end
    urls = []
    (1..number_of_pages).each do |page_no|
      # Don't refetch the first page
      if page_no > 1
        page = agent.get("https://cogc.cloud.infor.com/ePathway/epthprod/Web/GeneralEnquiry/EnquirySummaryView.aspx?PageNumber=#{page_no}")
      end
      # Get a list of urls on this page
      urls += extract_urls_from_page(page)
    end
    urls
  end

  def applications
    urls.map do |url|
      # Get application page with a referrer or we get an error page
      page = agent.get(url, [], URI.parse(enquiry_url))
      results = page.at('.GroupContentPanel').search('div.field')

      council_reference = results.at('span[contains("Application number")]').next.text
      date_received     = Date.strptime(results.at('span[contains("Lodgement date")]').next.text, '%d/%m/%Y').to_s
      description       = results.at('span[contains("Application description")]').next.text

      address = results.at('span[contains("Application location")]').next.text
      # Throw away the first part of the address which contains lot number
      address = address.split(", ")[1..-1].join(", ")
      record = {
        "council_reference" => council_reference,
        "address" => address,
        "description" => description,
        "info_url" => enquiry_url,
        "date_scraped" => Date.today.to_s,
        "date_received" => date_received
      }
      puts "Saving record " + record['council_reference'] + " - " + record['address']
      ScraperWiki.save_sqlite(['council_reference'], record)
    end
  end
end

GoldCoastScraper.new.applications
