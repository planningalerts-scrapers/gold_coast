require "epathway_scraper"

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

  def extract_total_number_of_pages(page)
    page_label = page.at('#ctl00_MainBodyContent_mPagingControl_pageNumberLabel')
    if page_label.nil?
      # If we can't find the label assume there is only one page of results
      1
    elsif page_label.inner_text =~ /Page \d+ of (\d+)/
      $~[1].to_i
    else
      raise "Unexpected form for number of pages"
    end
  end

  # Returns a list of URLs for all the applications on exhibition
  def urls
    # Get the main page and ask for the list of DAs on exhibition
    page = agent.get(enquiry_url)
    form = page.forms.first
    form.radiobuttons[1].click
    page = form.submit(form.button_with(:value => /Next/))

    number_of_pages = extract_total_number_of_pages(page)
    urls = []
    (1..number_of_pages).each do |page_no|
      page = agent.get("EnquirySummaryView.aspx?PageNumber=#{page_no}")
      # Get a list of urls on this page
      urls += extract_urls_from_page(page)
    end
    urls
  end

  def applications
    scraper = EpathwayScraper::Scraper.new("")
    urls.map do |url|
      # Get application page with a referrer or we get an error page
      page = agent.get(url, [], URI.parse(enquiry_url))
      data = scraper.scrape_detail_page(page)

      record = {
        "council_reference" => data[:council_reference],
        # Throw away the first part of the address which contains lot number
        "address" => data[:address].split(", ")[1..-1].join(", "),
        "description" => data[:description],
        "info_url" => enquiry_url,
        "date_scraped" => Date.today.to_s,
        "date_received" => data[:date_received]
      }
      EpathwayScraper.save(record)
    end
  end
end

GoldCoastScraper.new.applications
