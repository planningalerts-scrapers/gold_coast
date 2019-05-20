require "epathway_scraper"

scraper = EpathwayScraper::Scraper.new(
  "https://cogc.cloud.infor.com/ePathway/epthprod"
)

scraper.scrape(list_type: :advertising, with_gets: true) do |record|
  # Throw away the first part of the address which contains lot number
  record["address"] = record["address"].split(", ")[1..-1].join(", ")
  EpathwayScraper.save(record)
end
