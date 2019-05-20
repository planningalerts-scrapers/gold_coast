require "epathway_scraper"

scraper = EpathwayScraper::Scraper.new("https://cogc.cloud.infor.com/ePathway/epthprod")
page = scraper.pick_type_of_search(:advertising)

number_of_pages = scraper.extract_total_number_of_pages(page)

scraper.scrape_all_index_pages_with_gets(number_of_pages) do |record|
  # Throw away the first part of the address which contains lot number
  record["address"] = record["address"].split(", ")[1..-1].join(", ")
  EpathwayScraper.save(record)
end
