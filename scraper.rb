require "epathway_scraper"

class GoldCoastScraper
  attr_reader :agent

  def initialize
    @agent = Mechanize.new
  end

  def scrape_detail_page(url, scraper)
    # Get application page with a referrer or we get an error page
    page = agent.get(url, [], URI.parse(scraper.base_url))
    data = scraper.scrape_detail_page(page)

    record = {
      "council_reference" => data[:council_reference],
      # Throw away the first part of the address which contains lot number
      "address" => data[:address].split(", ")[1..-1].join(", "),
      "description" => data[:description],
      "info_url" => scraper.base_url,
      "date_scraped" => Date.today.to_s,
      "date_received" => data[:date_received]
    }
    EpathwayScraper.save(record)
  end

  def applications
    scraper = EpathwayScraper::Scraper.new("https://cogc.cloud.infor.com/ePathway/epthprod")
    page = scraper.pick_type_of_search(:advertising)

    number_of_pages = scraper.extract_total_number_of_pages(page)
    urls = []
    (1..number_of_pages).each do |page_no|
      page = scraper.agent.get("EnquirySummaryView.aspx?PageNumber=#{page_no}")
      table = page.at('table.ContentPanel')
      # Get a list of urls on this page
      urls += scraper.extract_table_data_and_urls(table).map do |row|
        scraper.extract_index_data(row)[:detail_url]
      end
    end
    urls.map do |url|
      scrape_detail_page(url, scraper)
    end
  end
end

GoldCoastScraper.new.applications
